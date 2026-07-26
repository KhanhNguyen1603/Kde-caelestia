#!/usr/bin/env python3
# Extract a window's _NET_WM_ICON (XWayland) to a cached PNG and print its path.
# Usage: caelestia-winicon.py --class "<res_class>" [--title "<title>"]
import sys, os, argparse, hashlib
try:
    from Xlib import display, X
    from PIL import Image
except Exception:
    sys.exit(0)

CACHE = os.path.expanduser("~/.cache/caelestia/winicons")
os.makedirs(CACHE, exist_ok=True)

def get_prop(d, w, atom, ptype=X.AnyPropertyType):
    try:
        return w.get_full_property(atom, ptype)
    except Exception:
        return None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--class", dest="cls", default="")
    ap.add_argument("--title", dest="title", default="")
    a = ap.parse_args()
    cls = (a.cls or "").strip()
    if not cls and not a.title:
        return
    key = hashlib.sha1((cls + "|" + a.title).encode()).hexdigest()[:16]
    out = os.path.join(CACHE, key + ".png")
    if os.path.exists(out) and os.path.getsize(out) > 0:
        print(out); return

    try:
        d = display.Display()
    except Exception:
        return
    root = d.screen().root
    NET_CLIENT_LIST = d.intern_atom('_NET_CLIENT_LIST')
    NET_WM_ICON = d.intern_atom('_NET_WM_ICON')
    NET_WM_NAME = d.intern_atom('_NET_WM_NAME')
    lst = get_prop(d, root, NET_CLIENT_LIST)
    if not lst:
        return
    clow = cls.lower(); tlow = (a.title or "").lower()
    cand = None
    for wid in lst.value:
        w = d.create_resource_object('window', wid)
        try:
            wmclass = w.get_wm_class()  # (res_name, res_class)
        except Exception:
            wmclass = None
        name = ""
        p = get_prop(d, w, NET_WM_NAME)
        if p:
            try: name = p.value.decode('utf-8', 'ignore')
            except Exception: name = str(p.value)
        rc = (wmclass[1] if wmclass else "") or ""
        rn = (wmclass[0] if wmclass else "") or ""
        match = False
        if clow and (rc.lower() == clow or rn.lower() == clow or clow in rc.lower() or rc.lower() in clow):
            match = True
        elif tlow and name and (tlow in name.lower() or name.lower() in tlow):
            match = True
        if not match:
            continue
        icon = get_prop(d, w, NET_WM_ICON)
        if icon and len(icon.value) >= 2:
            cand = icon.value
            break
    if not cand:
        return
    arr = list(cand); i = 0; best = None
    while i + 2 <= len(arr):
        wdt = arr[i]; hgt = arr[i+1]; i += 2
        n = wdt * hgt
        if n <= 0 or i + n > len(arr): break
        px = arr[i:i+n]; i += n
        if best is None or wdt*hgt > best[0]*best[1]:
            best = (wdt, hgt, px)
    if not best:
        return
    wdt, hgt, px = best
    img = Image.new('RGBA', (wdt, hgt))
    img.putdata([((v>>16)&0xff, (v>>8)&0xff, v&0xff, (v>>24)&0xff) for v in px])
    img.save(out)
    print(out)

if __name__ == "__main__":
    main()
