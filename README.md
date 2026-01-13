# ActiveTomato

A high-definition e-ink styled Pomodoro timer with batch sessions, smart reminders, and gamification.

## Features

### Timer Modes
- **25-minute focus sessions** (Pomodoro)
- **5-minute short breaks**
- **15-minute long breaks** (after 4 pomodoros)
- Visual progress bar
- Batch mode: plan 1-6 pomodoros in sequence

### Audio Cues
| Toggle | Function |
|--------|----------|
| **Completion Sound** | Melody when timer ends + warning beeps in last 30 sec |
| **Progress Beeps** | Beeps every 5 min (1 beep at 5min, 2 at 10min, etc.) |
| **Countdown Tick** | Audible tick on every second |

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

## Tech Stack
- React 18 (CDN)
- Supabase (Auth + Database)
- Web Audio API (sounds)
- CSS3 (responsive e-ink design)

## Setup

### Supabase Configuration

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

## Deploy to Netlify

1. Push to GitHub (already done)
2. Connect repo to Netlify
3. Deploy settings:
   - Build command: (leave empty)
   - Publish directory: `.`

## Environment Variables

For production, set these in Netlify:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

## Database Schema

See `supabase/schema.sql` for complete schema including:
- User profiles
- Settings/preferences
- Pomodoro sessions
- Daily activity
- Activity log

All tables have Row Level Security (RLS) enabled.

## License
MIT
