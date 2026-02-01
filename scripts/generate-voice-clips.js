#!/usr/bin/env node
/**
 * Generate voice clips for ActiveTomato using OpenAI TTS
 *
 * Uses API key from /Users/chris/Documents/Code/Speech/tokens/.env
 *
 * Voices available: alloy, echo, fable, onyx, nova, shimmer
 * - nova and shimmer are more feminine/warm
 * - onyx is deeper/masculine
 * - alloy is neutral
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

// Load API key from Speech project tokens
const envPath = '/Users/chris/Documents/Code/Speech/tokens/.env';
let OPENAI_API_KEY = process.env.OPENAI_API_KEY;

if (!OPENAI_API_KEY && fs.existsSync(envPath)) {
    const envContent = fs.readFileSync(envPath, 'utf8');
    const match = envContent.match(/OPENAI_API_KEY=([^\n]+)/);
    if (match) {
        OPENAI_API_KEY = match[1].trim();
    }
}

if (!OPENAI_API_KEY) {
    console.error('Error: Could not find OPENAI_API_KEY');
    process.exit(1);
}

// Voice options: alloy, echo, fable, onyx, nova, shimmer
// "shimmer" has a warm, alluring quality
const VOICE = 'shimmer';
const MODEL = 'tts-1-hd'; // Higher quality

const OUTPUT_DIR = path.join(__dirname, '..', 'audio', 'voice');

// All voice phrases for the timer
const phrases = {
    // Time remaining announcements
    'time-20min': 'Twenty minutes remaining',
    'time-15min': 'Fifteen minutes remaining',
    'time-10min': 'Ten minutes remaining',
    'time-5min': 'Five minutes remaining',
    'time-2min': 'Two minutes remaining',
    'time-1min': 'One minute remaining',
    'time-30sec': 'Thirty seconds',
    'time-10sec': 'Ten seconds',

    // Elapsed time milestones
    'elapsed-5min': 'Five minutes of focus completed',
    'elapsed-10min': 'Ten minutes in, you\'re doing great',
    'elapsed-15min': 'Fifteen minutes of solid focus',
    'elapsed-20min': 'Twenty minutes, almost there',

    // Session complete
    'complete-focus': 'Focus session complete. Well done, Chris',
    'complete-short-break': 'Break\'s over. Ready to focus again?',
    'complete-long-break': 'Long break finished. Let\'s get back to it',

    // Start announcements
    'start-focus': 'Starting focus session. You\'ve got this',
    'start-short-break': 'Time for a short break. Relax',
    'start-long-break': 'You\'ve earned a long break. Enjoy',

    // Pause/resume
    'pause': 'Timer paused',
    'resume': 'Resuming',

    // Points/gamification
    'points-25': 'Twenty-five points earned',
    'points-50': 'Fifty points! Nice work',
    'points-100': 'One hundred points! You\'re on fire',

    // Encouragement
    'encourage-1': 'Stay focused, you\'re doing amazing',
    'encourage-2': 'Keep going, you\'ve got this',
    'encourage-3': 'Deep breath. You\'re crushing it',

    // Nudge reminders
    'nudge': 'Hey Chris, ready to start focusing?',
    'nudge-gentle': 'Just checking in. Want to start a session?',
};

// Ensure output directory exists
if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

async function generateClip(id, text) {
    const outputPath = path.join(OUTPUT_DIR, `${id}.mp3`);

    // Skip if already exists
    if (fs.existsSync(outputPath)) {
        console.log(`Skipping ${id} (already exists)`);
        return;
    }

    console.log(`Generating: ${id} - "${text}"`);

    return new Promise((resolve, reject) => {
        const data = JSON.stringify({
            model: MODEL,
            input: text,
            voice: VOICE,
            response_format: 'mp3'
        });

        const options = {
            hostname: 'api.openai.com',
            path: '/v1/audio/speech',
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${OPENAI_API_KEY}`,
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
        };

        const req = https.request(options, (res) => {
            if (res.statusCode !== 200) {
                let error = '';
                res.on('data', d => error += d);
                res.on('end', () => {
                    reject(new Error(`API error ${res.statusCode}: ${error}`));
                });
                return;
            }

            const chunks = [];
            res.on('data', chunk => chunks.push(chunk));
            res.on('end', () => {
                const buffer = Buffer.concat(chunks);
                fs.writeFileSync(outputPath, buffer);
                console.log(`  Created: ${outputPath}`);
                resolve();
            });
        });

        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

async function main() {
    console.log(`\nGenerating voice clips using OpenAI TTS`);
    console.log(`Voice: ${VOICE}, Model: ${MODEL}`);
    console.log(`Output: ${OUTPUT_DIR}\n`);

    const ids = Object.keys(phrases);
    let completed = 0;
    let errors = 0;

    for (const id of ids) {
        try {
            await generateClip(id, phrases[id]);
            completed++;
            // Small delay to avoid rate limits
            await new Promise(r => setTimeout(r, 200));
        } catch (err) {
            console.error(`  Error generating ${id}: ${err.message}`);
            errors++;
        }
    }

    console.log(`\nDone! Generated ${completed} clips, ${errors} errors`);
    console.log(`\nAdd these to your app by updating the voiceCueSystem in index.html`);
}

main().catch(console.error);
