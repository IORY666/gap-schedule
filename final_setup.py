"""最终设置：桌面快捷方式 + 开机自启动"""
import os
import sys
import ctypes
import subprocess

def get_desktop():
    buf = ctypes.create_unicode_buffer(260)
    ctypes.windll.shell32.SHGetFolderPathW(None, 0, None, 0, buf)
    return buf.value

def get_startup():
    buf = ctypes.create_unicode_buffer(260)
    ctypes.windll.shell32.SHGetFolderPathW(None, 7, None, 0, buf)
    return buf.value

desktop = get_desktop()
startup = get_startup()
base_dir = os.path.dirname(os.path.abspath(__file__))

print(f"桌面: {desktop}")
print(f"启动: {startup}")
print(f"目录: {base_dir}")

# 清理旧的乱码文件
for d in [desktop]:
    try:
        for f in os.listdir(d):
            if 'Gap' in f and f.endswith('.vbs'):
                os.remove(os.path.join(d, f))
                print(f"已清理: {f}")
    except:
        pass

# PowerShell 创建快捷方式
def create_shortcut(link_path, target, args, workdir, desc):
    ps = f'''
$ws = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut("{link_path}")
$lnk.TargetPath = "{target}"
$lnk.Arguments = "{args}"
$lnk.WorkingDirectory = "{workdir}"
$lnk.Description = "{desc}"
$lnk.Save()
'''
    ps1 = os.path.join(base_dir, "_s.ps1")
    with open(ps1, 'w', encoding='utf-8-sig') as f:
        f.write(ps)
    subprocess.run(['powershell', '-ExecutionPolicy', 'Bypass', '-File', ps1],
                   capture_output=True)
    os.remove(ps1)
    return os.path.exists(link_path)

# 桌面快捷方式
ok1 = create_shortcut(
    os.path.join(desktop, "Gap任务日历.lnk"),
    "pythonw",
    os.path.join(base_dir, "desktop_widget.pyw"),
    base_dir,
    "Gap任务日历 - 桌面悬浮插件"
)
print(f"桌面快捷方式: {'OK' if ok1 else 'FAIL'}")

ok2 = create_shortcut(
    os.path.join(desktop, "Gap完整日历.lnk"),
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    f"--app=file:///{base_dir.replace(chr(92), '/')}/gap-schedule.html --window-size=420,750",
    base_dir,
    "Gap完整日历 - 浏览器版"
)
print(f"日历快捷方式: {'OK' if ok2 else 'FAIL'}")

# 开机自启动
ok3 = create_shortcut(
    os.path.join(startup, "Gap任务日历.lnk"),
    "pythonw",
    os.path.join(base_dir, "desktop_widget.pyw"),
    base_dir,
    "Gap任务日历 - 开机自启"
)
print(f"开机自启: {'OK' if ok3 else 'FAIL'}")

# 立刻启动
print("\n正在启动插件...")
subprocess.Popen(['pythonw', os.path.join(base_dir, 'desktop_widget.pyw')])
print("完成！请查看桌面右下角。")
print("\n提示：如果看不到窗口，请在桌面上双击 'Gap任务日历' 快捷方式。")
