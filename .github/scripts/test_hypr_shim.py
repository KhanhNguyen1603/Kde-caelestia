#!/usr/bin/env python3
import os
import re
import json
import sys

def main():
    # .github/scripts/test_hypr_shim.py -> .github/scripts -> .github -> root
    root_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    shell_dir = os.path.join(root_dir, "shell")
    map_file = os.path.join(root_dir, "src", "bin", "hypr_kwin_map.json")

    with open(map_file, "r") as f:
        schema = json.load(f)
    
    valid_verbs = set(schema.get("verbs", {}).keys())
    
    # Regex to find `dispatch("verb")` or `hyprctl dispatch verb` or `` dispatch(`verb`) ``
    # This is a bit tricky, we'll try to find any dispatch calls and extract the first word.
    
    errors = []
    
    for dirpath, _, filenames in os.walk(shell_dir):
        for filename in filenames:
            if not filename.endswith(".qml"):
                continue
                
            filepath = os.path.join(dirpath, filename)
            with open(filepath, "r", encoding="utf-8", errors="replace") as f:
                content = f.read()
                
            # Find dispatch("verb args") or dispatch(`verb args`) or dispatch('verb args')
            matches = re.findall(r'dispatch\(\s*[\'"`]([a-zA-Z]+)(?:[^\'"`]*?)[\'"`]', content)
            
            # Also find hyprctl dispatch verb
            matches2 = re.findall(r'hyprctl\s+dispatch\s+([a-zA-Z]+)', content)
            
            all_verbs = matches + matches2
            
            for verb in all_verbs:
                if verb == "action": # dynamic dispatch(action)
                    continue
                if verb not in valid_verbs:
                    errors.append(f"{os.path.relpath(filepath, root_dir)}: Found unregistered dispatch verb '{verb}'")
                    
    if errors:
        print("Test failed! Found unregistered verbs in QML files:")
        for e in errors:
            print("  " + e)
        sys.exit(1)
    else:
        print("All QML dispatch verbs are properly registered in hypr_kwin_map.json.")
        sys.exit(0)

if __name__ == "__main__":
    main()
