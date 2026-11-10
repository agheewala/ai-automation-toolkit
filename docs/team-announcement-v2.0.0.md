# 📢 AI Automation Toolkit — Now Available (v2.0.0)

### In one sentence
This gives Copilot the ability to automatically fix tickets, fix accessibility issues, and review
pull requests — the same way, for every project. You type simple commands into Copilot Chat; this
guide tells you exactly what to type, in order. You never have to guess.

### 🛟 Don't worry — you can't break anything by following this guide
- Nothing in this guide ever saves anything permanently to your team's shared project by itself.
- Every step stops and shows you what it would do. **A person must still say "yes, keep this"
  afterward** (the normal way your team saves/commits code).
- If anything ever looks wrong before that last "save" step, you can simply not save it, or ask a
  technical teammate to look — nothing is lost.

**So anywhere this guide tells you to pick a recommended option, just pick it — it is always safe
to try, review afterward, and undo if it doesn't look right.**

---

## Step 0 — Which of these applies to you?

Ask in your team channel: **"Has anyone already set this up in this exact project before?"**

- 🤷 **Not sure / nobody answers** → Assume "No" and follow **Section A**.
- ❌ **No, nobody has set this up here before** → Follow **Section A: First-time setup**. (This
  covers both "this project already has some old files" and "this project has nothing at all" —
  the steps are identical either way.)
- ✅ **Yes, it's already set up, I just want the newest version** → Skip to **Section B: Getting
  the update**.

---

## Section A — First-time setup (do this once per project)

Follow every step below, in the exact order shown. Copy-paste each command exactly as written —
the only thing you ever change is the folder path, and you set that once in Step 1.

Some of your team uses **VS Code Copilot Chat**, some use **GitHub Copilot CLI** (the `copilot`
command-line tool). Both are fully supported — wherever a step differs, both options are shown.

### Step 1 — Get the toolkit onto your computer
Don't worry — you don't need to know git commands for this. Just take the line below and either:
- Paste it into a terminal (PowerShell) and press Enter, **or**
- Paste it into Copilot Chat (VS Code) or GitHub Copilot CLI and ask Copilot to run it for you

```
git clone git@github.com:agheewala/ai-automation-toolkit.git C:\Path\To\ai-automation-toolkit
```

This downloads the toolkit to your computer one time, into the path shown above (feel free to
change `C:\Path\To\ai-automation-toolkit` to wherever you'd like it). You reuse this same folder
for every project you set up — you do not repeat this step per project.

### Step 2 — Open your project
- **VS Code:** open the actual project you want to set this up in — **not** the toolkit folder
  from Step 1.
- **GitHub Copilot CLI:** open a terminal, `cd` into that project's folder, then start `copilot`.

### Step 3 — One manual copy (the only step that isn't a typed command)
This is a one-time bootstrap step. Do the one that matches how you use Copilot (or do both — it
only takes a minute, and then your project supports either surface from here on):

- **If you use VS Code Copilot Chat**, type exactly this (replace `C:\Path\To\ai-automation-toolkit`
  with wherever you put it in Step 1):
  > Copy `sync-toolkit.prompt.md` from `C:\Path\To\ai-automation-toolkit\core\.github\prompts\`
  > into this workspace's `.github\prompts\` folder.

- **If you use GitHub Copilot CLI**, type exactly this instead:
  > Copy `sync-toolkit.agent.md` from `C:\Path\To\ai-automation-toolkit\core\.github\agents\` into
  > this workspace's `.github\agents\` folder.

### Step 4 — Reload
- **VS Code:** close the chat panel and open a new one (or restart VS Code). This lets it notice
  the file you just copied in Step 3.
- **GitHub Copilot CLI:** close that CLI session and start a new one (`copilot`) in the project
  folder, so it notices the file you just copied in Step 3.

### Step 5 — Run the setup command
- **VS Code:** type exactly:
  ```
  /sync-toolkit --source "C:\Path\To\ai-automation-toolkit" --mode install
  ```
- **GitHub Copilot CLI:** type `/agent`, choose **Sync Toolkit** from the list, then when it asks
  what you want to do, type:
  ```
  --source "C:\Path\To\ai-automation-toolkit" --mode install
  ```
  (or, all in one line without the menu:
  `copilot --agent="Sync Toolkit" --prompt "--source \"C:\Path\To\ai-automation-toolkit\" --mode install"`)

### Step 6 — Answer its questions
It will ask simple things: your project's name, a short description, where the code lives, and so
on.
- **If you know the answer, type it.**
- **If you don't know an answer, just type "I don't know."** It will note that and move on —
  never guess an answer for it.

### Step 7 — Only if it finds old files already in your project
If your project already had some of these files from before (hand-copied, old style), it will
stop and ask you, one file at a time, what to do. You'll see 3 choices.

> ### 👉 Recommended: type **Overwrite**
> Pick this one whenever you're not sure. It's safe, because:
> - Nothing is saved to your team's shared project yet — you (or a teammate) still review
>   everything in Step 8 before it's kept for real.
> - Overwriting lets the tool build the complete, correct version for your project, instead of
>   leaving old, incomplete pieces behind.
>
> Only pick **keep existing** or **save side-by-side** instead when you're sure you want to keep
> your old file — for example, because you already made your own customizations to it and don't
> want to lose them without comparing first.

If nothing old existed, you won't see this question at all — it just creates everything cleanly.

### Step 8 — Review it, then save it yourself
The tool never saves anything to your team's shared project on its own. A person does that last
step:
1. Look over what it created.
2. If it looks right, save it (commit) the normal way your team saves code.
3. If anything looks wrong, ask a technical teammate before saving — nothing is lost by waiting.

🎉 **Done.** Your project is now set up. Next time, you'll use **Section B**, not Section A, for
this project.

---

## Section B — Getting the update (project already has this set up)

- **VS Code:** open the project, open Copilot Chat, and type:
  ```
  /sync-toolkit --source "C:\Path\To\ai-automation-toolkit" --version v2.0.0
  ```
- **GitHub Copilot CLI:** open a terminal in the project folder, start `copilot`, type `/agent`,
  choose **Sync Toolkit**, then type:
  ```
  --source "C:\Path\To\ai-automation-toolkit" --version v2.0.0
  ```
  (or, all in one line:
  `copilot --agent="Sync Toolkit" --prompt "--source \"C:\Path\To\ai-automation-toolkit\" --version v2.0.0"`)

- It checks what changed since last time and updates only what's needed.
- It will **never** silently throw away anything your team wrote by hand.
- If your team's version and the new version both changed the exact same thing, it marks that spot
  clearly and asks you to decide — it never guesses for you.
- Same safety net as Section A: nothing is saved anywhere permanently until a person reviews it and
  saves it for real.

⚠️ **Don't use the Section A command here** — use the update command above, not `--mode install`.
(If you run install by mistake, it notices and asks you to confirm before doing anything, so you
still can't lose anything — but use update to keep things simple.)

---

## Extra things you can do later (optional — skip if you don't need them yet)

### Refresh just one part later (for example, after a database change)
- **VS Code:**
  ```
  /sync-toolkit --source "C:\Path\To\ai-automation-toolkit" --generator create-data-dictionary
  ```
- **GitHub Copilot CLI:** `/agent` → **Sync Toolkit**, then type:
  ```
  --source "C:\Path\To\ai-automation-toolkit" --generator create-data-dictionary
  ```

### Tell it you've manually fixed something it flagged
- **VS Code:**
  ```
  /sync-toolkit --source "C:\Path\To\ai-automation-toolkit" --mark-reconciled <file-path>
  ```
- **GitHub Copilot CLI:** `/agent` → **Sync Toolkit**, then type:
  ```
  --source "C:\Path\To\ai-automation-toolkit" --mark-reconciled <file-path>
  ```

Replace `<file-path>` with the exact file name it flagged earlier. It will ask a follow-up
question — answer honestly, don't guess.

The same VS Code ⇄ CLI pattern shown above also applies to `fix ticket` / accessibility fixes, via
the **Ticket Processor** agent in the CLI.

---

## For technical readers (optional — everyone else already has what they need above)

- This is a versioned package of `AGENTS.md`, `README.md`, `.ai/`, and `.github/` content,
  generated per project from that project's own codebase.
- Installs/updates are driven by `manifest.json`'s 3-tier classification; Tier 2 files go through a
  byte-level 3-way merge (`git merge-file`) against a per-file tracked `baseVersion`; Tier 3
  (`knowledge-base.md`, `data-dictionary/`) is project-owned and never touched by sync.
- A small `.ai/.toolkit-sync-state.json` file (machine-managed, never hand-edit it) tracks per-file
  sync state — its presence is what determines install vs. update eligibility. Use
  `--mark-reconciled` instead of editing it directly.
- Full command reference (every command, VS Code vs. CLI side by side): see the installed
  project's own `README.md` "Command Reference" section, or
  [core/README.md.template](../core/README.md.template#command-reference) in this repo.
- **What's new in v2.0.0:** GitHub Copilot CLI support for every command (not just VS Code); a full
  command reference; smarter data-dictionary handling (won't re-ask for CSV exports if one already
  exists); `data-dictionary-tooling/`, `generators/` and `stacks/` are no longer copied into
  installed projects — cleaner installs, read straight from the toolkit clone instead.

**GitHub:** https://github.com/agheewala/ai-automation-toolkit
