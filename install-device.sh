#!/bin/bash
# 修正のたびに実機へ入れるためのスクリプト。
# 接続中のiPhoneを自動で選ぶので、機種変更しても書き換え不要。
set -e
# xcodebuild | grep の形でも、ビルドの失敗で止まるように（引き継ぎ書 4-145）。
# 止まらないと、前のビルドの .app を入れて「完了」と出してしまう
set -o pipefail
cd "$(dirname "$0")/HealthExport"

# 設定画面のいちばん下に出す印。コミット数と時刻。未コミットの変更があれば + を付ける
STAMP="b$(git rev-list --count HEAD)$(git diff --quiet HEAD -- .. || echo +) $(date '+%m/%d %H:%M')"

# iPhoneに絞る。ペアリング済みのApple Watchも connected と出るため（引き継ぎ書 4-26）。
# no DDI は「中身を送れない状態」なので除く。
# grep の空振りで無言終了しないよう || true を付ける（4-19）。
LINE=$(xcrun devicectl list devices 2>/dev/null | grep '(iPhone' | grep -E ' (connected|available \(paired\)) ' | grep -v 'no DDI' | head -1 || true)
if [ -z "$LINE" ]; then
  echo "❌ iPhoneが接続されていません（USBで繋いで、ロックを解除してください）"
  exit 1
fi
DEV=$(echo "$LINE" | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
MODEL=$(echo "$LINE" | sed -E 's/.*(connected|available \(paired\)) +//')
echo "→ ${MODEL} にインストールします"

xcodebuild -project HealthExport.xcodeproj -scheme HealthExport -configuration Debug \
  -destination "platform=iOS,id=$DEV" -destination-timeout 30 -derivedDataPath /tmp/hx-device \
  HEALTHEXPORT_BUILD_STAMP="$STAMP" \
  -allowProvisioningUpdates build 2>&1 | grep -E "error:|BUILD SUCCEEDED"

xcrun devicectl device install app --device "$DEV" \
  /tmp/hx-device/Build/Products/Debug-iphoneos/HealthExport.app 2>&1 | grep -E "bundleID"
APP=/tmp/hx-device/Build/Products/Debug-iphoneos/HealthExport.app
echo "   入れた印: $(/usr/libexec/PlistBuddy -c 'Print HealthExportBuildStamp' "$APP/Info.plist")"
echo "✅ 完了　設定（詳しい設定 → 形式）のいちばん下に「$STAMP」が出ていれば入れ替わっています"
