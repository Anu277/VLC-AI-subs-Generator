# ZestSync - AI-Powered Subtitles for VLC

ZestSync generates real-time AI subtitles for VLC Media Player using OpenAI Whisper. This tool runs in the background, automatically creating `.srt` subtitle files when you open a video in VLC, with notifications for seamless integration.

**Website**: [ZestSync](https://zestsync.netlify.app) 

## Features
- Real-time subtitle generation for VLC.
- Powered by OpenAI Whisper for accurate transcription.
- Lightweight, offline-capable background process.
- Easy setup with VLC integration.
- Windows-only support.

## How I Made the AI Subtitles

I built ZestSync to bring AI-powered subtitles to VLC without manual effort. Here’s the process and commands I used:

### Development Process
1. **Concept**: I wanted subtitles to generate automatically for any video played in VLC, using AI transcription for accuracy across languages.
2. **Tech Stack**:
   - **Python**: For the core subtitle generation logic.
   - **OpenAI Whisper**: For real-time audio transcription.
   - **MoviePy**: To extract audio from video files.
   - **Psutil**: To monitor VLC processes.
   - **Winotify**: For Windows notifications.
   - **VLC Extension (ZSLoader)**: To integrate subtitles seamlessly.
3. **Workflow**:
   - Detect when VLC opens a video using `psutil`.
   - Extract audio with `moviepy`.
   - Transcribe audio to text with `openai-whisper`.
   - Convert text to `.srt` format.
   - Notify the user via `winotify` when subtitles are ready.
   - Load subtitles in VLC via the ZSLoader extension.

### Commands Used
To set up the environment and dependencies, I ran:

```bash
pip install moviepy==1.0.3
pip install psutil
pip install openai-whisper
pip install winotify
