#!/usr/bin/env python3
"""1.7 以降のストア画像を差し替える。前の版から引き継がれた画像を消してから入れる。

    python3 push-shots.py <版ID>
"""
import json, sys, urllib.request, urllib.error, hashlib

T = open("/tmp/he-token").read().strip()
V = sys.argv[1]
FOLDER = {"ja":"ja","en-US":"en","zh-Hans":"zh-Hans","zh-Hant":"zh-Hant","ko":"ko","es-ES":"es","fr-FR":"fr",
          "de-DE":"de","it":"it","pt-BR":"pt-BR","ru":"ru","ar-SA":"ar"}
FILES = ["01-home.png", "02-result.png", "03-detail.png", "04-settings.png"]

def api(path, body=None, method="GET"):
    req = urllib.request.Request(f"https://api.appstoreconnect.apple.com/v1/{path}",
        data=json.dumps(body).encode() if body else None, method=method,
        headers={"Authorization": f"Bearer {T}", "Content-Type": "application/json"})
    try:
        raw = urllib.request.urlopen(req).read(); return (json.loads(raw) if raw else {}), None
    except urllib.error.HTTPError as e:
        return None, e.read().decode()[:300]

locs = {l["attributes"]["locale"]: l["id"] for l in api(f"appStoreVersions/{V}/appStoreVersionLocalizations")[0]["data"]}
for loc, folder in FOLDER.items():
    lid = locs[loc]
    sets = api(f"appStoreVersionLocalizations/{lid}/appScreenshotSets")[0]["data"]
    s65 = [x for x in sets if x["attributes"]["screenshotDisplayType"] == "APP_IPHONE_65"]
    if s65:
        set_id = s65[0]["id"]
        for old in api(f"appScreenshotSets/{set_id}/appScreenshots")[0]["data"]:
            api(f"appScreenshots/{old['id']}", method="DELETE")
    else:
        r, _ = api("appScreenshotSets", {"data": {"type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": "APP_IPHONE_65"},
            "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": lid}}}}}, "POST")
        set_id = r["data"]["id"]
    ok = 0
    for name in FILES:
        data = open(f"screenshots-l10n/{folder}/{name}", "rb").read()
        r, err = api("appScreenshots", {"data": {"type": "appScreenshots",
            "attributes": {"fileSize": len(data), "fileName": name},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}}, "POST")
        if err: print(" ", loc, name, err); continue
        sid = r["data"]["id"]
        for op in r["data"]["attributes"]["uploadOperations"]:
            up = urllib.request.Request(op["url"], data=data[op["offset"]:op["offset"]+op["length"]], method=op["method"])
            for h in op["requestHeaders"]: up.add_header(h["name"], h["value"])
            urllib.request.urlopen(up)
        _, err = api(f"appScreenshots/{sid}", {"data": {"type": "appScreenshots", "id": sid,
            "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}}, "PATCH")
        ok += 0 if err else 1
        if err: print(" ", loc, name, err)
    print(f"  {loc}: {ok}/{len(FILES)} 枚")
