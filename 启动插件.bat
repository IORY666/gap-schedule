@echo off
chcp 65001 >nul
title 启动 Gap 任务日历插件...

:: 查找 Chrome 路径
set CHROME=
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" set CHROME=C:\Program Files\Google\Chrome\Application\chrome.exe
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" set CHROME=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" set CHROME=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe

:: 查找 Edge 路径（备选）
set EDGE=
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" set EDGE=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe
if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" set EDGE=C:\Program Files\Microsoft\Edge\Application\msedge.exe

if not "%CHROME%"=="" (
    echo 使用 Chrome 打开...
    start "" "%CHROME%" --app="file:///D:/GapSchedule/gap-schedule.html" --window-size=420,750 --window-position=1400,40
    goto :end
)

if not "%EDGE%"=="" (
    echo 使用 Edge 打开...
    start "" "%EDGE%" --app="file:///D:/GapSchedule/gap-schedule.html" --window-size=420,750 --window-position=1400,40
    goto :end
)

:: 都没找到，用默认浏览器
echo 使用默认浏览器打开...
start "" "file:///D:/GapSchedule/gap-schedule.html"

:end
echo.
echo ✅ 插件已启动！
echo 💡 提示：Windows 11 按 Win+Ctrl+T 可置顶窗口（需安装 PowerToys）
echo 💡 也可用 DeskPins 等工具置顶窗口
timeout /t 2 >nul
