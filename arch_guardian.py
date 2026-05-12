#!/usr/bin/env python3
import feedparser
import re
import requests
import subprocess
import os
import sys
from datetime import datetime, timedelta

RSS_URL = "https://archlinux.org/feeds/news/"
AGE_LIMIT_DAYS = 30

RED_DARK   = "\033[1;41;97m"
ORANGE     = "\033[38;5;208m"
YELLOW     = "\033[1;33m"
GREEN_BOLD = "\033[1;92m" 
BOLD       = "\033[1m"
RESET      = "\033[0m"

def get_version_info():
    updates = {}
    try:
        out = subprocess.check_output(['pacman', '-Qu'], stderr=subprocess.DEVNULL).decode('utf-8')
        for line in out.splitlines():
            parts = line.split()
            if len(parts) >= 4:
                updates[parts[0]] = (parts[1], parts[3])
    except subprocess.CalledProcessError:
        pass
    return updates

def version_match(pkg_name, current_v, new_v, news_text):
    clean_v = lambda v: v.split('-')[0].split(':')[-1]
    pattern = rf'{re.escape(pkg_name)}\s*(>=|>|<=|<|==|=)?\s*([0-9][a-z0-9\.\-\:\+]+)'
    matches = re.findall(pattern, news_text.lower())
    
    if not matches: return True
    
    for op, v_news in matches:
        vn, vnew, vcurr = clean_v(v_news), clean_v(new_v), clean_v(current_v)
        if vn in vnew or vn in vcurr: return True
    return False

def analyze_risk(pkg, v_info, title, content_body):
    full_text = f"{title} {content_body}".lower()
    curr_v, new_v = v_info
    
    if not version_match(pkg, curr_v, new_v, full_text):
        return None, None, None
        
    risk_score = 0
    keywords = {
        r"manual intervention": 15,
        r"requires manual": 15,
        r"breaking change": 15,
        r"reinstall": 10,
        r"security": 8,
        r"vulnerability": 8
    }
    
    for kw, score in keywords.items():
        if re.search(kw, full_text): risk_score += score
            
    core_pkgs = ['linux', 'systemd', 'glibc', 'pacman', 'grub', 'base']
    if any(core in pkg for core in core_pkgs):
        risk_score *= 1.3
        
    if risk_score >= 15:
        return "CRITICAL", f"Action required for {pkg}", RED_DARK
    return "NOTICE", f"Relevant update for {pkg}", YELLOW

def check_arch_news(updates):
    try:
        response = requests.get(RSS_URL, headers={'User-Agent': 'ArchGuardian/6.0'}, timeout=10)
        feed = feedparser.parse(response.content)
    except:
        return "CONTINUE"

    relevant_news = []
    found_critical = False
    date_limit = datetime.now() - timedelta(days=AGE_LIMIT_DAYS)

    for entry in feed.entries:
        try:
            dt = datetime(*entry.published_parsed[:6])
            if dt < date_limit: continue
        except: continue

        content = f"{entry.title} {entry.get('description', '')} {entry.get('summary', '')}".lower()
        if 'content' in entry: content += entry.content[0].value.lower()
        
        for pkg, v_info in updates.items():
            if pkg in content or (pkg == "linux" and "kernel" in content):
                status, msg, color = analyze_risk(pkg, v_info, entry.title, content)
                if status:
                    relevant_news.append((pkg, status, msg, color, entry.title, entry.link))
                    if status == "CRITICAL": found_critical = True
                break

    if not relevant_news: return "CONTINUE"

    print(f"\n{BOLD}--- ARCH NEWS ANALYSIS REPORT ---{RESET}")
    for pkg, status, msg, color, title, link in relevant_news:
        print(f"\n{color}{BOLD}[{status}]{RESET} {pkg} ({updates[pkg][0]} -> {updates[pkg][1]})")
        print(f"Info: {msg}\nNews: {title}\nLink: {link}")
    
    prompt = f"\n{RED_DARK} CRITICAL RISK! {RESET} Continue upgrade? (y/N): " if found_critical else "\nProceed with update? (Y/n): "
    try:
        ans = input(prompt).lower()
        if found_critical: return "CONTINUE" if ans == 'y' else "ABORT"
        return "ABORT" if ans == 'n' else "CONTINUE"
    except EOFError:
        return "ABORT"

def main():
    try:
        if os.system('sudo -v') != 0: return
        
        print(f"{BOLD}:: Synchronizing databases...{RESET}")
        if os.system('sudo pacman -Sy') != 0: return

        updates = get_version_info()
        if not updates:
            print(f"{GREEN_BOLD}:: System is up-to-date.{RESET}")
            return

        status = check_arch_news(updates)
        
        if status == "CONTINUE":
            os.system('sudo pacman -Su')
        else:
            print(f"\n{ORANGE}:: Upgrade postponed.{RESET}")
            
    except KeyboardInterrupt:
        print("\n:: Cancelled.")
        sys.exit(1)

if __name__ == "__main__":
    main()
