#!/usr/bin/env node
/**
 * Generate voice clips for ActiveTomato using ElevenLabs voice cloning
 * Uses the assistant_voice_only.wav sample from the Speech project
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

// ElevenLabs API key (with full access)
const ELEVENLABS_API_KEY = 'sk_87ed21af3575a56cffebd2826f4a79eb2a7b09418d8e8c90';

const VOICE_SAMPLE = '/Users/chris/Documents/Code/ActiveTomato/voice_sample.wav';
const OUTPUT_DIR = path.join(__dirname, '..', 'audio', 'voice');

// All voice phrases for the timer
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

function httpsRequest(options, data) {
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            const chunks = [];
            res.on('data', chunk => chunks.push(chunk));
            res.on('end', () => {
                const body = Buffer.concat(chunks);
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve({ status: res.statusCode, body, headers: res.headers });
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${body.toString()}`));
                }
            });
        });
        req.on('error', reject);
        if (data) req.write(data);
        req.end();
    });
}

async function createVoiceClone() {
    console.log('Creating voice clone from assistant_voice_only.wav...');

    const boundary = '----FormBoundary' + Math.random().toString(36).substr(2);
    const voiceData = fs.readFileSync(VOICE_SAMPLE);

    let body = '';
    body += `--${boundary}\r\n`;
    body += `Content-Disposition: form-data; name="name"\r\n\r\n`;
    body += `ActiveTomato Assistant\r\n`;
    body += `--${boundary}\r\n`;
    body += `Content-Disposition: form-data; name="description"\r\n\r\n`;
    body += `Voice for ActiveTomato timer\r\n`;
    body += `--${boundary}\r\n`;
    body += `Content-Disposition: form-data; name="files"; filename="assistant_voice_only.wav"\r\n`;
    body += `Content-Type: audio/wav\r\n\r\n`;

    const bodyStart = Buffer.from(body, 'utf8');
    const bodyEnd = Buffer.from(`\r\n--${boundary}--\r\n`, 'utf8');
    const fullBody = Buffer.concat([bodyStart, voiceData, bodyEnd]);

    const options = {
        hostname: 'api.elevenlabs.io',
        path: '/v1/voices/add',
        method: 'POST',
        headers: {
            'xi-api-key': ELEVENLABS_API_KEY,
            'Content-Type': `multipart/form-data; boundary=${boundary}`,
            'Content-Length': fullBody.length
        }
    };

    const response = await httpsRequest(options, fullBody);
    const result = JSON.parse(response.body.toString());
    console.log(`Voice clone created: ${result.voice_id}`);
    return result.voice_id;
}

async function generateClip(voiceId, clipId, text) {
    const outputPath = path.join(OUTPUT_DIR, `${clipId}.mp3`);

    console.log(`Generating: ${clipId} - "${text}"`);

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
        path: `/v1/text-to-speech/${voiceId}`,
        method: 'POST',
        headers: {
            'xi-api-key': ELEVENLABS_API_KEY,
            'Content-Type': 'application/json',
            'Accept': 'audio/mpeg',
            'Content-Length': Buffer.byteLength(data)
        }
    };

    const response = await httpsRequest(options, data);
    fs.writeFileSync(outputPath, response.body);
    console.log(`  Created: ${outputPath}`);
}

async function deleteVoice(voiceId) {
    console.log(`\nCleaning up voice clone...`);

    const options = {
        hostname: 'api.elevenlabs.io',
        path: `/v1/voices/${voiceId}`,
        method: 'DELETE',
        headers: {
            'xi-api-key': ELEVENLABS_API_KEY
        }
    };

    try {
        await httpsRequest(options);
        console.log('Voice clone deleted');
    } catch (e) {
        console.log('Note: Could not delete voice clone, you may need to remove it manually');
    }
}

async function main() {
    console.log('\nGenerating voice clips using ElevenLabs voice cloning');
    console.log(`Voice sample: ${VOICE_SAMPLE}`);
    console.log(`Output: ${OUTPUT_DIR}\n`);

    // First, delete old clips
    console.log('Removing old voice clips...');
    const existingFiles = fs.readdirSync(OUTPUT_DIR).filter(f => f.endsWith('.mp3'));
    existingFiles.forEach(f => fs.unlinkSync(path.join(OUTPUT_DIR, f)));
    console.log(`Removed ${existingFiles.length} old clips\n`);

    // Create voice clone
    let voiceId;
    try {
        voiceId = await createVoiceClone();
    } catch (err) {
        console.error('Failed to create voice clone:', err.message);
        process.exit(1);
    }

    // Generate all clips
    const ids = Object.keys(phrases);
    let completed = 0;
    let errors = 0;

    for (const id of ids) {
        try {
            await generateClip(voiceId, id, phrases[id]);
            completed++;
            // Delay to respect rate limits
            await new Promise(r => setTimeout(r, 500));
        } catch (err) {
            console.error(`  Error generating ${id}: ${err.message}`);
            errors++;
        }
    }

    // Clean up - delete the cloned voice
    await deleteVoice(voiceId);

    console.log(`\nDone! Generated ${completed} clips, ${errors} errors`);
}

main().catch(console.error);
