"""
Gap 任务日历 · 桌面悬浮插件 v3
- 提前10分钟提醒 + Snooze推迟 | 甜美女声晓伊语音
- 始终置顶 | 左键拖拽 | 右键菜单 | 任务勾选
"""
import tkinter as tk
from tkinter import font
from datetime import datetime, date
import json, os, threading, ctypes, time, winsound

# ============ 数据 ============
SCHEDULE = [
    ("🏃", "07:00-07:45", "空腹有氧45min",     "快走/慢跑/跳绳"),
    ("🧹", "07:45-08:00", "洗漱整理",           "冲澡换衣服"),
    ("🛒", "08:00-08:30", "买菜",               "菜市场/超市"),
    ("☕", "08:30-09:00", "早餐",               "健康早餐+蛋白质"),
    ("📖", "09:00-11:30", "背面试题 · 上午",    "专注刷题2.5小时"),
    ("🍳", "11:30-12:30", "做午饭",             "简单营养午餐"),
    ("🍽️", "12:30-14:00", "午餐 + 午休",       "饭后午睡30分钟"),
    ("📖", "14:00-16:00", "背面试题 · 下午",    "专注刷题2小时"),
    ("📤", "16:00-17:00", "投简历",             "Boss/拉钩/脉脉 5-10家"),
    ("🍳", "17:00-18:00", "做晚饭",             "自己做饭"),
    ("🍽️", "18:00-19:00", "晚餐 + 休息",       "饭后散步/放松"),
    ("💪", "19:00-20:20", "力量训练+有氧35min", "力量45分+有氧35分"),
    ("🛀", "20:20-21:00", "洗漱放松",           "复盘今日+规划明日"),
    ("😴", "22:30-23:00", "睡觉",               "保证7-8小时睡眠"),
]
WEEKDAYS = ["周一","周二","周三","周四","周五","周六","周日"]
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CHECK_FILE = os.path.join(BASE_DIR, ".gap_checks.json")
VOICE_DIR = os.path.join(BASE_DIR, "voice")
NOTIFY_WAV = os.path.join(BASE_DIR, "notify.wav")
ALARM_WAV  = os.path.join(BASE_DIR, "alarm.wav")

# ============ 配色 ============
BG       = "#1e1f23"; SURFACE  = "#292a2f"; BORDER   = "#3a3b40"
TEXT     = "#c8c9cc"; TEXT_DIM = "#8a8b90"; TEXT_HI  = "#e4e5e8"
ACCENT   = "#f0a040"; GREEN    = "#57d97c"; RED_SOFT = "#ff6b6b"
BTN_BG   = "#33353b"; BTN_HOVER = "#44464d"

# ============ 全局状态 ============
_snoozed = {}          # {task_idx: next_alert_min}  推迟到何时再提醒
_dismissed = set()     # 已"离开"的任务索引（当天有效）
_on_time_done = set()  # 已弹出过"到点提醒"的任务（防止重复）
_last_date = date.today()
_alarm_enabled = True
_pending_snooze_timer = None  # root.after 自动snooze定时器ID

# ============ 主窗口 ============
root = tk.Tk()
root.title("Gap 任务日历")
root.overrideredirect(True)
root.attributes("-topmost", True)
root.attributes("-alpha", 0.95)
root.configure(bg=BG)

# ============ 拖拽 ============
_dx, _dy = 0, 0
def drag_start(e):
    global _dx, _dy; _dx, _dy = e.x, e.y
def drag_move(e):
    root.geometry(f"+{root.winfo_x()+e.x-_dx}+{root.winfo_y()+e.y-_dy}")

# ============ 辅助 ============
def load_checks():
    try:
        with open(CHECK_FILE, 'r') as f: return json.load(f)
    except: return {}
def save_checks(data):
    with open(CHECK_FILE, 'w') as f: json.dump(data, f)
def today_str():
    d = date.today(); return f"{d.year}-{d.month}-{d.day}"
def is_rest_day():
    return date.today().weekday() == 5
def open_html():
    import webbrowser
    webbrowser.open(f"file:///{os.path.join(BASE_DIR, 'gap-schedule.html').replace(os.sep, '/')}")

# ============ MCI 音频播放 ============
def play_wav(path):
    """异步播放WAV音效"""
    try:
        winsound.PlaySound(path, winsound.SND_FILENAME | winsound.SND_ASYNC | winsound.SND_NOSTOP)
    except: pass

def play_mp3(path):
    """MCI异步播放mp3语音"""
    if not os.path.exists(path): return
    try:
        alias = "gap_voice"
        ctypes.windll.winmm.mciSendStringW(f'close {alias}', None, 0, None)
        ret = ctypes.windll.winmm.mciSendStringW(
            f'open "{path}" type mpegvideo alias {alias}', None, 0, None)
        if ret == 0:
            ctypes.windll.winmm.mciSendStringW(f'play {alias}', None, 0, None)
    except: pass

def play_voice(idx, mode):
    """播放预生成语音: mode = '10m' | 'pre' | 'now'"""
    path = os.path.join(VOICE_DIR, f"{idx}_{mode}.mp3")
    threading.Thread(target=lambda: [play_wav(NOTIFY_WAV if mode != 'now' else ALARM_WAV), play_mp3(path)], daemon=True).start()

# ============ Snooze 弹窗 ============
def show_snooze_popup(task_idx, emoji, name, timestr, start_min):
    """提前10分钟弹窗，带推迟按钮"""
    global _pending_snooze_timer

    popup = tk.Toplevel(root)
    popup.overrideredirect(True)
    popup.attributes("-topmost", True)
    popup.configure(bg="#1a1b1e")
    popup.attributes("-alpha", 0.96)
    popup.configure(highlightbackground=ACCENT, highlightthickness=2, bd=0)

    inner = tk.Frame(popup, bg="#1a1b1e", padx=20, pady=16)
    inner.pack()

    # 标题
    now = datetime.now()
    remain = start_min - (now.hour * 60 + now.minute)
    tk.Label(inner, text=f"⏰ 还有{remain}分钟开始",
             font=font.Font(family="Microsoft YaHei UI", size=12, weight="bold"),
             fg=ACCENT, bg="#1a1b1e").pack(pady=(0, 8))

    # 大emoji + 任务名
    tk.Label(inner, text=emoji,
             font=font.Font(family="Segoe UI Emoji", size=36),
             bg="#1a1b1e").pack()
    tk.Label(inner, text=name,
             font=font.Font(family="Microsoft YaHei UI", size=14, weight="bold"),
             fg=TEXT_HI, bg="#1a1b1e").pack(pady=(2, 0))
    tk.Label(inner, text=timestr,
             font=font.Font(family="Microsoft YaHei UI", size=10),
             fg=TEXT_DIM, bg="#1a1b1e").pack(pady=(0, 10))

    # 按钮行
    btn_frame = tk.Frame(inner, bg="#1a1b1e")
    btn_frame.pack()

    def make_btn(text, color, cmd):
        btn = tk.Label(btn_frame, text=text, fg=color, bg=BTN_BG,
                       font=font.Font(family="Microsoft YaHei UI", size=11, weight="bold"),
                       padx=14, pady=6, cursor="hand2",
                       relief="flat", bd=0, highlightthickness=0)
        btn.bind("<Enter>", lambda e: btn.configure(bg=BTN_HOVER))
        btn.bind("<Leave>", lambda e: btn.configure(bg=BTN_BG))
        btn.bind("<Button-1>", lambda e: cmd())
        return btn

    def snooze(minutes, label):
        """推迟N分钟后再次提醒"""
        global _snoozed, _pending_snooze_timer
        now = datetime.now()
        next_min = now.hour * 60 + now.minute + minutes
        _snoozed[task_idx] = next_min

        # 取消之前的定时器
        if _pending_snooze_timer:
            root.after_cancel(_pending_snooze_timer)
            _pending_snooze_timer = None

        popup.destroy()
        # 播放5分钟版本的语音
        threading.Thread(target=lambda: play_voice(task_idx, 'pre'), daemon=True).start()

    def dismiss():
        """离开 - 不再提醒此任务"""
        global _dismissed
        _dismissed.add(task_idx)
        popup.destroy()

    def on_time():
        """到点提醒"""
        global _snoozed
        _snoozed[task_idx] = start_min  # 设置到任务开始时间
        popup.destroy()

    # 四个按钮
    make_btn("离开", TEXT_DIM, dismiss).pack(side=tk.LEFT, padx=3)
    make_btn("5分钟后", "#74c0fc", lambda: snooze(5, "5分钟后")).pack(side=tk.LEFT, padx=3)
    make_btn("1分钟后", "#f0a040", lambda: snooze(1, "1分钟后")).pack(side=tk.LEFT, padx=3)
    make_btn("到点", GREEN, on_time).pack(side=tk.LEFT, padx=3)

    # 定位：屏幕中央偏上
    popup.update_idletasks()
    pw, ph = popup.winfo_width(), popup.winfo_height()
    sw, sh = root.winfo_screenwidth(), root.winfo_screenheight()
    popup.geometry(f"+{(sw-pw)//2}+{(sh-ph)//3}")

    # 15秒后自动snooze 5分钟
    def auto_snooze():
        global _pending_snooze_timer
        _pending_snooze_timer = None
        if popup.winfo_exists():
            _snoozed[task_idx] = (datetime.now().hour * 60 + datetime.now().minute + 5)
            popup.destroy()
            threading.Thread(target=lambda: play_voice(task_idx, 'pre'), daemon=True).start()
    _pending_snooze_timer = root.after(15000, auto_snooze)

    # 窗口关闭时取消定时器
    def on_destroy():
        global _pending_snooze_timer
        if _pending_snooze_timer:
            root.after_cancel(_pending_snooze_timer)
            _pending_snooze_timer = None
        popup.destroy()
    popup.protocol("WM_DELETE_WINDOW", on_destroy)

    # ESC关闭 = 离开
    popup.bind("<Escape>", lambda e: dismiss())

    # 播放10分钟语音
    threading.Thread(target=lambda: play_voice(task_idx, '10m'), daemon=True).start()

    # 闪烁边框
    def flash(count=0):
        if count >= 8 or not popup.winfo_exists(): return
        try: popup.configure(highlightbackground=ACCENT if count%2==0 else "#1a1b1e")
        except: return
        popup.after(350, lambda: flash(count+1))
    flash()

    return popup

# ============ 到点提醒弹窗（无snooze） ============
def show_on_time_popup(task_idx, emoji, name, timestr):
    """到点闹钟弹窗"""
    popup = tk.Toplevel(root)
    popup.overrideredirect(True)
    popup.attributes("-topmost", True)
    popup.configure(bg="#1a1b1e")
    popup.attributes("-alpha", 0.96)
    popup.configure(highlightbackground=ACCENT, highlightthickness=2, bd=0)

    inner = tk.Frame(popup, bg="#1a1b1e", padx=20, pady=16)
    inner.pack()

    tk.Label(inner, text="⏰ 时间到！开始吧",
             font=font.Font(family="Microsoft YaHei UI", size=13, weight="bold"),
             fg=ACCENT, bg="#1a1b1e").pack(pady=(0, 8))
    tk.Label(inner, text=emoji,
             font=font.Font(family="Segoe UI Emoji", size=40),
             bg="#1a1b1e").pack()
    tk.Label(inner, text=name,
             font=font.Font(family="Microsoft YaHei UI", size=15, weight="bold"),
             fg=TEXT_HI, bg="#1a1b1e").pack(pady=(4, 2))
    tk.Label(inner, text=timestr,
             font=font.Font(family="Microsoft YaHei UI", size=11),
             fg=TEXT_DIM, bg="#1a1b1e").pack()

    # 完成按钮
    btn = tk.Label(inner, text="✓ 知道了",
                   fg=GREEN, bg=BTN_BG,
                   font=font.Font(family="Microsoft YaHei UI", size=12, weight="bold"),
                   padx=20, pady=6, cursor="hand2")
    btn.bind("<Enter>", lambda e: btn.configure(bg=BTN_HOVER))
    btn.bind("<Leave>", lambda e: btn.configure(bg=BTN_BG))
    btn.bind("<Button-1>", lambda e: popup.destroy())
    btn.pack(pady=(10, 0))

    # 点击任意处关闭
    popup.bind("<Button-1>", lambda e: popup.destroy())

    # 定位
    popup.update_idletasks()
    pw, ph = popup.winfo_width(), popup.winfo_height()
    sw, sh = root.winfo_screenwidth(), root.winfo_screenheight()
    popup.geometry(f"+{(sw-pw)//2}+{(sh-ph)//3}")

    # 8秒自动关闭
    popup.after(8000, popup.destroy)
    # ESC关闭
    popup.bind("<Escape>", lambda e: popup.destroy())

    # 播放到点语音 + 闹钟音效
    threading.Thread(target=lambda: play_voice(task_idx, 'now'), daemon=True).start()

    # 闪烁
    def flash(count=0):
        if count >= 6 or not popup.winfo_exists(): return
        try: popup.configure(highlightbackground=ACCENT if count%2==0 else "#1a1b1e")
        except: return
        popup.after(300, lambda: flash(count+1))
    flash()

    return popup

# ============ 闹钟检测（新版） ============
def check_alarms(now):
    global _snoozed, _dismissed, _on_time_done

    if is_rest_day(): return

    now_min = now.hour * 60 + now.minute
    checks = load_checks()
    day_checks = checks.get(today_str(), {})

    for i, (emoji, timestr, name, _) in enumerate(SCHEDULE):
        # 已完成 → 跳过
        if day_checks.get(str(i), False): continue
        # 已离开 → 跳过
        if i in _dismissed: continue

        # 解析开始/结束时间
        sh, sm = map(int, timestr.split("-")[0].split(":"))
        eh, em = map(int, timestr.split("-")[1].split(":"))
        start_min = sh * 60 + sm
        end_min = eh * 60 + em

        # === 到点提醒（精确命中，不可推迟） ===
        if now_min == start_min:
            _on_time_done.add(i)
            show_on_time_popup(i, emoji, name, timestr)
            _snoozed.pop(i, None)
            _dismissed.discard(i)
            continue

        # === 错过开始时间但在任务时段内（刚打开程序等情况） ===
        if start_min < now_min < end_min and i not in _on_time_done:
            _on_time_done.add(i)
            show_on_time_popup(i, emoji, name, timestr)
            _snoozed.pop(i, None)
            _dismissed.discard(i)
            continue

        # === 检查snooze到期 ===
        if i in _snoozed:
            if now_min >= _snoozed[i]:
                del _snoozed[i]
                if now_min >= start_min:
                    # 到点已过 → 到点提醒
                    _on_time_done.add(i)
                    show_on_time_popup(i, emoji, name, timestr)
                    _dismissed.discard(i)
                else:
                    # 还没到点 → 再次snooze弹窗
                    show_snooze_popup(i, emoji, name, timestr, start_min)
            continue

        # === 首次提醒：提前10分钟 ===
        if now_min == start_min - 10:
            show_snooze_popup(i, emoji, name, timestr, start_min)

# ============ 右键菜单 ============
def right_menu(e):
    global _alarm_enabled
    m = tk.Menu(root, tearoff=0, bg=SURFACE, fg=TEXT,
                activebackground=ACCENT, activeforeground=BG,
                font=("Microsoft YaHei UI", 10))

    alarm_label = "🔔 提醒: ON" if _alarm_enabled else "🔕 提醒: OFF"
    def toggle_alarm():
        global _alarm_enabled
        _alarm_enabled = not _alarm_enabled

    m.add_command(label=alarm_label, command=toggle_alarm)
    m.add_command(label="🧪 测试提醒", command=lambda: show_snooze_popup(0, "🏃", "空腹有氧45min", "07:00-07:45", 420))
    m.add_separator()
    m.add_command(label="🔄 刷新", command=rebuild)
    m.add_command(label="📅 完整日历", command=open_html)
    m.add_separator()
    m.add_command(label="✕ 退出", command=root.destroy)
    m.post(e.x_root, e.y_root)

# ============ 字体 ============
F_TITLE  = font.Font(family="Microsoft YaHei UI", size=12, weight="bold")
F_DATE   = font.Font(family="Microsoft YaHei UI", size=14, weight="bold")
F_TIME   = font.Font(family="Segoe UI", size=9, weight="bold")
F_TASK   = font.Font(family="Microsoft YaHei UI", size=10)
F_DETAIL = font.Font(family="Microsoft YaHei UI", size=8)
F_EMOJI  = font.Font(family="Segoe UI Emoji", size=15)
F_SMALL  = font.Font(family="Microsoft YaHei UI", size=9)

# ============ UI ============
main = tk.Frame(root, bg=BG, padx=10, pady=8)
main.pack(fill=tk.BOTH, expand=True)
for s in ("<Button-1>", "<B1-Motion>"):
    main.bind(s, drag_start if s=="<Button-1>" else drag_move)

topbar = tk.Frame(main, bg=BG)
topbar.pack(fill=tk.X)
tk.Label(topbar, text="🔥 Gap 任务日历", font=F_TITLE, fg=TEXT_HI, bg=BG).pack(side=tk.LEFT)
clock_lbl = tk.Label(topbar, text="", font=F_SMALL, fg=TEXT_DIM, bg=BG)
clock_lbl.pack(side=tk.RIGHT)
for w in [topbar]+list(topbar.winfo_children()):
    w.bind("<Button-1>", drag_start); w.bind("<B1-Motion>", drag_move)

datebar = tk.Frame(main, bg=BG)
datebar.pack(fill=tk.X, pady=(6,2))
dt = date.today()
date_lbl = tk.Label(datebar, text=f"{dt.month}月{dt.day}日 {WEEKDAYS[dt.weekday()]}",
                    font=F_DATE, fg=TEXT_HI, bg=BG)
date_lbl.pack(side=tk.LEFT)
badge_lbl = tk.Label(datebar, text="", font=F_SMALL, padx=10, pady=2, borderwidth=0)
badge_lbl.pack(side=tk.RIGHT)

tk.Frame(main, height=1, bg=BORDER).pack(fill=tk.X, pady=(6,6))

list_frame = tk.Frame(main, bg=BG)
list_frame.pack(fill=tk.BOTH, expand=True)

canvas = tk.Canvas(list_frame, bg=BG, highlightthickness=0, bd=0)
scrollbar = tk.Scrollbar(list_frame, orient=tk.VERTICAL, command=canvas.yview,
                          bg=SURFACE, troughcolor=BG, width=6, bd=0,
                          activebackground=BORDER, highlightthickness=0)
scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
canvas.configure(yscrollcommand=scrollbar.set)

inner = tk.Frame(canvas, bg=BG)
inner_win = canvas.create_window((0,0), window=inner, anchor="nw")
inner.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
canvas.bind("<Configure>", lambda e: canvas.itemconfig(inner_win, width=e.width))

def on_mw(e):
    canvas.yview_scroll(-1*(e.delta//120), "units")
canvas.bind("<MouseWheel>", on_mw)
root.bind("<MouseWheel>", on_mw)

bottombar = tk.Frame(main, bg=BG)
bottombar.pack(fill=tk.X, pady=(8,2))
progress_lbl = tk.Label(bottombar, text="", font=F_SMALL, fg=TEXT_DIM, bg=BG)
progress_lbl.pack(side=tk.LEFT)
progress_bar = tk.Canvas(bottombar, width=130, height=5, bg=BORDER, highlightthickness=0, bd=0)
progress_bar.pack(side=tk.RIGHT, pady=(3,0))

close_btn = tk.Label(main, text="✕", font=font.Font(family="Segoe UI", size=11),
                     fg=TEXT_DIM, bg=BG, cursor="hand2")
close_btn.pack(anchor="e", pady=(4,0))
close_btn.bind("<Button-1>", lambda e: root.destroy())

# ============ 任务列表 ============
_task_rows = []
def rebuild():
    global _task_rows
    for row,*_ in _task_rows: row.destroy()
    _task_rows = []
    checks = load_checks()
    day_checks = checks.get(today_str(), {})
    now = datetime.now(); now_min = now.hour*60+now.minute
    done_count = 0; rest = is_rest_day()

    for i,(emoji,timestr,name,detail) in enumerate(SCHEDULE):
        is_done = day_checks.get(str(i), False)
        if is_done: done_count += 1

        sh,sm = map(int, timestr.split("-")[0].split(":"))
        eh,em = map(int, timestr.split("-")[1].split(":"))
        is_cur = (not rest) and (sh*60+sm <= now_min < eh*60+em)

        row_bg = SURFACE if is_cur else BG
        row = tk.Frame(inner, bg=row_bg, padx=6, pady=4, cursor="hand2")
        row.pack(fill=tk.X, pady=1)
        if is_cur:
            tk.Frame(row, bg=ACCENT, width=3).pack(side=tk.LEFT, fill=tk.Y, padx=(0,6))
        tk.Label(row, text=emoji, font=F_EMOJI, bg=row_bg).pack(side=tk.LEFT, padx=(0,8))

        txt = tk.Frame(row, bg=row_bg); txt.pack(side=tk.LEFT, fill=tk.X, expand=True)
        alarm_mark = " 🔔" if (not rest and not is_done) else ""
        tk.Label(txt, text=timestr+alarm_mark, font=F_TIME, fg=ACCENT, bg=row_bg, anchor="w").pack(anchor="w")

        nc = TEXT_DIM if is_done else TEXT_HI
        nd = f"✓ {name}" if is_done else name
        tk.Label(txt, text=nd, font=F_TASK, fg=nc, bg=row_bg, anchor="w").pack(anchor="w")
        tk.Label(txt, text=detail, font=F_DETAIL, fg=TEXT_DIM, bg=row_bg, anchor="w").pack(anchor="w")

        cc = "●" if is_done else "○"
        clr = GREEN if is_done else BORDER
        cl = tk.Label(row, text=cc, font=font.Font(family="Segoe UI", size=12),
                      fg=clr, bg=row_bg, cursor="hand2", padx=4)
        cl.pack(side=tk.RIGHT)
        def cb(idx):
            return lambda e: toggle(idx)
        c = cb(i); cl.bind("<Button-1>", c); row.bind("<Button-1>", c)
        _task_rows.append((row,cl,name))

    pct = done_count/len(SCHEDULE)
    progress_bar.delete("pbar")
    progress_bar.create_rectangle(0,0,130*pct,5,fill=ACCENT,outline="",tags="pbar")
    progress_lbl.config(text=f"今日进度 {done_count}/{len(SCHEDULE)}")
    badge_lbl.config(text="🌴 休息日" if rest else "🔥 训练日",
                     bg=GREEN if rest else ACCENT, fg=BG)

def toggle(idx):
    checks = load_checks(); key = today_str()
    checks.setdefault(key, {})
    checks[key][str(idx)] = not checks[key].get(str(idx), False)
    save_checks(checks)
    if checks[key][str(idx)]:
        # 勾选完成 → 清理提醒状态
        _snoozed.pop(idx, None)
        _dismissed.add(idx)
        _on_time_done.add(idx)
    else:
        # 取消勾选 → 恢复提醒
        _dismissed.discard(idx)
        _on_time_done.discard(idx)
        _snoozed.pop(idx, None)
    rebuild()

# ============ 定时器 ============
_last_check_min = -1
def tick():
    global _last_check_min, _last_date, _snoozed, _dismissed, _on_time_done
    now = datetime.now()
    clock_lbl.config(text=now.strftime("%H:%M:%S"))

    # 跨天重置
    t = date.today()
    if t != _last_date:
        _last_date = t; _snoozed = {}; _dismissed = set(); _on_time_done = set(); rebuild()

    if now.minute != _last_check_min:
        _last_check_min = now.minute
        if _alarm_enabled:
            check_alarms(now)
        rebuild()

    root.after(1000, tick)

# ============ 快捷键 & 启动 ============
root.bind("<Button-3>", right_menu)
root.bind("<Escape>", lambda e: root.destroy())

root.update_idletasks()
sw = root.winfo_screenwidth(); sh = root.winfo_screenheight()
ww, wh = 340, 530
root.geometry(f"{ww}x{wh}+{sw-ww-25}+{sh-wh-70}")

rebuild()
tick()
root.mainloop()
