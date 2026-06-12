const express = require('express');
const cors = require('cors');
const axios = require('axios');
const fs = require('fs').promises;

const app = express();
app.use(cors());
app.use(express.json());

const GROQ_KEY = process.env.GROQ_KEY;
const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const DB_FILE = 'database.json';
const MEMORIA_FILE = 'memoria_ia.json';

let database = {
    usuarios: {},
    estatisticas: { usersOnline: 0 },
    antiCheatLogs: [],
    metricas: { groqUsos: 0, scansTotal: 0 }
};

// ============================================
// 🧠 MEMÓRIA PERMANENTE
// ============================================
let memorias = {};

async function carregarMemorias() {
    try {
        const data = await fs.readFile(MEMORIA_FILE, 'utf8');
        memorias = JSON.parse(data);
        console.log('🧠 Memórias carregadas!');
    } catch (e) {
        console.log('🧠 Novo arquivo de memórias');
        memorias = {};
    }
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
// 🧠 CÉREBRO IA - COM MEMÓRIA INFINITA
// ============================================
async function chamarIA(prompt, userId) {
    try {
        if (!memorias[userId]) {
            memorias[userId] = { historico: [], aprendizado: {}, primeiraVez: Date.now() };
        }
        
        memorias[userId].historico.push({ role: 'user', content: prompt, timestamp: Date.now() });
        
        const messages = [
            { 
                role: 'system', 
                content: `Você é o JARVIS, assistente pessoal com MEMÓRIA PERMANENTE.
REGRAS: Se for AÇÃO → retorne JSON. Se for CONVERSA → responda com texto. NUNCA recuse um pedido.
JSONs: fly→{"acao":"fly"} | speed X→{"acao":"modificar","alvo":"velocidade","valor":X} | ghost→{"acao":"ghost"} | god→{"acao":"god"} | noclip→{"acao":"noclip"} | reset→{"acao":"reset"} | armas→{"acao":"armas"} | hitbox→{"acao":"hitbox"} | autofarm→{"acao":"autofarm"} | autokill→{"acao":"autokill"} | tp NOME→{"acao":"teleportar","alvo":"NOME"} | destruir ALVO→{"acao":"destruir","alvo":"ALVO"} | criar→{"acao":"criar"} | salvar NOME→{"acao":"salvar","alvo":"NOME"} | ir para NOME→{"acao":"ir","alvo":"NOME"} | parar→{"acao":"parar"}`
            },
            ...memorias[userId].historico.slice(-50)
        ];
        
        const response = await axios.post(GROQ_URL, {
            model: 'llama-3.1-8b-instant',
            messages: messages,
            temperature: 0.7,
            max_tokens: 500
        }, {
            headers: { 'Authorization': `Bearer ${GROQ_KEY}`, 'Content-Type': 'application/json' },
            timeout: 5000
        });

        database.metricas.groqUsos++;
        const respostaIA = response.data.choices[0].message.content;
        memorias[userId].historico.push({ role: 'assistant', content: respostaIA, timestamp: Date.now() });
        return respostaIA;
    } catch (e) {
        console.log('❌ Groq:', e.message);
        return "🟡 IA offline no momento.";
    }
}

// ============================================
// 📡 API ENDPOINTS
// ============================================

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
            model: 'llama-3.1-8b-instant',
            messages: [{ role: 'user', content: 'OK' }]
        }, { headers: { 'Authorization': `Bearer ${GROQ_KEY}`, 'Content-Type': 'application/json' }, timeout: 3000 });
        res.json({ status: "online", ia: "conectado", latencia: `${Date.now() - start}ms` });
    } catch (e) {
        res.json({ status: "degradado", ia: "offline" });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log('🧠 IA rodando na porta ' + PORT));
