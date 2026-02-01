# ActiveTomato

A high-definition Pomodoro timer with voice cues, ambient sounds, and a native desktop widget. Built with React, Tauri 2, and Web Audio API.

## Features

### Timer Modes
- **25-minute focus sessions** (Pomodoro)
- **5-minute short breaks**
- **15-minute long breaks** (after 4 pomodoros)
- Visual progress bar
- Batch mode: plan 1-6 pomodoros in sequence

### Voice Cues (NEW)
Synthetic voice announcements to keep you informed without looking at the app:
- **Time remaining**: Announcements at 20, 15, 10, 5, 2, 1 minute marks
- **Final countdown**: 30 seconds, 10 seconds
- **Milestones**: "5 minutes of focus completed", "10 minutes in"
- **Session complete**: Personalized completion messages with points earned
- **Start/Pause**: Voice confirmation when toggling timer

### Audio Cues
| Toggle | Function |
|--------|----------|
| **Completion Sound** | Melody when timer ends + warning beeps in last 30 sec |
| **Progress Beeps** | Beeps every 1 or 5 min (1 beep at first interval, 2 at second, etc.) |
| **Countdown Tick** | Audible tick every second (soft/click/pulse/woodblock styles) |
| **Voice Cues** | Spoken time announcements and session feedback |

### Ambient Sounds
Background soundscapes to enhance focus:
- **Focus**: Deep drone ambience
- **Rain**: Brown noise rain-like sound
- **Space**: Ethereal sweeping tones
- Volume slider control

### Desktop App (Tauri 2)
Native desktop widget with three view modes:
- **Full Mode**: Complete interface with all controls
- **Widget Mode**: Compact floating timer (300x400)
- **Mini Mode**: Ultra-compact timer only (220x90)

Features:
- Frameless, transparent windows
- Always-on-top option
- System tray icon with menu
- Custom traffic light controls
- Drag anywhere to reposition

### Nudge Me (Reminders)
| Toggle | Function |
|--------|----------|
| **Remind to Focus** | Ping when timer is idle (5/10/15/30/60 min intervals) |
| **Auto-Start** | Automatically start timer when reminder fires |

### Batch Mode
| Toggle | Function |
|--------|----------|
| **Chain Sessions** | Auto-start next pomodoro after break in a series |

### Gamification
- **Points**: 25 pts per completed pomodoro
- **Levels**: Seedling → Sprout → Sapling → Tree → Grove → Forest
- **Activity Grid**: GitHub-style yearly contribution tracker
- **Daily Log**: Session timestamps

### Cross-Device Sync
- Real-time timer sync across devices via Supabase
- Session history and stats stored in cloud
- Works offline with local storage fallback

## Tech Stack
- **Frontend**: React 18 (CDN)
- **Desktop**: Tauri 2 (Rust)
- **Backend**: Supabase (Auth + Database + Realtime)
- **Audio**: Web Audio API (sounds), Web Speech API (voice)
- **Graphics**: WebGPU/WebGL (particle effects)
- **Design**: CSS3 (glassmorphism, responsive e-ink style)

## Running the Desktop App

### Development
```bash
npm install
npm run dev
```

### Build for Production
```bash
# macOS
npm run build

# Windows
npm run build -- --target x86_64-pc-windows-msvc

# Linux
npm run build -- --target x86_64-unknown-linux-gnu
```

### Tray Icon
- **Left-click**: Cycle through view modes (Full → Widget → Mini)
- **Right-click**: Menu (Show Full View, Widget Mode, Mini Mode, Hide, Quit)

## Supabase Setup

1. Create a Supabase project at [supabase.com](https://supabase.com)

2. Run the schema in your SQL editor:
```bash
# Copy contents of supabase/schema.sql to Supabase SQL Editor
```

3. Update credentials in `index.html`:
```javascript
const SUPABASE_URL = 'https://your-project.supabase.co';
const SUPABASE_ANON_KEY = 'your-anon-key';
```

4. Enable Email Auth in Supabase Dashboard:
   - Authentication → Providers → Email

### Authentication
- **Email/Password**: Enter email and password - new users are automatically registered
- **Passkey**: Use WebAuthn passkeys for passwordless login (browser support required)

## Deploy to Netlify (Web Version)

1. Push to GitHub
2. Connect repo to Netlify
3. Deploy settings:
   - Build command: (leave empty)
   - Publish directory: `.`

## Project Structure
```
ActiveTomato/
├── index.html          # Main app (React + CSS + JS)
├── package.json        # npm dependencies
├── src-tauri/          # Tauri desktop app
│   ├── Cargo.toml      # Rust dependencies
│   ├── tauri.conf.json # Tauri configuration
│   ├── src/main.rs     # Rust backend (window management, tray)
│   └── icons/          # App icons
├── supabase/
│   └── schema.sql      # Database schema
└── README.md
```

## License
MIT
