#!/usr/bin/env python3
import feedparser
import re
import requests
import subprocess
import os
import sys
import json
import logging
from datetime import datetime, timedelta
from pathlib import Path

RSS_URL        = "https://archlinux.org/feeds/news/"
AGE_LIMIT_DAYS = int(os.environ.get("AG_AGE_DAYS", 30))
CACHE_TTL_MIN  = 60

_xdg_cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
_xdg_data  = Path(os.environ.get("XDG_DATA_HOME",  Path.home() / ".local/share"))
CACHE_DIR  = _xdg_cache / "arch-guardian"
LOG_DIR    = _xdg_data  / "arch-guardian"
CACHE_FILE = CACHE_DIR  / "feed_cache.json"
LOG_FILE   = LOG_DIR    / "arch-guardian.log"

RED_DARK   = "\033[1;41;97m"
ORANGE     = "\033[38;5;208m"
YELLOW     = "\033[1;33m"
GREEN_BOLD = "\033[1;92m"
BOLD       = "\033[1m"
RESET      = "\033[0m"


def _setup_logging():
    try:
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        logging.basicConfig(
            filename=str(LOG_FILE),
            level=logging.INFO,
            format="%(asctime)s %(levelname)s %(message)s",
        )
    except OSError:
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s %(levelname)s %(message)s",
        )

_setup_logging()
logger = logging.getLogger("arch-guardian")


def get_version_info():
    updates = {}
    try:
        out = subprocess.check_output(
            ['pacman', '-Qu'], stderr=subprocess.DEVNULL
        ).decode('utf-8')
        for line in out.splitlines():
            parts = line.split()
            if len(parts) >= 4:
                updates[parts[0]] = (parts[1], parts[3])
    except subprocess.CalledProcessError:
        pass
    return updates


def load_cached_feed():
    try:
        if not CACHE_FILE.exists():
            return None
        data = json.loads(CACHE_FILE.read_text())
        cached_at = datetime.fromisoformat(data["cached_at"])
        if datetime.now() - cached_at < timedelta(minutes=CACHE_TTL_MIN):
            return data["content"]
    except (json.JSONDecodeError, KeyError, ValueError, OSError):
        pass
    return None


def save_feed_cache(content_bytes):
    try:
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        CACHE_FILE.write_text(json.dumps({
            "cached_at": datetime.now().isoformat(),
            "content":   content_bytes.decode('utf-8', errors='replace'),
        }))
    except OSError:
        pass


def fetch_feed():
    cached = load_cached_feed()
    if cached:
        return feedparser.parse(cached)
    response = requests.get(
        RSS_URL,
        headers={'User-Agent': 'ArchGuardian/6.0'},
        timeout=10,
    )
    response.raise_for_status()
    save_feed_cache(response.content)
    return feedparser.parse(response.content)


def clean_version(v):
    return v.split('-')[0].split(':')[-1]


def version_match(pkg_name, current_v, new_v, news_text):
    pattern = rf'{re.escape(pkg_name)}\s*(?:>=|>|<=|<|==|=)?\s*([0-9][a-z0-9\.\-\:\+]+)'
    matches = re.findall(pattern, news_text.lower())
    if not matches:
        return True
    vn_list = [clean_version(m) for m in matches]
    vnew  = clean_version(new_v)
    vcurr = clean_version(current_v)
    return any(vn in vnew or vn in vcurr for vn in vn_list)


def analyze_risk(pkg, v_info, title, content_body):
    full_text = f"{title} {content_body}".lower()
    curr_v, new_v = v_info

    if not version_match(pkg, curr_v, new_v, full_text):
        return None, None, None

    keywords = {
        r"manual intervention": 15,
        r"requires manual":     15,
        r"breaking change":     15,
        r"reinstall":           10,
        r"security":             8,
        r"vulnerability":        8,
    }
    risk_score = sum(score for kw, score in keywords.items() if re.search(kw, full_text))

    core_pkgs = ['linux', 'systemd', 'glibc', 'pacman', 'grub', 'base']
    if any(core in pkg for core in core_pkgs):
        risk_score *= 1.3

    if risk_score >= 15:
        return "CRITICAL", f"Action required for {pkg}", RED_DARK
    return "NOTICE", f"Relevant update for {pkg}", YELLOW


def check_arch_news(updates):
    try:
        feed = fetch_feed()
    except Exception as exc:
        logger.warning("Failed to fetch Arch news: %s", exc)
        return "CONTINUE"

    relevant_news = []
    found_critical = False
    date_limit = datetime.now() - timedelta(days=AGE_LIMIT_DAYS)

    for entry in feed.entries:
        try:
            dt = datetime(*entry.published_parsed[:6])
            if dt < date_limit:
                continue
        except (AttributeError, TypeError, ValueError):
            continue

        content = f"{entry.title} {entry.get('description', '')} {entry.get('summary', '')}".lower()
        if 'content' in entry:
            content += entry.content[0].value.lower()

        for pkg, v_info in updates.items():
            if pkg in content or (pkg == "linux" and "kernel" in content):
                status, msg, color = analyze_risk(pkg, v_info, entry.title, content)
                if status:
                    relevant_news.append((pkg, status, msg, color, entry.title, entry.link))
                    if status == "CRITICAL":
                        found_critical = True
                    logger.info("%s %s -> %s | %s", status, pkg, v_info[1], entry.title)
                break

    if not relevant_news:
        return "CONTINUE"

    relevant_news.sort(key=lambda x: 0 if x[1] == "CRITICAL" else 1)

    print(f"\n{BOLD}--- ARCH NEWS ANALYSIS REPORT ---{RESET}")
    for pkg, status, msg, color, title, link in relevant_news:
        print(f"\n{color}{BOLD}[{status}]{RESET} {pkg} ({updates[pkg][0]} -> {updates[pkg][1]})")
        print(f"Info: {msg}\nNews: {title}\nLink: {link}")

    prompt = (
        f"\n{RED_DARK} CRITICAL RISK! {RESET} Continue upgrade? (y/N): "
        if found_critical
        else "\nProceed with update? (Y/n): "
    )
    try:
        ans = input(prompt).strip().lower()
        if found_critical:
            return "CONTINUE" if ans == 'y' else "ABORT"
        return "ABORT" if ans == 'n' else "CONTINUE"
    except EOFError:
        return "ABORT"


def main():
    try:
        result = subprocess.run(['sudo', '-v'], check=False)
        if result.returncode != 0:
            return

        print(f"{BOLD}:: Synchronizing databases...{RESET}")
        sync = subprocess.run(['sudo', 'pacman', '-Sy'], check=False)
        if sync.returncode != 0:
            return

        updates = get_version_info()
        if not updates:
            print(f"{GREEN_BOLD}:: System is up-to-date.{RESET}")
            return

        status = check_arch_news(updates)

        if status == "CONTINUE":
            subprocess.run(['sudo', 'pacman', '-Su'], check=False)
        else:
            print(f"\n{ORANGE}:: Upgrade postponed.{RESET}")

    except KeyboardInterrupt:
        print("\n:: Cancelled.")
        sys.exit(1)


if __name__ == "__main__":
    main()
