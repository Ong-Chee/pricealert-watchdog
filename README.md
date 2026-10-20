# pricealert-watchdog

PriceAlertBot 서버(개인 PC)가 꺼졌는지 감시합니다.

- PC가 2분마다 저장소 변수 `HEARTBEAT`에 현재 시각을 기록합니다.
- 이 저장소의 GitHub Actions가 5분마다 `check.sh`를 실행합니다. 기록이 10분(`STALE_MIN`) 넘게 끊겼으면 텔레그램으로 한 번 알립니다.
- 봇 토큰과 chat_id는 암호화된 Actions 비밀값(`BOT_TOKEN`, `CHAT_IDS`)에 있습니다. 코드와 실행 기록에는 남지 않습니다.
- 정상 종료할 때는 `HEARTBEAT`가 `stopped:…`로 바뀌어 알리지 않습니다.

이 저장소는 PriceAlertBot의 `setup_watchdog.py`가 만들고 관리합니다.
