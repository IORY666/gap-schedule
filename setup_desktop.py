"""在桌面创建快捷方式并启动插件"""
import os
import sys
import ctypes
import subprocess

# 1. 获取桌面路径
CSIDL_DESKTOP = 0
buf = ctypes.create_unicode_buffer(260)
ctypes.windll.shell32.SHGetFolderPathW(None, CSIDL_DESKTOP, None, 0, buf)
desktop = buf.value
print(f"桌面路径: {desktop}")

# 2. 创建快捷方式（用 PowerShell 通过 subprocess 调用，UTF-8 编码）
ps_script = f'''
$desktop = [Environment]::GetFolderPath("Desktop")
$WshShell = New-Object -ComObject WScript.Shell

$lnk1 = $WshShell.CreateShortcut("$desktop\\Gap任务日历.lnk")
$lnk1.TargetPath = "pythonw"
$lnk1.Arguments = "D:\\GapSchedule\\desktop_widget.pyw"
$lnk1.WorkingDirectory = "D:\\GapSchedule"
$lnk1.Description = "Gap任务日历桌面悬浮插件"
$lnk1.Save()
Write-Host "OK: Gap任务日历.lnk"

$lnk2 = $WshShell.CreateShortcut("$desktop\\Gap完整日历.lnk")
$lnk2.TargetPath = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
$lnk2.Arguments = "--app=file:///D:/GapSchedule/gap-schedule.html --window-size=420,750"
$lnk2.WorkingDirectory = "D:\\GapSchedule"
$lnk2.Description = "Gap完整日历"
$lnk2.Save()
Write-Host "OK: Gap完整日历.lnk"
'''

# Write ps1 with BOM UTF-8
ps1_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_temp.ps1")
with open(ps1_path, 'w', encoding='utf-8-sig') as f:
    f.write(ps_script)

result = subprocess.run(
    ['powershell', '-ExecutionPolicy', 'Bypass', '-File', ps1_path],
    capture_output=True, text=True
)
print(result.stdout)
if result.stderr:
    print("ERR:", result.stderr)

os.remove(ps1_path)

# 3. 启动桌面悬浮插件
print("\n启动桌面悬浮插件...")
subprocess.Popen(['pythonw', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'desktop_widget.pyw')],
                 creationflags=subprocess.CREATE_NO_WINDOW if hasattr(subprocess, 'CREATE_NO_WINDOW') else 0)

print("完成！请查看桌面右下角的悬浮窗口。")
print("桌面上的快捷方式可下次快速启动。")
input("按 Enter 退出...")
