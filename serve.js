const express = require('express');
const cors = require('cors');
const axios = require('axios');
const fs = require('fs').promises;
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

const GROQ_KEY = process.env.GROQ_KEY;
const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const DB_FILE = 'database.json';
const MEMORIA_FILE = 'memoria_ia.json';
const PLUGINS_DIR = path.join(__dirname, 'plugins');

let database = {
    usuarios: {},
    estatisticas: { usersOnline: 0 },
    antiCheatLogs: [],
    metricas: { groqUsos: 0, scansTotal: 0 }
};

let memorias = {};

async function carregarMemorias() {
    try {
        const data = await fs.readFile(MEMORIA_FILE, 'utf8');
        memorias = JSON.parse(data);
        console.log('🧠 Memórias carregadas!');
    } catch (e) { memorias = {}; }
}

async function salvarMemorias() {
    try { await fs.writeFile(MEMORIA_FILE, JSON.stringify(memorias, null, 2)); } catch (e) {}
}

carregarMemorias();
setInterval(salvarMemorias, 60000);

async function carregarDB() {
    try {
        const data = await fs.readFile(DB_FILE, 'utf8');
        database = { ...database, ...JSON.parse(data) };
        console.log('📂 Banco carregado!');
    } catch (e) { console.log('📂 Novo banco'); }
}
carregarDB();

async function salvarDB() {
    try { await fs.writeFile(DB_FILE, JSON.stringify(database, null, 2)); } catch (e) {}
}
setInterval(salvarDB, 30000);

// ============================================
// 📦 ENDPOINT DE PLUGINS
// ============================================
app.get('/api/plugin/:nome', async (req, res) => {
    const nome = req.params.nome.toLowerCase();
    const arquivo = path.join(PLUGINS_DIR, nome + '.lua');
    
    try {
        const codigo = await fs.readFile(arquivo, 'utf8');
        res.json({ sucesso: true, codigo: codigo });
    } catch (e) {
        res.json({ sucesso: false, erro: 'Plugin não encontrado: ' + nome });
    }
});

app.get('/api/plugins', async (req, res) => {
    try {
        const arquivos = await fs.readdir(PLUGINS_DIR);
        const plugins = arquivos.filter(f => f.endsWith('.lua')).map(f => f.replace('.lua', ''));
        res.json({ plugins });
    } catch (e) {
        res.json({ plugins: [] });
    }
});

// ============================================
// 🧠 IA ENDPOINTS
// ============================================
async function chamarIA(prompt, userId) {
    try {
        if (!memorias[userId]) {
            memorias[userId] = { historico: [], aprendizado: {} };
        }
        
        memorias[userId].historico.push({ role: 'user', content: prompt });
        
        const messages = [
            { 
                role: 'system', 
                content: `Você é o JARVIS. Retorne JSON com o plugin a usar: {"plugin":"nome","args":"argumentos","resposta":"sua resposta"}. Plugins: speed, teleport, fly, ghost, god, noclip, armas, hitbox, autofarm_loop, autokill_loop, criar, destruir, pulo, noite, dia, reset, loop_parar. Se for conversa, responda normal.`
            },
            ...memorias[userId].historico.slice(-50)
        ];
        
        const response = await axios.post(GROQ_URL, {
            model: 'llama-3.3-70b-versatile',
            messages: messages,
            temperature: 0.7,
            max_tokens: 500
        }, {
            headers: { 'Authorization': `Bearer ${GROQ_KEY}`, 'Content-Type': 'application/json' },
            timeout: 10000
        });

        database.metricas.groqUsos++;
        const respostaIA = response.data.choices[0].message.content;
        memorias[userId].historico.push({ role: 'assistant', content: respostaIA });
        return respostaIA;
    } catch (e) {
        console.log('❌ Groq:', e.message);
        return "🟡 IA offline no momento.";
    }
}

app.post('/api/registrar', (req, res) => {
    const { userId, nome } = req.body;
    if (!userId) return res.status(400).json({ error: 'Dados incompletos' });
    if (!database.usuarios[userId]) database.usuarios[userId] = { nome, userId, scans: 0 };
    database.usuarios[userId].online = true;
    database.usuarios[userId].lastSeen = Date.now();
    database.estatisticas.usersOnline = Object.values(database.usuarios).filter(u => u.online).length;
    res.json({ sucesso: true });
});

app.post('/api/telemetria', (req, res) => {
    const { userId, tipo, dados } = req.body;
    if (!userId) return res.status(400).json({ error: 'userId obrigatório' });
    if (!database.usuarios[userId]) database.usuarios[userId] = { online: true, scans: 0 };
    database.usuarios[userId].lastSeen = Date.now();
    database.usuarios[userId].online = true;
    if (tipo === 'anti_cheat_scan') {
        database.antiCheatLogs.push({ userId, timestamp: Date.now(), dados });
        database.usuarios[userId].scans++;
        database.metricas.scansTotal++;
        if (database.antiCheatLogs.length > 500) database.antiCheatLogs.shift();
    }
    res.json({ sucesso: true });
});

app.get('/api/dados', (req, res) => {
    database.estatisticas.usersOnline = Object.values(database.usuarios).filter(u => u.online).length;
    res.json({
        estatisticas: { usersOnline: database.estatisticas.usersOnline },
        metricas: database.metricas,
        scansAcumulados: database.antiCheatLogs.length
    });
});

app.post('/api/ia/chat', async (req, res) => {
    const { pergunta, userId } = req.body;
    if (!pergunta) return res.json({ resposta: "Qual a pergunta?" });
    const resposta = await chamarIA(pergunta, userId || 'painel');
    res.json({ resposta });
});

app.get('/api/testar', async (req, res) => {
    try {
        const start = Date.now();
        await axios.post(GROQ_URL, {
            model: 'llama-3.3-70b-versatile',
            messages: [{ role: 'user', content: 'OK' }]
        }, { headers: { 'Authorization': `Bearer ${GROQ_KEY}`, 'Content-Type': 'application/json' }, timeout: 5000 });
        res.json({ status: "online", ia: "conectado", latencia: `${Date.now() - start}ms` });
    } catch (e) {
        res.json({ status: "degradado", ia: "offline" });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log('🧩 Jarvis Plugins rodando na porta ' + PORT));
