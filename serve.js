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

let database = {
    usuarios: {},
    estatisticas: { usersOnline: 0 },
    antiCheatLogs: [],
    metricas: { groqUsos: 0, scansTotal: 0 }
};

// ============================================
// 🧠 MEMÓRIA DE CONVERSAS
// ============================================
const memorias = {};

// Limpeza de memórias antigas (a cada 30 minutos)
setInterval(() => {
    const agora = Date.now();
    for (let id in memorias) {
        if (agora - memorias[id].ultimoUso > 1800000) { // 30 minutos
            delete memorias[id];
        }
    }
}, 600000);

async function carregarDB() {
    try {
        const data = await fs.readFile(DB_FILE, 'utf8');
        database = { ...database, ...JSON.parse(data) };
        console.log('📂 Banco carregado!');
    } catch (e) {
        console.log('📂 Novo banco');
    }
}
carregarDB();

async function salvarDB() {
    try { await fs.writeFile(DB_FILE, JSON.stringify(database, null, 2)); } catch (e) {}
}
setInterval(salvarDB, 30000);

// ============================================
// 🧠 CÉREBRO IA - COM MEMÓRIA
// ============================================
async function chamarIA(prompt, userId) {
    try {
        // Inicializa memória do usuário se não existir
        if (!memorias[userId]) {
            memorias[userId] = {
                historico: [],
                ultimoUso: Date.now()
            };
        }
        
        memorias[userId].ultimoUso = Date.now();
        
        // Adiciona a mensagem do usuário ao histórico
        memorias[userId].historico.push({ role: 'user', content: prompt });
        
        // Mantém apenas as últimas 30 mensagens
        if (memorias[userId].historico.length > 30) {
            memorias[userId].historico = memorias[userId].historico.slice(-30);
        }
        
        // Cria o array de mensagens com o system prompt + histórico
        const messages = [
            { 
                role: 'system', 
                content: `Você é o JARVIS, assistente pessoal de um jogador de Roblox.

REGRAS SIMPLES:
1. Se o usuário pedir uma AÇÃO (fly, speed, god, etc), retorne APENAS o JSON correspondente
2. Se for CONVERSA normal, responda com texto
3. NUNCA analise, NUNCA explique, NUNCA dê aulas
4. Apenas OBEDEÇA e EXECUTE
5. Você tem MEMÓRIA desta conversa, use o histórico para contexto

JSONs que você deve usar:
- fly → {"acao":"fly","resposta":"Fly ativado! 🛫"}
- speed X → {"acao":"modificar","alvo":"velocidade","valor":X,"resposta":"Velocidade X! ⚡"}
- pulo X → {"acao":"modificar","alvo":"pulo","valor":X,"resposta":"Pulo X! 🦘"}
- ghost → {"acao":"ghost","resposta":"Invisível! 👻"}
- god → {"acao":"god","resposta":"God Mode! 🛡️"}
- noclip → {"acao":"noclip","resposta":"NoClip! 👻"}
- reset → {"acao":"reset","resposta":"Reset! 💀"}
- noite → {"acao":"noite","resposta":"Noite! 🌙"}
- dia → {"acao":"dia","resposta":"Dia! ☀️"}
- armas → {"acao":"armas","resposta":"Armas! 🔫"}
- hitbox → {"acao":"hitbox","resposta":"Hitbox! 🎯"}
- auto farm → {"acao":"autofarm","resposta":"AutoFarm! 🔄"}
- auto kill → {"acao":"autokill","resposta":"AutoKill! 🎯"}
- auto fugir → {"acao":"autofugir","resposta":"AutoFugir! 🏃"}
- seguir NOME → {"acao":"seguir","alvo":"NOME","resposta":"Seguindo! 👣"}
- tp NOME → {"acao":"teleportar","alvo":"NOME","resposta":"TP para NOME! 📍"}
- destruir ALVO → {"acao":"destruir","alvo":"ALVO","resposta":"Destruído! 💣"}
- criar → {"acao":"criar","resposta":"Criado! 🏗️"}
- salvar NOME → {"acao":"salvar","alvo":"NOME","resposta":"Salvo! 📍"}
- ir para NOME → {"acao":"ir","alvo":"NOME","resposta":"Indo! 🚀"}
- parar tudo → {"acao":"parar","resposta":"Tudo parado! ⏸️"}`
            },
            ...memorias[userId].historico
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
        
        // Salva a resposta da IA no histórico
        memorias[userId].historico.push({ role: 'assistant', content: respostaIA });
        
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
    const agora = Date.now();
    for (let id in database.usuarios) {
        if (agora - database.usuarios[id].lastSeen > 60000) database.usuarios[id].online = false;
    }
    database.estatisticas.usersOnline = Object.values(database.usuarios).filter(u => u.online).length;
    res.json({
        estatisticas: { usersOnline: database.estatisticas.usersOnline },
        metricas: database.metricas,
        scansAcumulados: database.antiCheatLogs.length,
        antiCheat: { totalScans: database.antiCheatLogs.length }
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

setInterval(() => {
    const agora = Date.now();
    for (let id in database.usuarios) {
        if (agora - database.usuarios[id].lastSeen > 300000) database.usuarios[id].online = false;
    }
    database.estatisticas.usersOnline = Object.values(database.usuarios).filter(u => u.online).length;
}, 30000);

setInterval(async () => {
    try { await axios.get('https://cerebro-ia-mh3k.onrender.com/api/testar', { timeout: 5000 }); } catch (e) {}
}, 600000);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log('🧠 IA com Memória rodando na porta ' + PORT));
