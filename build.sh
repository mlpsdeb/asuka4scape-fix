#!/bin/bash
set -e
export THEOS=~/theos
export PATH="$THEOS/bin:$PATH"
echo "[*] Building asuka4scape..."
make clean
make
APP=$(find .theos -name "SPTMRace.app" -type d | head -1)
if [ -z "$APP" ]; then echo "[-] SPTMRace.app not found!"; exit 1; fi
echo "[*] Found app at: $APP"
cp SPTMRace.plist "$APP/Info.plist"
echo "[*] Signing with entitlements..."
ldid -SEntitlements.plist "$APP/SPTMRace"
echo "[*] Packaging IPA..."
rm -rf Payload SPTMRace.ipa
mkdir Payload
cp -r "$APP" Payload/
zip -r -q SPTMRace.ipa Payload/
rm -rf Payload
echo "[+] Done!"
echo "[+] IPA: $(pwd)/SPTMRace.ipa"
ls -la SPTMRace.ipa
