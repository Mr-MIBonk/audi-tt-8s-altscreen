# Working with Claude

[Home](Home.md)

Most of this port was built in conversations with Claude (Claude Code, the
desktop app). People keep asking how, and where to start. This page is the
honest answer: what the setup was, how a typical round went, prompts that
worked, and where it went wrong.

## Setup

- **Claude Code** on a PC, with the firmware files and the git checkout in its
  working folder. Claude reads, writes and runs code there: Python tools for the
  firmware images, Java builds, the jar patcher, previews.
- **The car stays with you.** Claude never connected to the head unit. You run
  the commands over SSH from your own computer and bring back photos and logs.
- **Your own firmware copy.** Everything was checked against files from this
  exact car and firmware, not against what someone else's dump says.
- **A test kit on the car** (`kit/tt.sh`) so each round is: copy a zip, run
  `setup`, `use vNN`, restart the MMI, `play ...`, `save`. Claude writes the kit
  and keeps it in step with each build.

## How a round goes

1. You describe what you see, with **photos of the cockpit** and the **logs**
   (`sh tt.sh save`). Photos carry most of the information.
2. Claude reads the logs, works out the cause, changes the code, builds a new
   version with its hash, and packages a kit.
3. Claude gives you the exact commands, one block each, ready to paste.
4. You test **parked**, and the next round starts.

32 HMI versions were built this way. Most were small: one question, one test.

## Prompts that worked

**Start from your own firmware, not from guesses.**
> Here is my firmware folder (MU1462, TT 8S). The upstream project supports
> MU1438. Find what differs and whether its hook can work on mine. Check
> against my files.

That produced the [differences table](TT-differences.md) and the offline hook
check (47 symbols, 5 prologues) before anything touched the car.

**Report what you see, plainly, with pictures.**
> Actual good news. It works. A couple of things though. The straight line drawn
> by the nav by default is annoying, and it takes time to be transparent.
> (7 photos)

Claude traced the flash to the stock banner's fade-in animation and added a
watcher thread. Short, honest reports with photos worked better than long theories.

**Ask for a test that answers one question.**
> Is it as low as it can go, or is there space to make it lower or taller?

Claude did not guess. It built a window test (move the stock banner, grid on,
photo per step). The answer, "the window is fixed by the cluster", came from
three identical photos.

**Ask to see designs before anything is built.**
> Before you build those into a jar file, show it to me.

From then on every look change was a PC preview drawn by the car's own code.
Five rounds of mockups cost minutes each; car tests would have cost an evening.

**Ask how sure it is.**
> How sure are we that this will work with Google Maps and Apple Maps?

You get a split between what is proven on the car and what is not, instead of
optimism.

**Ask it to research.**
> Can you scout more kinds of route instructions? There should be something
> online about Google and Apple Maps.

Claude read Apple's CarPlay and Google's navigation docs, compared them with
what the code handles, found two wrong pictures and proposed nine new ones.

**Say what you can and cannot do.**
> I cannot get many of those just by driving around.

Claude added a research log that records every maneuver the iPhone sends, so
routes planned while parked replace test drives.

## Where it went wrong, and what caught it

Claude is often right about the cause and sometimes wrong about the API. Each of
these cost one test round and was caught by a photo or a log line:

| Mistake | Caught by |
|---|---|
| Texture arguments in the wrong order: the panel came out as a thin strip | Log showed a 200x6 image |
| Font arguments swapped: no text at all | Log, then the converted class |
| Own layer created but hidden by default | Log said everything succeeded; photo showed nothing |
| Text placed by its top edge; the engine uses the baseline | Photo: text above the box |
| Colours written ARGB; the engine wants RGBA, so grey came out pink | Grid labels coded green showed magenta |
| Overriding a large stock class broke navigation start-up | Car stuck at 11 %; removing the jar recovered it |

What kept these cheap:

- **One change per test**, and a version number with a sha256 hash on every jar.
- **Nothing replaced on flash** where possible: the jar is an add-on, removing it
  restores stock. Installers check hashes first and keep a backup.
- **Logs everywhere.** Most fixes came from a log line, not from guessing.
- **Parked tests**: playback scripts drive the panel without a route or a drive.

## Tips

### Reporting from the car

- **Photos beat descriptions.** Take them straight on, the whole cockpit in frame,
  and say which view and tab each one shows. Number them when a test has steps
  ("W1, W2, W3"), and say when photos look identical: that is a result too.
- **Send the log files, not a retelling.** `sh tt.sh save`, copy the folder, attach
  the files. Paste exact error text.
- **Say what you did not do.** "I skipped the map tab", "the phone was unplugged":
  Claude reads the logs with that in mind.
- **Ask for calibration aids.** A coordinate grid drawn on the screen turned
  "a bit too high" into exact pixel numbers in one photo.

### Commands and the car

- **Ask for one command per block**, ready to paste, and say where you run them
  (a Mac, a phone over SSH). Long chains are easy to mistype in a car.
- **Ask for `--check` before `--install`.** A read-only check that compares hashes
  and prints what it would change is cheap insurance.
- **Get the rollback command before the install command.**
- **Keep the car powered** (engine on or a charger) during long parked sessions.
- `/tmp` on the head unit is wiped at power-off: save logs before you switch off.
- Old SSH: `-o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa`,
  and `scp -O`.

### Steering the work

- **Tell it your rules once.** For example: never commit firmware or patched stock
  files; commit as my GitHub noreply address; work on main; send zips, not jars;
  show designs before building. Claude keeps to them.
- **Make the design calls yourself.** "Original style", "framed, Audi TT styled",
  "make it centred": the results got better each time the request was specific.
- **Say "hold" when you want to talk first.** "Hold before you make any changes, I
  want to discuss" gets a discussion, not a build.
- **Say "you decide" for small things.** It saves a round of questions.
- **Ask "what do you think?"** You get a recommendation, not a list of options.
- **Let it say no.** Some things cannot work (the stock guidance banner cannot
  show iPhone turns). The [dead ends page](Stock-guidance-dead-ends.md) is
  worth as much as the features.
- **Expect safety prompts.** Claude asks before risky or outward-facing steps
  (deleting a remote branch, for example) and will not invent car results it has
  not seen.

### Long projects

- **Keep the knowledge in the repo.** Long conversations run out of context and
  get summarised. This wiki and Claude Code's memory carry facts from one
  session to the next. Ask Claude to update the wiki after each result.
- **Version everything.** Every jar got a number and a hash, and the kit could
  switch between versions with one command, so a bad build was one command
  away from the last good one.
- **Ask it to record the "why".** A dead end without its evidence gets tried
  again three weeks later.
- **Commit often**, small and described, so the history explains itself.
- **Research is a task too.** "Check Apple's docs", "compare with this other
  repo": Claude reads and reports back with sources.

### Mindset

- It is a collaborator that is fast at reading code and building tools. It is
  not an oracle: on an undocumented head unit, every guess is a test.
- Small parked tests, honest photos and saved logs were what made the 32
  versions possible.

## Where to start on your own car

1. Get root access (SSH or M.I.B.) and a full backup first.
2. Copy your firmware files to your computer and open the folder in Claude Code.
3. First prompt: what your car is, what you want, and "check it against my files
   before we change anything".
4. Ask for a read-only check script before any installer.
5. Work in small, parked tests, and send photos and logs back each time.
