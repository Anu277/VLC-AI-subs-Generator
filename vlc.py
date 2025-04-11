import os
import time
import psutil
import subprocess
from datetime import timedelta
from pathlib import Path
import whisper
import sys
from winotify import Notification, audio


os.environ["PATH"] += os.pathsep + r"C:\ffmpeg\bin"  # <-- Replace with your actual path

if getattr(sys, 'frozen', False):
    base_path = sys._MEIPASS
else:
    base_path = os.path.dirname(os.path.abspath(__file__))

whisper.audio.MEL_FILTERS_PATH = os.path.join(base_path, "whisper", "assets", "mel_filters.npz")
whisper.utils._MODELS_DIR = os.path.join(base_path, "whisper")  # Where base.pt will be

# Debug: Verify paths and file existence
print(f"Base path: {base_path}")
print(f"Patched MEL_FILTERS_PATH: {whisper.audio.MEL_FILTERS_PATH}")
print(f"Patched MODELS_DIR: {whisper.utils._MODELS_DIR}")
if os.path.exists(whisper.audio.MEL_FILTERS_PATH):
    print("✅ mel_filters.npz found!")
else:
    print("❌ mel_filters.npz not found!")
if os.path.exists(os.path.join(whisper.utils._MODELS_DIR, "base.pt")):
    print("✅ base.pt found!")
else:
    print("❌ base.pt not found!")

# Rest of your code...
model = whisper.load_model("base")
processed = set()

def find_vlc_media_file():
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        if proc.info['name'] and 'vlc.exe' in proc.info['name'].lower():
            for arg in proc.info['cmdline']:
                if arg.lower().endswith(('.mp4', '.mkv', '.avi', '.mov')):
                    return arg
    return None

def extract_audio(video_path, audio_path):
    command = [
        "ffmpeg", "-i", video_path,
        "-vn", "-ac", "1", "-ar", "16000", "-b:a", "128k", "-y",
        audio_path
    ]
    try:
        subprocess.run(command, check=True)
        print(f"✅ Compressed audio extracted: {audio_path}")
        return audio_path
    except subprocess.CalledProcessError as e:
        print("❌ Error extracting audio:", e)
        return None

def generate_subtitles_streaming(audio_path, srt_path):
    print("🧠 Starting transcription (auto-translating to English)...")
    result = model.transcribe(audio_path, task="translate", verbose=False)

    with open(srt_path, "w", encoding="utf-8") as srt_file:
        for i, segment in enumerate(result["segments"], start=1):
            start = format_srt_time(segment["start"])
            end = format_srt_time(segment["end"])
            text = segment["text"].strip()
            srt_file.write(f"{i}\n{start} --> {end}\n{text}\n\n")

    print(f"✅ Subtitles saved: {srt_file.name}")

def format_srt_time(seconds):
    td = timedelta(seconds=seconds)
    total_seconds = int(td.total_seconds())
    hours, remainder = divmod(total_seconds, 3600)
    minutes, secs = divmod(remainder, 60)
    milliseconds = int((td.total_seconds() - total_seconds) * 1000)
    return f"{hours:02}:{minutes:02}:{secs:02},{milliseconds:03}"

print("🚀 Watching VLC media sessions...")

while True:
    media_file = find_vlc_media_file()
    if media_file and media_file not in processed:
        print(f"\n🎬 New VLC media detected: {media_file}")
        base_path = Path(media_file).with_suffix('')
        audio_file = str(base_path) + ".mp3"
        srt_file = str(base_path) + ".srt"

        if not os.path.exists(srt_file):
            audio_path = extract_audio(media_file, audio_file)
            if audio_path:
                generate_subtitles_streaming(audio_path, srt_file)

                if os.path.exists(audio_file):
                    os.remove(audio_file)
                    print(f"🧹 Deleted temporary audio file: {audio_file}")
                    toast = Notification(app_id="ZestSync Helper",  # Custom app name!
                     title="Subtitles Loaded",
                     msg="Subs generated! To enable --In VLC Player Go to [View] > [ZestSync Loader], press 'V' on Keybaord",
                     duration="short")
                    toast.set_audio(audio.Default, loop=False)
                    toast.show()
            else:
                print("⚠️ Skipping subtitle generation due to audio extraction error.")
        else:
            print("🟡 Subtitle already exists, skipping generation.")

        processed.add(media_file)

    time.sleep(5)