import smtplib, os
from email.mime.text import MIMEText
from datetime import datetime

sender = os.environ.get('SENDER_EMAIL', '')
password = os.environ.get('SENDER_PASSWORD', '')
receiver = 'eomdeng@gmail.com'

if not sender or not password:
    print('SENDER_EMAIL/SENDER_PASSWORD Secrets not set')
    exit(0)

repo = os.environ.get('GITHUB_REPOSITORY', '')
run_id = os.environ.get('GITHUB_RUN_ID', '')
server_url = os.environ.get('GITHUB_SERVER_URL', 'https://github.com')

apk_size_mb = os.path.getsize('build/SpaceShooter.apk') / 1024 / 1024
download_url = server_url + '/' + repo + '/actions/runs/' + run_id
now = datetime.now().strftime('%Y-%m-%d %H:%M')

body = (
    'SpaceShooter APK 빌드 완료!\n\n'
    '빌드 시간: ' + now + '\n'
    '파일 크기: ' + str(round(apk_size_mb, 1)) + ' MB\n\n'
    '다운로드 링크 (GitHub Actions):\n'
    + download_url + '\n\n'
    '위 링크에서 "Artifacts" 섹션의 "SpaceShooter-APK"를 클릭하면 APK를 다운로드할 수 있습니다.\n\n'
    '설치 방법:\n'
    '1. 위 링크에서 APK 다운로드\n'
    '2. 폰에서 열기\n'
    '3. "알 수 없는 앱 설치" 허용\n'
    '4. 설치 완료\n'
)

msg = MIMEText(body, 'plain')
msg['From'] = sender
msg['To'] = receiver
msg['Subject'] = '[SpaceShooter] APK 빌드 완료 - ' + now

try:
    with smtplib.SMTP_SSL('smtp.gmail.com', 465) as s:
        s.login(sender, password)
        s.send_message(msg)
    print('이메일 발송 성공!')
except Exception as e:
    print('이메일 발송 실패: ' + str(e))
