# Vibe Coding Workshop — Laptop Setup

One script that gets a student's laptop ready for the workshop. It installs:

**Python 3.14 · Node.js · Git · GitHub CLI · Supabase CLI · Vercel CLI · Claude Code**

It skips anything that's already installed, so it's safe to run as many times as you like.

---

## Run it

### Mac

Open Terminal (press **Cmd + Space**, type `terminal`, press **Enter**). Paste this line and press **Enter**:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jaydetj77-sudo/claudesetup/main/script/setup-mac.sh)"
```

- If it asks for the Mac password, type it and press Enter. The letters don't show while typing. That's normal.
- If a box pops up asking to install **Command Line Tools**, click **Install**. When it finishes, paste the same line again.

### Windows

1. On this page, click the green **Code** button → **Download ZIP**.
2. In Downloads, right-click the ZIP → **Extract All…** → **Extract**.
3. Open the folder, then open the `script` folder inside it.
4. Double-click **`run-setup.bat`**. Click **Yes** when Windows asks for permission.
5. If a blue **"Windows protected your PC"** box appears, click **More info** → **Run anyway**.

**It takes 5–20 minutes.** It can look stuck at times. Leave it running until the results table appears.

---

## Done = ALL GREEN

At the end, a results table shows one row per tool:

| Status | Meaning |
| --- | --- |
| 🟢 **Installed** | It wasn't there, and the script installed it. |
| 🟢 **AlreadyInstalled** | It was already there. Nothing changed. |
| 🔴 **Failed** | The install didn't work. See "When it breaks" below. |
| 🟡 **Missing** | Only shown in check-only mode. The tool isn't installed yet. |

When every row is green, you'll see **ALL GREEN – setup complete!** Then the student signs in to each tool.

1. **Close the window and open a fresh one.** New tools only work in a newly opened window.
   - Mac: **Cmd + Q** to quit Terminal, then open it again.
   - Windows: press **Windows Key + R**, type `powershell`, press **Enter**.
2. Run these one at a time. Wait for each one to finish before starting the next:

```bash
gh auth login
supabase login
vercel login
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

- The first three open a web browser. Approve the sign-in there, then come back.
- `gh auth login` asks a few questions first. Press **Enter** on each one to accept the suggested answer.
- In the last two, swap in your real name and the email you use for GitHub.

**Check everything works.** Each of these should print a version number:

```bash
claude --version
gh --version
supabase --version
vercel --version
```

---

## When it breaks

| Problem | Fix |
| --- | --- |
| A row says **Failed** | Close the window, open a new one, and run the script again. This fixes most problems. |
| **"command not found"**, even though the table said Installed | The window was opened before the tool was installed. Close it and open a new one. |
| Mac: stops after installing Command Line Tools | That's expected. Run the same line again. |
| Windows: nothing happens when double-clicking | Right-click `run-setup.bat` → **Run as administrator**. |
| Windows: "winget not found" | Open the Microsoft Store, search **App Installer**, click **Update** (or **Get**), then run again. |
| Antivirus deleted or blocked the script | Allow it in the antivirus, or install the tools by hand (see the end of this page). |

**Log files.** Every run saves a full copy of what appeared on screen to the home folder. The file is named like `workshop-setup-20261026-093000.log`. The exact path is printed at the bottom of the results. Send it along with a screenshot of the table when asking for help.

---

## Check without installing

This shows what's installed and what's missing, and changes nothing. It's handy for assistants doing a quick check on workshop day.

- **Mac:**
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jaydetj77-sudo/claudesetup/main/script/setup-mac.sh)" -- --check-only
  ```
- **Windows:** in the `script` folder, run `run-setup.bat -CheckOnly`.

---

## On the day

- Ask students to run the script **before** the workshop. Venue Wi-Fi with many laptops downloading at once is slow.
- 5–20 minutes is normal. Older laptops or slow Wi-Fi can take longer.
- A Mac may ask for its password more than once. That's normal.
- The Mac script backs up the student's shell settings to `~/dotfile-backups` before changing anything.

---

## Install by hand (last resort)

If the script can't run at all, install each tool from its official site:

| Tool | Where to get it |
| --- | --- |
| Python 3.14 | [python.org/downloads](https://www.python.org/downloads/) |
| Node.js (LTS) | [nodejs.org](https://nodejs.org/) |
| Git | [git-scm.com/downloads](https://git-scm.com/downloads) |
| GitHub CLI | [cli.github.com](https://cli.github.com/) |
| Supabase CLI | [supabase.com/docs/guides/local-development/cli/getting-started](https://supabase.com/docs/guides/local-development/cli/getting-started) |
| Vercel CLI | After Node.js is installed, run `npm install -g vercel` |
| Claude Code | [docs.claude.com — Claude Code setup](https://docs.claude.com/en/docs/claude-code/setup) |

---

## What's in this folder

| File | What it does |
| --- | --- |
| `script/setup-mac.sh` | The Mac setup script |
| `script/setup-windows.ps1` | The Windows setup script |
| `script/run-setup.bat` | The double-click launcher for Windows. It asks for permission, then runs the script above. |
