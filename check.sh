#!/usr/bin/env bash
# PriceAlertBot 꺼짐 감시 — GitHub Actions 에서 5분마다 실행됩니다.
# PC(엔진)가 2분마다 저장소 변수 HEARTBEAT 에 현재 시각(epoch 초)을 기록합니다.
# 마지막 기록이 STALE_MIN 분보다 오래되면 텔레그램으로 한 번 알립니다(장애 1건당 1번).
# 공개 저장소라 실행 기록이 공개되므로 시각 · chat_id 같은 값은 출력하지 않습니다.
set -euo pipefail
export LC_ALL=C.UTF-8

API="${TG_API:-https://api.telegram.org}"
STALE_MIN="${STALE_MIN:-10}"
hb="${HEARTBEAT:-}"
now=$(date +%s)

case "$hb" in
  "" | stopped:*) echo "감시 안 함: 신호 없음 또는 정상 종료 상태"; exit 0 ;;
esac

age=$(( (now - hb) / 60 ))
if [ "$age" -lt "$STALE_MIN" ]; then
  echo "정상"
  exit 0
fi

alerted=$(cat state/alerted 2>/dev/null || true)
if [ "$alerted" = "$hb" ]; then
  echo "꺼짐 상태 지속 (이미 알림 보냄)"
  exit 0
fi

echo "꺼짐 감지"
last=$(date -u -d "@$((hb + 9 * 3600))" '+%m-%d %H:%M KST')  # 시간대 데이터 없이 KST(UTC+9) 계산
text=$(printf '⚠️ <b>PriceAlertBot 서버 응답 없음</b>\n마지막 신호: %s (%s분 전)\nPC 전원과 인터넷을 확인하세요.\n다시 켜지면 꺼져 있던 동안의 돌파를 지연 알림으로 보냅니다.' "$last" "$age")

if [ -z "${BOT_TOKEN:-}" ] || [ -z "${CHAT_IDS:-}" ]; then
  echo "BOT_TOKEN/CHAT_IDS 비밀값이 없어 발송을 건너뜁니다 (시험 모드)"
  exit 0
fi

IFS=',' read -ra ids <<< "$CHAT_IDS"
for id in "${ids[@]}"; do
  # 본문은 표준 입력으로 넘김(명령 인자 인코딩 변환 문제 방지)
  printf '%s' "$text" | curl -fsS -o /dev/null --retry 3 "$API/bot${BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${id}" --data-urlencode "text@-" -d parse_mode=HTML
done
echo "알림 보냄"

# 같은 장애로 다시 알리지 않도록 기록 (커밋은 저장소 활동으로도 잡혀 예약 실행 자동 중지를 막아 줌)
if [ "${NO_COMMIT:-}" != "1" ]; then
  mkdir -p state
  echo "$hb" > state/alerted
  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git add state/alerted
  git commit -q -m "watchdog: alerted"
  git push -q
fi
