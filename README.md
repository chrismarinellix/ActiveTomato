# ActiveTomato

A retro e-ink styled Pomodoro timer with gamification and activity tracking.

## Features

### Timer
- **25-minute focus sessions** (Pomodoro)
- **5-minute short breaks**
- **15-minute long breaks** (after 4 pomodoros)
- Visual progress bar
- Session dots showing progress toward long break

### Sound System
Three toggleable sound modes:

| Toggle | Function |
|--------|----------|
| **End Alert** | Plays completion melody when timer ends, warning beeps in last 30 seconds |
| **5m Beeps** | Interval beeps every 5 minutes (1 beep at 5min, 2 at 10min, 3 at 15min, etc.) |
| **Tick** | Audible tick sound every second |

All sounds are generated using the Web Audio API - no external files needed.

### Gamification
- **Points**: Earn 25 points per completed pomodoro
- **Levels**: Progress through ranks as you accumulate points
  - Seedling (0-99 pts)
  - Sprout (100-299 pts)
  - Sapling (300-599 pts)
  - Tree (600-999 pts)
  - Grove (1000-1999 pts)
  - Forest (2000+ pts)
- **Today Counter**: Track daily pomodoro completions

### Activity Tracking
- **GitHub-style contribution grid** showing the last 52 weeks
- **Daily log** of timer sessions with timestamps
- All data persisted in localStorage

## Tech Stack
- HTML5
- React 18 (via CDN)
- CSS3 with responsive design
- Web Audio API for sounds
- localStorage for persistence

## Usage

Simply open `index.html` in a web browser. No build process required.

```bash
open index.html
```

Or serve locally:
```bash
npx serve .
```

## Mobile Support
Fully responsive design works on all screen sizes from desktop to mobile.

## Data Storage
All data is stored in localStorage under these keys:
- `activeTomatoPoints` - Total points
- `activeTomatoToday` - Today's pomodoro count
- `activeTomatoActivity` - Activity grid data
- `activeTomatoLog` - Today's session log
- `activeTomatoStreak` - Current streak

## License
MIT
