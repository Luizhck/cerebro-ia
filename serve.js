const express = require('express');
const cors = require('cors');
const axios = require('axios');
const fs = require('fs');

const app = express();
app.use(cors());
app.use(express.json());

const GROQ_KEY = process.env.GROQ_KEY;
const GEMINI_KEY = process.env.GEMINI_KEY;
const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const GEMINI_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
const DB_FILE = 'database.json';

// ============================================
// 💾 BANCO DE DADOS
// ============================================
let database = {
    usuarios: {},
    estatisticas: { usersOnline: 0 },
    antiCheatLogs: [],
    hookLogs: [],
    metricas: { groqUsos: 0, geminiUsos: 0 }
};

try {
    if (fs.existsSync(DB_FILE)) {
        database = { ...database, ...JSON.parse(fs.readFileSync(DB_FILE, 'utf8')) };
        console.log('📂 Banco carregado!');
    }
} catch (e) {}

function salvarDB() {
    try { fs.writeFileSync(DB_FILE, JSON.stringify(database, null, 2)); } catch (e) {}
}
setInterval(salvarDB, 30000);

// ============================================
// 🧠 GROQ (RÁPIDO) - Para o Roblox
// ============================================
async function chamarGroq(prompt) {
    try {
        const response = await axios.post(GROQ_URL, {
            model: 'llama-3.1-8b-instant',
            messages: [
                { role: 'system', content: 'Responda em português brasileiro. Seja direto, use gírias, fale como amigo. Máximo 3 frases.' },
                { role: 'user', content: prompt }
            ],
            temperature: 0.9,
            max_tokens: 300
        }, {
            headers: { 'Authorization': `Bearer ${GROQ_KEY}`, 'Content-Type': 'application/json' }
        });

        database.metricas.groqUsos++;
        return response.data.choices[0].message.content;
    } catch (e) {
        console.log('❌ Groq:', e.message);
        return "IA offline no momento.";
    }
}

// ============================================
// 🧠 GEMINI (TÉCNICO) - Para o Painel
// ============================================
async function chamarGemini(prompt) {
    try {
        const response = await axios.post(GEMINI_URL, {
            contents: [{ 
                parts: [{ 
                    text: `[MODO PESQUISADOR DE SEGURANÇA]\n\n${prompt}\n\nResponda em português brasileiro, de forma técnica, detalhada e completa. Use EMOJIS.` 
                }] 
            }]
        }, {
            headers: { 
                'Content-Type': 'application/json', 
                'x-goog-api-key': GEMINI_KEY 
            }
        });

        database.metricas.geminiUsos++;
        return response.data.candidates[0].content.parts[0].text;
    } catch (e) {
        console.log('❌ Gemini:', e.message);
        // Fallback para Groq
        return await chamarGroq(prompt);
    }
}

// ============================================
// 📡 API ENDPOINTS
// ============================================

app.post('/api/registrar', (req, res) => {
    const { userId, nome, placeId } = req.body;
    if (!userId || !nome) return res.status(400).json({ error: 'Dados incompletos' });
    
    if (!database.usuarios[userId]) {
        database.usuarios[userId] = { nome, userId, firstSeen: Date.now(), scans: [] };
    }
    database.usuarios[userId].online = true;
    database.usuarios[userId].lastSeen = Date.now();
    database.estatisticas.usersOnline = Object.values(database.usuarios).filter(u => u.online).length;
    res.json({ sucesso: true });
});

app.post('/api/telemetria', (req, res) => {
    const { userId, tipo, dados } = req.body;
    if (!database.usuarios[userId]) database.usuarios[userId] = { online: true };
    database.usuarios[userId].lastSeen = Date.now();
    database.usuarios[userId].online = true;
    
    if (tipo === 'anti_cheat_scan') {
        database.antiCheatLogs.push({ userId, timestamp: Date.now(), ...dados });
        if (database.antiCheatLogs.length > 5000) database.antiCheatLogs = database.antiCheatLogs.slice(-5000);
    }
    res.json({ sucesso: true });
});

app.get('/api/dados', (req, res) => {
    database.estatisticas.usersOnline = Object.values(database.usuarios).filter(u => u.online).length;
    res.json({
        estatisticas: database.estatisticas,
        metricas: database.metricas,
        antiCheat: { totalScans: database.antiCheatLogs.length }
    });
});

// 💬 Chat do PAINEL (Site) → GEMINI
app.post('/api/ia/chat', async (req, res) => {
    const { pergunta } = req.body;
    if (!pergunta) return res.json({ resposta: "Qual a pergunta?" });
    const resposta = await chamarGemini(pergunta);
    res.json({ resposta });
});

// 🎮 Chat do ROBLOX (Aimbot) → GROQ
app.post('/api/ia/chat-roblox', async (req, res) => {
    const { pergunta } = req.body;
    if (!pergunta) return res.json({ resposta: "Fala aí!" });
    const resposta = await chamarGroq(pergunta);
    res.json({ resposta });
});

app.get('/api/testar', async (req, res) => {
    const resultado = { status: "online", groq: "offline", gemini: "offline" };
    
    try {
        await axios.post(GROQ_URL, {
            model: 'llama-3.1-8b-instant',
            messages: [{ role: 'user', content: 'OK' }]
        }, { headers: { 'Authorization': `Bearer ${GROQ_KEY}`, 'Content-Type': 'application/json' } });
        resultado.groq = "conectado";
    } catch (e) {}

    try {
        await axios.post(GEMINI_URL, {
            contents: [{ parts: [{ text: 'OK' }] }]
        }, { headers: { 'Content-Type': 'application/json', 'x-goog-api-key': GEMINI_KEY } });
        resultado.gemini = "conectado";
    } catch (e) {}

    res.json(resultado);
});

setInterval(async () => {
    try { await axios.get('https://cerebro-ia-mh3k.onrender.com/api/testar'); } catch (e) {}
}, 600000);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log('🧠 Painel=Gemini | Roblox=Groq | Porta ' + PORT));
