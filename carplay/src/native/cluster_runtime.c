/* MU1438 runtime. Declares a separate context 900 containing layer 60 only.
 * The HMI bridge selects/restores it using live renderer heartbeats. Stock
 * contexts are never edited here. Stock map hardware planes occlude layer 60.
 * Launch once per dio_manager lifetime; all state files are in volatile RAM. */
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <time.h>
#include <fcntl.h>
#include <dlfcn.h>
#ifndef MU1438_HOST_TEST
#include <process.h>
#else
#define P_WAIT 0
static int spawnv(int mode,const char *path,char *const argv[]) { (void)mode;(void)path;(void)argv;return 0; }
#endif
#include <sys/socket.h>
#include <sys/select.h>
#include <netinet/in.h>
#include "mu1438_au_wire.h"

#ifndef ACTIVE
#define ACTIVE "/tmp/mu1438-cluster-active"
#endif
struct open_params { uint32_t output,reserved; uint8_t priority,use_layer,layer,pad; uint32_t buffers,r2,r3; };
struct config { uint32_t width,height; float fps; };
struct input { void *data; uint32_t length; uint64_t timestamp; uint8_t flag,pad[7]; };
typedef char check_open[sizeof(struct open_params)==24?1:-1];
#ifndef MU1438_HOST_TEST
typedef char check_input[offsetof(struct input,timestamp)==8?1:-1];
#endif
static volatile sig_atomic_t stopped;
static pid_t owner;
static int compositions;
static void *video_handle;
static int kd_started;
static uint64_t recovery_start,last_beat;
static unsigned long frames;
static int (*init_kd)(void),(*open_video)(void **,const struct open_params *);
static void (*term_kd)(void);
static int (*configure)(void *,const struct config *),(*get_attrs)(void *,void *);
static int (*set_attrs)(void *,const void *),(*decode)(void *,const struct input *,int),(*close_video)(void *);
static void stop_handler(int sig) { (void)sig; stopped=1; }
static uint64_t millis(void);
#ifdef MU1462_TT
/* TT MU1462, window handover stage 1 (car runs 50/51). The head unit's own CarPlay video and
 * this renderer cannot hold a display window at the same time: nvdisp "Window is in use", the
 * head unit's decoder then times out (NVSS_STATUS_TIMED_OUT) and the iPhone ends the session.
 * Instead of being killed for the CarPlay tab, the renderer pauses: SIGUSR1 closes the video
 * output (frees the window) and drops the stream connection, SIGUSR2 opens it again (the hook
 * sends a fresh config + IDR to every new consumer). /tmp/mu1438-cluster-paused exists while
 * paused. Times are logged with %lu (QNX 6.5 printf drops %llu lines). */
#define PAUSED_FILE "/tmp/mu1438-cluster-paused"
#define SPORT_FILE "/tmp/mu1438-cluster-sport"
#define SPORT_SHIFT 453
/* Stage 1b (run53/55): pause modes for timing tests, chosen per pause by /tmp/mu1438-pause-mode:
 *   close  (default) close the video output and terminate KD, drop the stream connection
 *   keepkd close only the video output (KD stays initialised: faster resume)
 *   hide   keep everything and keep decoding, only switch the output off (attribute byte 60)
 * Log lines start with the realtime clock in seconds.ms, the same clock as the hook's log. */
#define MODE_FILE "/tmp/mu1438-pause-mode"
enum { MODE_CLOSE, MODE_KEEPKD, MODE_HIDE };
static volatile sig_atomic_t pause_wanted;
static volatile uint64_t pause_signal_at,resume_signal_at;
static int paused,hidden,mode_now=-1,at_header;
static uint64_t resume_began;
static int applied_shift=-1;
static uint64_t rt_ms(void) { struct timespec t;clock_gettime(CLOCK_REALTIME,&t);return (uint64_t)t.tv_sec*1000+t.tv_nsec/1000000; }
static void ts(void) { uint64_t m=rt_ms();printf("%lu.%03lu ",(unsigned long)(m/1000),(unsigned long)(m%1000)); }
static void pause_handler(int sig)
{
    pause_wanted=(sig==SIGUSR1);
    if(pause_wanted)pause_signal_at=rt_ms();else resume_signal_at=rt_ms();
}
/* The mode of the pause in progress: read once when the pause is first noticed. */
static int pause_mode(void)
{
    char m[16];FILE *f;
    if(mode_now>=0)return mode_now;
    mode_now=MODE_CLOSE;
    f=fopen(MODE_FILE,"r");
    if(f){
        if(fgets(m,sizeof(m),f)){
            if(!strncmp(m,"keepkd",6))mode_now=MODE_KEEPKD;
            else if(!strncmp(m,"hide",4))mode_now=MODE_HIDE;
        }
        fclose(f);
    }
    return mode_now;
}
#endif
static int alive(void) { return !stopped && kill(owner,0)==0 && access("/tmp/mu1438-cluster-disable",F_OK)!=0; }
static void put32(unsigned char *p,unsigned at,uint32_t v) { memcpy(p+at,&v,4); }
static uint64_t millis(void) { struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return (uint64_t)t.tv_sec*1000+t.tv_nsec/1000000; }
static int declare_context(void)
{
    const char *args[]={"dmdt","dc","900","60",NULL};
    return spawnv(P_WAIT,"/eso/bin/apps/dmdt",(char * const *)args);
}
static void heartbeat(void)
{
    FILE *f=fopen(ACTIVE,"w");
    if(f){fprintf(f,"%ld\n",(long)getpid());fclose(f);}
    last_beat=millis();
}
static void release_map(void)
{
    unlink(ACTIVE);
    if(compositions){compositions=0;puts("renderer heartbeat withdrawn");}
}
static int source_ready(void)
{
    char line[160]; int session=0,desired=0,ready=0; FILE *f;
    f=fopen("/tmp/mibr-alt111-gen2.status","r");if(!f)return 0;
    while(fgets(line,sizeof(line),f)){
        if(!strncmp(line,"control_session=",16))session=atoi(line+16)>0;
        if(!strncmp(line,"projection_desired=",19))desired=atoi(line+19)==1;
        if(!strncmp(line,"config_valid=",13))ready=atoi(line+13)==1;
    }
    fclose(f);return session&&desired&&ready;
}
static void end_renderer(void)
{
    release_map();
    if(video_handle){printf("decoder closed=%d frames=%lu\n",close_video(video_handle),frames);video_handle=NULL;}
    if(kd_started){term_kd();kd_started=0;}
    recovery_start=0;frames=0;
}
static int prepare_renderer(void)
{
#ifdef MU1462_TT
    /* MU1462: output device 0 (stage-1 binary patch of the shipped build) */
    struct open_params p={0,0,100,1,60,0,8,0,0};struct config cfg={1440,540,30.0f};
#else
    struct open_params p={1,0,100,1,60,0,8,0,0};struct config cfg={1440,540,30.0f};
#endif
    unsigned char attrs[64];uint64_t began=millis();
    if(video_handle)return 0;
#ifdef MU1462_TT
    if(!kd_started){if(init_kd()!=0)return -1;kd_started=1;}
#else
    if(init_kd()!=0)return -1;kd_started=1;
#endif
    if(open_video(&video_handle,&p)!=0 || !video_handle)goto fail;
    if(configure(video_handle,&cfg)!=0)goto fail;
    memset(attrs,0,sizeof(attrs));if(get_attrs(video_handle,attrs)!=0)goto fail;
    attrs[8]=1;put32(attrs,12,0);put32(attrs,16,0);put32(attrs,20,1440);put32(attrs,24,540);
    put32(attrs,28,0);put32(attrs,32,0);put32(attrs,36,1440);put32(attrs,40,540);
    attrs[60]=1;attrs[61]=0;if(set_attrs(video_handle,attrs)!=0)goto fail;
#ifdef MU1462_TT
    applied_shift=0;
#endif
#ifdef MU1462_TT
    ts();printf("decoder prepared in %lu ms\n",(unsigned long)(millis()-began));
#else
    printf("decoder prepared before TCP connect in %llu ms\n",(unsigned long long)(millis()-began));
#endif
    return 0;
fail:
    end_renderer();return -1;
}
#ifdef MU1462_TT
/* Sport skin small view: the tachometer covers the right part, so show the picture from
 * x=453 at the left edge (crop x..1440 -> screen 0..1440-x). The HMI sets SPORT_FILE. Same
 * logic as the old binary patch (scripts/mkrt.py), checked every 8 frames. */
static void apply_shift(void)
{
    unsigned char attrs[64];int want=access(SPORT_FILE,F_OK)==0?SPORT_SHIFT:0;
    if(want==applied_shift || !video_handle)return;
    memset(attrs,0,sizeof(attrs));if(get_attrs(video_handle,attrs)!=0)return;
    attrs[8]=1;put32(attrs,12,(uint32_t)want);put32(attrs,16,0);put32(attrs,20,(uint32_t)(1440-want));put32(attrs,24,540);
    put32(attrs,28,0);put32(attrs,32,0);put32(attrs,36,(uint32_t)(1440-want));put32(attrs,40,540);
    attrs[60]=1;attrs[61]=0;
    if(set_attrs(video_handle,attrs)==0){applied_shift=want;printf("crop shift %d\n",want);}
}
static void write_paused(void)
{
    FILE *f=fopen(PAUSED_FILE,"w");if(f){fprintf(f,"%ld\n",(long)getpid());fclose(f);}
}
static void do_pause(void)
{
    uint64_t began=rt_ms(),sig=pause_signal_at;int mode=pause_mode();
    if(paused)return;
    if(mode==MODE_KEEPKD){
        release_map();
        if(video_handle){printf("decoder closed=%d frames=%lu\n",close_video(video_handle),frames);video_handle=NULL;}
        recovery_start=0;frames=0;
    }else end_renderer();
    paused=1;write_paused();
    ts();printf("paused (%s): output released %lu ms after the signal (close took %lu ms)\n",
        mode==MODE_KEEPKD?"keepkd":"close",(unsigned long)(rt_ms()-sig),(unsigned long)(rt_ms()-began));
}
/* hide mode: the output is switched off, decoding goes on (attribute byte 60, set to 1 at prepare) */
static void set_visible(int on)
{
    unsigned char attrs[64];uint64_t began=rt_ms(),sig=on?resume_signal_at:pause_signal_at;int rc;
    memset(attrs,0,sizeof(attrs));
    if(!video_handle || get_attrs(video_handle,attrs)!=0){ts();puts("hide: no attributes");return;}
    attrs[60]=on?1:0;rc=set_attrs(video_handle,attrs);
    ts();printf("%s: rc=%d %lu ms after the signal (set took %lu ms)\n",on?"shown":"hidden",rc,
        (unsigned long)(rt_ms()-sig),(unsigned long)(rt_ms()-began));
}
#endif
/* EOF is a transport event, not proof that CarPlay projection ended. Retain the
 * last decoded surface during a bounded reconnect; never feed partial pictures
 * or hold a stale projection indefinitely after its session has ended. */
static int read_exact_frame(int fd,unsigned char *dst,size_t size)
{
    size_t used=0;uint64_t began=millis(),invalid_since=0;
    while(used<size && alive()){
        fd_set reads;struct timeval timeout={0,200000};int rc;ssize_t n;uint64_t now=millis();
#ifdef MU1462_TT
        if(pause_wanted && pause_mode()!=MODE_HIDE)return 0;
        if(at_header && pause_wanted!=hidden && !used)return 2;
#endif
        if(compositions && now-last_beat>=500)heartbeat();
        if(recovery_start && now-recovery_start>=3000)return -1;
        if(used && now-began>=5000)return -1;
        FD_ZERO(&reads);FD_SET(fd,&reads);rc=select(fd+1,&reads,NULL,NULL,&timeout);
        if(rc<0){if(errno==EINTR)continue;return -1;}
        if(!rc){
            if(!source_ready()){
                if(!invalid_since)invalid_since=now;
                else if(now-invalid_since>=1500)return 0;
            }else invalid_since=0;
            if(!compositions && now-began>=10000)return -1;
            continue;
        }
        n=recv(fd,dst+used,size-used,0);
        if(n<0&&errno==EINTR)continue;
        if(n<=0)return 0;
        used+=(size_t)n;
    }
    return used==size?1:0;
}
static void play_stream(int fd)
{
    unsigned char header[8],*buf=NULL;size_t capacity=0;int rc;uint64_t worst=0;
    while(alive()){
        uint32_t n;struct input in;uint64_t began,elapsed;
#ifdef MU1462_TT
        if(pause_wanted && !hidden && pause_mode()==MODE_HIDE){
            set_visible(0);hidden=1;release_map();write_paused();
        }else if(!pause_wanted && hidden){
            set_visible(1);hidden=0;mode_now=-1;unlink(PAUSED_FILE);resume_began=rt_ms();
        }
        at_header=1;rc=read_exact_frame(fd,header,8);at_header=0;
        if(rc==2)continue;
        if(rc!=1)break;
#else
        if(read_exact_frame(fd,header,8)!=1)break;
#endif
        n=mu1438_au_length(header);
        if(!n){puts("invalid framed-video header; refusing raw/mismatched stream");break;}
        if(n>capacity){unsigned char *next=realloc(buf,n);if(!next)break;buf=next;capacity=n;}
#ifdef MU1462_TT
        rc=read_exact_frame(fd,buf,n);
        if(rc!=1)break;
#else
        if(read_exact_frame(fd,buf,n)!=1)break;
#endif
        if(!video_handle)break;
        memset(&in,0,sizeof(in));in.data=buf;in.length=n;
        began=millis();rc=decode(video_handle,&in,0);elapsed=millis()-began;
        if(elapsed>worst)worst=elapsed;
        if(rc){printf("decode failed 0x%x\n",rc);end_renderer();break;}
        frames++;recovery_start=0;
#ifdef MU1462_TT
        if(!compositions && !hidden){
            compositions=1;
            heartbeat();ts();puts("map ownership acquired, decoder accepting complete frames");
            if(resume_began){ts();printf("resumed: first frame %lu ms after the resume signal\n",(unsigned long)(rt_ms()-resume_began));resume_began=0;}
        }
#else
        if(!compositions){
            compositions=1;
            heartbeat();puts("map ownership acquired, decoder accepting complete frames");
        }
#endif
#ifdef MU1462_TT
        if(frames%8==1)apply_shift();
#endif
        if(frames==1 || frames%120==0)printf("frames=%lu lastBytes=%u decodeMs=%llu worstMs=%llu\n",frames,n,(unsigned long long)elapsed,(unsigned long long)worst);
    }
    free(buf);
#ifdef MU1462_TT
    if(pause_wanted)return;
#endif
    if(compositions && !recovery_start){recovery_start=millis();puts("transport interrupted; retaining frame during bounded recovery");}
}
int main(int argc,char **argv)
{
    void *kd,*nv;int lockfd;struct sockaddr_in singleton;
    if(argc!=2 || (owner=(pid_t)atoi(argv[1]))<=1)return 2;
    /* QNX RAM filesystem does not implement record locks. A loopback UDP bind
     * is kernel-owned and released on crash; never trust a stale PID file. */
    lockfd=socket(AF_INET,SOCK_DGRAM,0);if(lockfd<0)return 1;
    memset(&singleton,0,sizeof(singleton));singleton.sin_family=AF_INET;
    singleton.sin_addr.s_addr=htonl(INADDR_LOOPBACK);singleton.sin_port=htons(19823);
    if(bind(lockfd,(struct sockaddr *)&singleton,sizeof(singleton))<0){perror("runtime singleton");return 1;}
    fcntl(lockfd,F_SETFD,FD_CLOEXEC);
    freopen("/tmp/mu1438-cluster-runtime.log","a",stdout);dup2(fileno(stdout),STDERR_FILENO);
    setvbuf(stdout,NULL,_IONBF,0);
    signal(SIGTERM,stop_handler);signal(SIGINT,stop_handler);signal(SIGPIPE,SIG_IGN);
#ifdef MU1462_TT
    {
        /* no SA_RESTART: a pause signal must wake select() at once */
        struct sigaction sa;memset(&sa,0,sizeof(sa));sa.sa_handler=pause_handler;sigemptyset(&sa.sa_mask);
        sigaction(SIGUSR1,&sa,NULL);sigaction(SIGUSR2,&sa,NULL);
        unlink(PAUSED_FILE);
    }
#endif
    setenv("IPL_CONFIG_DIR","/etc/eso/production",1);
    kd=dlopen("libKD.so",RTLD_NOW|RTLD_GLOBAL);nv=dlopen("libnvss_video.so",RTLD_NOW|RTLD_GLOBAL);
    if(!kd||!nv){printf("dlopen failed: %s\n",dlerror());return 1;}
#define LOAD(dst,lib,name) do { *(void **)(&(dst))=dlsym(lib,name);if(!(dst))return 1; } while(0)
    LOAD(init_kd,kd,"kdInitializeNV");LOAD(term_kd,kd,"kdTerminateNV");
    LOAD(open_video,nv,"NvSSVideoOpen");LOAD(close_video,nv,"NvSSVideoClose");
    LOAD(configure,nv,"NvSSVideoStreamConfigure");LOAD(get_attrs,nv,"NvSSVideoGetAttribs");
    LOAD(set_attrs,nv,"NvSSVideoSetAttribs");LOAD(decode,nv,"NvSSVideoDecode");
    printf("runtime pid=%ld owner=%ld\n",(long)getpid(),(long)owner);
    unlink(ACTIVE);
    if(declare_context()!=0)return 1;
    while(alive()){
        int fd;struct sockaddr_in a;
#ifdef MU1462_TT
        if(pause_wanted && pause_mode()!=MODE_HIDE){do_pause();usleep(20000);continue;}
        if(!pause_wanted && !paused && !hidden)mode_now=-1;
        if(paused){
            paused=0;mode_now=-1;unlink(PAUSED_FILE);resume_began=rt_ms();
            ts();printf("resume requested %lu ms after the signal\n",(unsigned long)(rt_ms()-resume_signal_at));
        }
#endif
        if(recovery_start && millis()-recovery_start>=3000)end_renderer();
        if(!source_ready()){
            if(compositions && !recovery_start)recovery_start=millis();
            usleep(200000);continue;
        }
        if(compositions && millis()-last_beat>=500)heartbeat();
        if(prepare_renderer()!=0){usleep(1000000);continue;}
        fd=socket(AF_INET,SOCK_STREAM,0);if(fd<0)break;
        memset(&a,0,sizeof(a));a.sin_family=AF_INET;a.sin_port=htons(19820);a.sin_addr.s_addr=htonl(INADDR_LOOPBACK);
        if(connect(fd,(struct sockaddr *)&a,sizeof(a))==0)play_stream(fd);
        close(fd);usleep(100000);
    }
    end_renderer();puts("runtime stopped");close(lockfd);
#ifdef MU1462_TT
    unlink(PAUSED_FILE);
#endif
    return 0;
}
