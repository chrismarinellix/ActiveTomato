#!/usr/bin/env node
/**
 * Generate voice clips using Microsoft Edge TTS (free, high quality)
 *
 * Run: node scripts/generate-voice-edge.js
 * Or for a specific voice: VOICE=en-US-AriaNeural node scripts/generate-voice-edge.js
 *
 * Good female voices:
 * - en-US-AriaNeural (warm, natural)
 * - en-US-JennyNeural (clear, friendly)
 * - en-GB-SoniaNeural (British, sophisticated)
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Voice options - Aria is warm and natural
const VOICE = process.env.VOICE || 'en-US-AriaNeural';
const OUTPUT_DIR = path.join(__dirname, '..', 'audio', 'voice');
const VENV_PYTHON = path.join(__dirname, '..', '.venv', 'bin', 'python3');

const phrases = {
    'time-20min': 'Twenty minutes remaining',
    'time-15min': 'Fifteen minutes remaining',
    'time-10min': 'Ten minutes remaining',
    'time-5min': 'Five minutes remaining',
    'time-2min': 'Two minutes remaining',
    'time-1min': 'One minute remaining',
    'time-30sec': 'Thirty seconds',
    'time-10sec': 'Ten seconds',
    'elapsed-5min': 'Five minutes of focus completed',
    'elapsed-10min': 'Ten minutes in, you\'re doing great',
    'elapsed-15min': 'Fifteen minutes of solid focus',
    'elapsed-20min': 'Twenty minutes, almost there',
    'complete-focus': 'Focus session complete. Well done, Chris',
    'complete-short-break': 'Break\'s over. Ready to focus again?',
    'complete-long-break': 'Long break finished. Let\'s get back to it',
    'start-focus': 'Starting focus session. You\'ve got this',
    'start-short-break': 'Time for a short break. Relax',
    'start-long-break': 'You\'ve earned a long break. Enjoy',
    'pause': 'Timer paused',
    'resume': 'Resuming',
    'points-25': 'Twenty-five points earned',
    'points-50': 'Fifty points! Nice work',
    'points-100': 'One hundred points! You\'re on fire',
    'encourage-1': 'Stay focused, you\'re doing amazing',
    'encourage-2': 'Keep going, you\'ve got this',
    'encourage-3': 'Deep breath. You\'re crushing it',
    'nudge': 'Hey Chris, ready to start focusing?',
    'nudge-gentle': 'Just checking in. Want to start a session?',
};

// Ensure output directory exists
if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

console.log(`\nGenerating voice clips using Edge TTS`);
console.log(`Voice: ${VOICE}`);
console.log(`Output: ${OUTPUT_DIR}\n`);

// Clear old clips
const oldFiles = fs.readdirSync(OUTPUT_DIR).filter(f => f.endsWith('.mp3'));
if (oldFiles.length > 0) {
    console.log(`Removing ${oldFiles.length} old clips...`);
    oldFiles.forEach(f => fs.unlinkSync(path.join(OUTPUT_DIR, f)));
}

let completed = 0;
let errors = 0;

for (const [id, text] of Object.entries(phrases)) {
    const outputPath = path.join(OUTPUT_DIR, `${id}.mp3`);
    console.log(`Generating: ${id} - "${text}"`);

    try {
        // Use edge-tts via the venv Python
        const cmd = `${VENV_PYTHON} -m edge_tts --voice "${VOICE}" --text "${text}" --write-media "${outputPath}"`;
        execSync(cmd, { stdio: 'pipe' });
        console.log(`  Created: ${outputPath}`);
        completed++;
    } catch (err) {
        console.error(`  Error: ${err.message}`);
        errors++;
    }
}

console.log(`\nDone! Generated ${completed} clips, ${errors} errors`);
