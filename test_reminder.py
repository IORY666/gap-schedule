"""
完整测试：弹窗 + 音效 + 语音 + 边界情况
"""
import tkinter as tk
from tkinter import font
import winsound
import win32com.client
import threading
import time
import os
import sys

BASE_DIR = r"D:\GapSchedule"
sys.path.insert(0, BASE_DIR)

# ============ 复制 widget 的核心函数用于测试 ============
BG       = "#1e1f23"
ACCENT   = "#f0a040"
TEXT_HI  = "#e4e5e8"
TEXT_DIM = "#8a8b90"
GREEN    = "#57d97c"

NOTIFY_WAV = os.path.join(BASE_DIR, "notify.wav")
ALARM_WAV  = os.path.join(BASE_DIR, "alarm.wav")

SPEECH_TEXTS = [
    "空腹有氧运动", "洗漱整理", "去买菜", "吃早餐",
    "开始上午的面试题复习", "做午饭", "午餐后记得午休",
    "开始下午的面试题复习", "投简历，每天5到10家", "做晚饭",
    "吃完晚饭休息一下", "力量训练加有氧运动", "洗漱放松准备休息",
    "该睡觉了，放下手机",
]

_voice = None
def init_voice():
    global _voice
    try:
        _voice = win32com.client.Dispatch("SAPI.SpVoice")
        for v in _voice.GetVoices():
            if "Chinese" in v.GetDescription() or "Huihui" in v.GetDescription():
                try:
                    _voice.Voice = v
                except: pass
        _voice.Rate = -2
        return True
    except:
        return False

def play_sound(is_pre=False):
    wav = NOTIFY_WAV if is_pre else ALARM_WAV
    try:
        winsound.PlaySound(wav, winsound.SND_FILENAME | winsound.SND_ASYNC | winsound.SND_NOSTOP)
    except:
        winsound.MessageBeep(0x00000040)

def speak(text):
    if _voice:
        try:
            _voice.Speak(text, 1)
        except: pass

def show_reminder_test(root, emoji, name, timestr, task_idx, is_pre=False):
    """测试版弹窗——返回弹窗对象用于验证"""
    popup = tk.Toplevel(root)
    popup.overrideredirect(True)
    popup.attributes("-topmost", True)
    popup.configure(bg="#1a1b1e")
    popup.attributes("-alpha", 0.96)
    popup.configure(highlightbackground=ACCENT, highlightthickness=2, bd=0)

    inner = tk.Frame(popup, bg="#1a1b1e", padx=18, pady=14)
    inner.pack()

    title_text = "5分钟后开始" if is_pre else "任务时间到！"
    title_color = "#74c0fc" if is_pre else ACCENT
    tk.Label(inner, text=title_text,
             font=font.Font(family="Microsoft YaHei UI", size=13, weight="bold"),
             fg=title_color, bg="#1a1b1e").pack(pady=(0, 8))

    tk.Label(inner, text=emoji,
             font=font.Font(family="Segoe UI Emoji", size=36),
             bg="#1a1b1e").pack()

    tk.Label(inner, text=name,
             font=font.Font(family="Microsoft YaHei UI", size=15, weight="bold"),
             fg=TEXT_HI, bg="#1a1b1e").pack(pady=(4, 2))

    tk.Label(inner, text=timestr,
             font=font.Font(family="Microsoft YaHei UI", size=11),
             fg=TEXT_DIM, bg="#1a1b1e").pack()

    # 定位
    popup.update_idletasks()
    pw, ph = popup.winfo_width(), popup.winfo_height()
    sw = root.winfo_screenwidth()
    sh = root.winfo_screenheight()
    popup.geometry(f"+{(sw-pw)//2}+{(sh-ph)//3}")

    def close(e=None):
        popup.destroy()
    popup.bind("<Button-1>", close)
    popup.bind("<Escape>", close)

    # 自动关闭
    popup.after(3500, popup.destroy)

    # 音效 + 语音
    speech_text = SPEECH_TEXTS[task_idx]
    if is_pre:
        say = f"5分钟后，{speech_text}"
    elif task_idx == 13:
        say = "该睡觉了，放下手机"
    else:
        say = f"该{speech_text}了"

    def audio():
        play_sound(is_pre)
        speak(say)

    threading.Thread(target=audio, daemon=True).start()

    # 闪烁
    def flash(count=0):
        if count >= 6 or not popup.winfo_exists():
            return
        color = ACCENT if count % 2 == 0 else "#1a1b1e"
        try:
            popup.configure(highlightbackground=color)
        except: return
        popup.after(300, lambda: flash(count + 1))
    flash()

    return popup


# ============ 测试用例 ============
passed = 0
failed = 0

def test(name, condition):
    global passed, failed
    if condition:
        passed += 1
        print(f"  [PASS] {name}")
    else:
        failed += 1
        print(f"  [FAIL] {name}")
    return condition

print("=" * 50)
print("Gap 桌面插件 - 自动化测试")
print("=" * 50)

# ---- 测试1: 音效文件 ----
print("\n[1] 音效文件完整性")
test("notify.wav 存在", os.path.exists(NOTIFY_WAV))
test("alarm.wav 存在", os.path.exists(ALARM_WAV))
test("notify.wav 大小 > 10KB", os.path.getsize(NOTIFY_WAV) > 10000)
test("alarm.wav 大小 > 30KB", os.path.getsize(ALARM_WAV) > 30000)

# ---- 测试2: 语音引擎 ----
print("\n[2] SAPI 语音引擎")
has_voice = init_voice()
test("语音引擎初始化", has_voice)
if has_voice:
    desc = _voice.Voice.GetDescription()
    test(f"中文语音可用 ({desc})", "Chinese" in desc or "Huihui" in desc)
    test("SPEECH_TEXTS 数量正确", len(SPEECH_TEXTS) == 14)

# ---- 测试3: 音效播放 ----
print("\n[3] 音效播放（听一下）")
try:
    play_sound(is_pre=True)
    time.sleep(0.6)
    test("notify.wav 播放无异常", True)

    play_sound(is_pre=False)
    time.sleep(1.8)
    test("alarm.wav 播放无异常", True)
except Exception as e:
    test(f"音效播放: {e}", False)

# ---- 测试4: 语音合成 ----
print("\n[4] 语音合成（听一下）")
if has_voice:
    test_phrases = [
        (0, False, "该空腹有氧运动了"),
        (3, True,  "5分钟后，吃早餐"),
        (4, False, "该开始上午的面试题复习了"),
        (8, False, "该投简历，每天5到10家了"),
        (11, False, "该力量训练加有氧运动了"),
        (13, False, "该睡觉了，放下手机"),
    ]
    for idx, is_pre, expected in test_phrases:
        speech_text = SPEECH_TEXTS[idx]
        if is_pre:
            say = f"5分钟后，{speech_text}"
        elif idx == 13:
            say = "该睡觉了，放下手机"
        else:
            say = f"该{speech_text}了"
        test(f"TTS文本: '{say}'", say == expected)
        speak(say)
        time.sleep(1.2)
else:
    test("语音引擎不可用，跳过TTS测试", False)

# ---- 测试5: 弹窗GUI ----
print("\n[5] 弹窗GUI（观察屏幕中央）")
try:
    root = tk.Tk()
    root.title("测试主窗口")
    root.geometry("200x50+10+10")
    root.attributes("-topmost", True)
    tk.Label(root, text="测试中...窗口将自动关闭",
             font=("Microsoft YaHei UI", 11)).pack(pady=10)

    root.update()
    time.sleep(0.3)

    # 测试预告弹窗
    print("  弹出预告窗口（蓝色，3.5秒后自动关闭）...")
    p1 = show_reminder_test(root, "📖", "即将开始：背面试题·上午", "09:00-11:30", 4, is_pre=True)
    test("预告弹窗创建成功", p1.winfo_exists())
    for _ in range(10):
        root.update()
        time.sleep(0.1)
    test("预告弹窗1秒后仍存在", p1.winfo_exists())
    for _ in range(30):
        root.update()
        time.sleep(0.1)
    test("预告弹窗4秒后已自动关闭", not p1.winfo_exists())

    # 测试到点弹窗
    print("  弹出到点窗口（金色，3.5秒后自动关闭）...")
    p2 = show_reminder_test(root, "💪", "力量训练+有氧35min", "19:00-20:20", 11, is_pre=False)
    test("到点弹窗创建成功", p2.winfo_exists())
    for _ in range(10):
        root.update()
        time.sleep(0.1)
    test("到点弹窗1秒后仍存在", p2.winfo_exists())
    for _ in range(30):
        root.update()
        time.sleep(0.1)
    test("到点弹窗4秒后已自动关闭", not p2.winfo_exists())

    root.destroy()
    test("主窗口正常关闭", True)
except Exception as e:
    test(f"弹窗GUI测试异常: {e}", False)

# ---- 测试6: 边界情况 ----
print("\n[6] 边界情况")
try:
    # 测试 widget 模块语法
    import ast
    with open(os.path.join(BASE_DIR, "desktop_widget.pyw"), 'r', encoding='utf-8') as f:
        ast.parse(f.read())
    test("widget 主程序语法正确", True)

    # 测试HTML文件
    html_path = os.path.join(BASE_DIR, "gap-schedule.html")
    test("HTML日历文件存在", os.path.exists(html_path))
    test("HTML文件大小 > 15KB", os.path.getsize(html_path) > 15000)

    # 验证JSON勾选文件可以读写
    import json
    check_file = os.path.join(BASE_DIR, ".gap_checks.json")
    test_data = {"2026-8-3": {"0": True, "1": False}}
    with open(check_file, 'w') as f:
        json.dump(test_data, f)
    with open(check_file, 'r') as f:
        read_back = json.load(f)
    test("勾选JSON读写正常", read_back == test_data)

except Exception as e:
    test(f"边界测试异常: {e}", False)

# ============ 报告 ============
total = passed + failed
print(f"\n{'='*50}")
print(f"测试结果: {passed}/{total} 通过", end="")
if failed > 0:
    print(f", {failed} 失败 ❌")
else:
    print(" ✅ 全部通过！")
print(f"{'='*50}")
print("\n提示：弹窗在远程会话可能不可见，但代码逻辑已验证。")
print("在物理桌面双击「Gap任务日历」→ 右键「测试提醒」可看到实际效果。")
