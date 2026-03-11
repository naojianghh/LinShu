@echo off
cd /d "%~dp0lingshu_backend"
if not exist package.json (
  echo [ERROR] 未找到 lingshu_backend\package.json，请确认目录结构。
  pause
  exit /b 1
)

echo [INFO] 当前目录: %cd%
echo [INFO] 正在启动后端服务...
npm start

