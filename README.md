# `Arch-Guardian`

A security-focused middleware and update safety layer for Arch Linux.

Official repository:

https://github.com/plopletoyay/Arch-Guardian

This project analyzes pending system upgrades before they are installed, searches Arch Linux news for package-related warnings or advisories, ranks findings by severity, and asks the user whether the upgrade should continue.

# `Security Middleware for pacman Updates`

> This project is not a replacement for `pacman`.
>
> It is a middleware layer designed to improve awareness and safety before running system upgrades on Arch Linux.

---

# Important Warning

Even though Arch Guardian adds extra safety checks, the actual system upgrade still uses the real Arch Linux package manager underneath.

Arch Guardian only adds:

- update interception
- Arch news analysis
- package inspection
- advisory detection
- severity scoring
- risk sorting
- confirmation prompts

before the real upgrade proceeds.

You should still understand basic Arch Linux package management before relying on automated update tools.

---

# What this project does

Arch Guardian acts as a protective layer around the normal Arch Linux upgrade workflow.

Instead of immediately upgrading packages, it:

- synchronizes package databases
- checks which packages are about to be upgraded
- searches Arch Linux news entries
- detects package-related warnings
- analyzes risk severity
- sorts findings from most dangerous to least dangerous
- asks the user whether to continue

The purpose is to help users avoid blindly upgrading into:

- known breakages
- dangerous package releases
- dependency problems
- security advisories
- unstable transitions
- manual intervention requirements
- or critical system-related issues

---

# Real Workflow Behavior

The script internally performs a workflow similar to:

```text id="v2xq9m"
sudo pacman -Sy
↓
Check pending upgrades
↓
Analyze Arch Linux news
↓
Detect risky package updates
↓
Ask user for confirmation
↓
sudo pacman -Su
````

This means the user still uses the normal Arch Linux upgrade workflow.

Arch Guardian simply adds a verification and analysis layer before the actual upgrade happens.

---

# What Arch Guardian can be described as

This project can be viewed as multiple things at once:

| Type                       | Meaning                                |
| -------------------------- | -------------------------------------- |
| `Update Wrapper`           | Wraps the upgrade workflow             |
| `Pre-flight Check`         | Performs checks before upgrading       |
| `Pre-update Hook`          | Runs logic before package installation |
| `Middleware`               | Sits between user and pacman           |
| `Logic Interceptor`        | Intercepts upgrade behavior            |
| `Automated System Auditor` | Automatically audits upgrade safety    |

---

# Main Features

## `Arch Linux News Analysis`

Arch Guardian downloads and analyzes the official Arch Linux news feed:

```text id="2gf3wh"
https://archlinux.org/feeds/news/
```

This allows the script to detect important upgrade-related announcements automatically.

---

## `Package-aware Detection`

The script checks whether packages being upgraded are mentioned directly inside Arch Linux news entries.

Example:

```text id="c9ffna"
Packages detected:
- linux
- systemd
- openssl

Detected warnings:
- Kernel-related compatibility issue
- OpenSSL advisory found
```

---

## `Risk Ranking System`

Findings are sorted by severity.

Example:

```text id="6m0b2k"
[CRITICAL]
Kernel package may require manual intervention

[NOTICE]
Relevant update for systemd
```

Severity detection is currently based on keywords such as:

* `manual intervention`
* `requires manual`
* `breaking change`
* `reinstall`
* `security`
* `vulnerability`

Core system packages receive additional weighting during analysis.

Example core packages:

* `linux`
* `systemd`
* `glibc`
* `pacman`
* `grub`
* `base`

---

## `Version-aware Matching`

The script attempts to match package versions mentioned in Arch news against:

* currently installed versions
* pending upgrade versions

This helps reduce unrelated or false-positive warnings.

---

## `User Confirmation`

After analysis is complete, the script asks whether the upgrade should continue.

Example:

```text id="5m8h3z"
CRITICAL RISK! Continue upgrade? (y/N):
```

or:

```text id="t08ys8"
Proceed with update? (Y/n):
```

If the user declines, the upgrade is postponed.

---

# Technical Architecture

Arch Guardian behaves like middleware between the user and the package manager.

```text id="8p1z6n"
┌─────────────┐
│    User     │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ ArchGuardian│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   pacman    │
└─────────────┘
```

The upgrade request passes through Arch Guardian before reaching `pacman`.

---

# Technologies Used

## `Python`

The core logic is written in Python.

Python handles:

* package detection
* RSS parsing
* advisory/news inspection
* severity analysis
* keyword scoring
* version matching
* terminal interaction
* confirmation handling
* workflow automation

---

## `feedparser`

Used for parsing the Arch Linux RSS news feed.

---

## `requests`

Used for downloading the RSS feed data.

---

## `subprocess`

Used for interacting with:

* `pacman`
* system commands
* update queries

---

## `pacman`

Arch Guardian integrates directly with the Arch Linux package manager.

The script internally uses workflows equivalent to:

```text id="h7p0gn"
sudo pacman -Sy
sudo pacman -Su
```

instead of replacing package management entirely.

---

# Workflow Overview

## Step 1 — Synchronize Databases

The script synchronizes package databases.

Example internal workflow:

```text id="7n7hqs"
sudo pacman -Sy
```

---

## Step 2 — Detect Pending Upgrades

The script checks upgrade candidates using:

```text id="d7p3ul"
pacman -Qu
```

Example detected packages:

```text id="x4q5iw"
linux
mesa
openssl
systemd
```

---

## Step 3 — Download Arch News

Arch Guardian downloads recent entries from the Arch Linux news RSS feed.

---

## Step 4 — Analyze Relevant News

The script checks whether news entries reference packages involved in the upgrade.

---

## Step 5 — Score Risk Severity

Risk scores increase when keywords such as:

* `manual intervention`
* `breaking change`
* `security`
* `vulnerability`

appear in relevant news entries.

---

## Step 6 — Display Findings

Example output:

```text id="r79k20"
--- ARCH NEWS ANALYSIS REPORT ---

[CRITICAL] linux (6.14 -> 6.15)
Info: Action required for linux

News:
Manual intervention required after kernel upgrade

Link:
https://archlinux.org/news/
```

---

## Step 7 — User Decision

The user decides whether the upgrade should continue.

---

## Step 8 — Continue or Abort

If approved, the script continues the upgrade process.

If rejected, the upgrade is postponed.

---

# Why This Project Is Useful

## `Prevents Blind Upgrading`

Most users immediately upgrade without reading Arch Linux news first.

Arch Guardian automates that checking process.

---

## `Improves Security Awareness`

Security-related advisories become visible before upgrading.

---

## `Detects Manual Intervention Warnings`

The script can detect situations where Arch Linux requires manual action before or after upgrading.

---

## `Highlights Dangerous Core Package Updates`

Core system packages receive additional risk weighting.

---

## `Adds Human Verification`

The user still controls whether the upgrade proceeds.

---

# Example Output

```text id="0a6d7i"
:: Synchronizing databases...

--- ARCH NEWS ANALYSIS REPORT ---

[CRITICAL] linux (6.14 -> 6.15)
Info: Action required for linux

News:
Manual intervention required after kernel upgrade

Link:
https://archlinux.org/news/

CRITICAL RISK! Continue upgrade? (y/N):
```

---

# Installation

## 1) Install Automatically

Clone the repository:

```bash
git clone https://github.com/plopletoyay/Arch-Guardian.git
cd Arch-Guardian
./install.sh
```

The repository already handles installer permissions.

---

# Usage

Run the normal Arch Linux upgrade workflow.

Example:

```bash
sudo pacman -Syu
```

Arch Guardian intercepts and analyzes the upgrade before package installation continues.

---

# Example Project Structure

```text id="u7n5z0"
Arch-Guardian/
├── install.sh
├── arch_guardian.py
├── README.md
├── logs/
└── config/
```

---

# Future Improvements

Possible future upgrades:

* smarter severity scoring
* more advanced version matching
* additional advisory sources
* colored terminal reports
* local caching
* configurable risk policies
* rollback suggestions
* JSON output support
* package-specific risk rules

---

# Design Philosophy

Arch Guardian follows one main principle:

```text id="g19mxu"
Investigate first. Upgrade safely.
```

System upgrades are not just downloads.
They are system-level modifications that can affect:

* security
* drivers
* dependencies
* stability
* compatibility
* and entire system workflows

Arch Guardian adds awareness before execution.

---

# Notes

* This project is designed for Arch-based Linux distributions.
* It is a middleware layer, not a replacement for `pacman`.
* News analysis currently depends on the Arch Linux RSS feed.
* Risk scoring is keyword-based.
* Always review warnings before confirming upgrades.
* Use at your own risk.

---

# License

Licensed under the GNU General Public License v3.0.

SPDX identifier:

```text id="6jv8ni"
GNU General Public License v3.0
```

---

# Author

Created by `plopletoyay`
"Keep It Simple, Stupid."
