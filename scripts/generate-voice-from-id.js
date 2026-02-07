#!/usr/bin/env node
/**
 * Generate voice clips using existing ElevenLabs voice
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const ELEVENLABS_API_KEY = 'sk_87ed21af3575a56cffebd2826f4a79eb2a7b09418d8e8c90';
const VOICE_ID = '8vBME1id08shCqlhBh9l';
const OUTPUT_DIR = path.join(__dirname, '..', 'audio', 'voice');

const phrases = {
    // Standard announcements
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
    // Fun and cheeky
    'cheeky-1': 'Come on, you can do better than that',
    'cheeky-2': 'Are we working or are we scrolling?',
    'cheeky-3': 'That phone isn\'t going to check itself... oh wait',
    'cheeky-4': 'I see you. Yes, you. Get back to work',
    'cheeky-5': 'Procrastination is just productivity... for later',
    'fun-halfway': 'Halfway there! Living on a prayer',
    'fun-almost': 'Sooo close. Don\'t you dare stop now',
    'fun-complete': 'Boom! You absolute legend',
    'fun-start': 'Let\'s goooo. Time to crush it',
    'fun-break': 'Break time! Go touch some grass',
    'motivate-1': 'You\'re basically a productivity ninja right now',
    'motivate-2': 'Future you is going to be so proud',
    'motivate-3': 'This is your moment. Own it',
    'sassy-1': 'Oh, we\'re pausing? How very interesting',
    'sassy-2': 'Taking a break? Bold move, Chris. Bold move',
    'sassy-3': 'Back already? I knew you couldn\'t resist',
};

// Ensure output directory exists
if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

async function generateClip(clipId, text) {
    const outputPath = path.join(OUTPUT_DIR, `${clipId}.mp3`);

    console.log(`Generating: ${clipId} - "${text}"`);

    return new Promise((resolve, reject) => {
        const data = JSON.stringify({
            text: text,
            model_id: 'eleven_monolingual_v1',
            voice_settings: {
                stability: 0.5,
                similarity_boost: 0.75
            }
        });

        const options = {
            hostname: 'api.elevenlabs.io',
            path: `/v1/text-to-speech/${VOICE_ID}`,
            method: 'POST',
            headers: {
                'xi-api-key': ELEVENLABS_API_KEY,
                'Content-Type': 'application/json',
                'Accept': 'audio/mpeg',
                'Content-Length': Buffer.byteLength(data)
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
                console.log(`  ✓ Created: ${clipId}.mp3`);
                resolve();
            });
        });

        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

async function main() {
    console.log('\n🎙️  Generating voice clips with your ElevenLabs voice');
    console.log(`Voice ID: ${VOICE_ID}`);
    console.log(`Output: ${OUTPUT_DIR}\n`);

    // Clear old clips
    const oldFiles = fs.readdirSync(OUTPUT_DIR).filter(f => f.endsWith('.mp3'));
    if (oldFiles.length > 0) {
        console.log(`Removing ${oldFiles.length} old clips...\n`);
        oldFiles.forEach(f => fs.unlinkSync(path.join(OUTPUT_DIR, f)));
    }

    const ids = Object.keys(phrases);
    let completed = 0;
    let errors = 0;

    for (const id of ids) {
        try {
            await generateClip(id, phrases[id]);
            completed++;
            // Small delay to respect rate limits
            await new Promise(r => setTimeout(r, 300));
        } catch (err) {
            console.error(`  ✗ Error: ${err.message}`);
            errors++;
        }
    }

    console.log(`\n✅ Done! Generated ${completed} clips, ${errors} errors\n`);
}

main().catch(console.error);
