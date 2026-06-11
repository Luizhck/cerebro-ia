const express = require('express');
const cors = require('cors');
const axios = require('axios');
const fs = require('fs');
const crypto = require('crypto');

const app = express();
app.use(cors());
app.use(express.json());

const GROQ_KEY = process.env.GROQ_KEY;
const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const DB_FILE = 'database.json';

// ============================================
// 💾 BANCO DE DADOS
// ============================================
let database = {
    usuarios: {},
    estatisticas: {
        usersOnline: 0,
        globalWinrate: 0,
        totalKills: 0,
        totalDeaths: 0,
        totalEngagements: 0
    },
    historico: [],
    antiCheatLogs: [],
    hookLogs: [],
    configuracoes: {},
    blacklist: [],
    metricas: {
        requisições: 0,
        erros: 0,
        latenciaMedia: 0,
        scansPorHora: 0,
        hooksDetectados: 0,
        clientesComprometidos: 0,
        bansEmitidos: 0
    }
};

try {
    if (fs.existsSync(DB_FILE)) {
        const data = fs.readFileSync(DB_FILE, 'utf8');
        const carregado = JSON.parse(data);
        database = { ...database, ...carregado };
        console.log('📂 Banco carregado!');
        console.log('👥 Usuários:', Object.keys(database.usuarios).length);
        console.log('🔍 Scans:', database.antiCheatLogs.length);
        console.log('🪝 Hooks:', database.hookLogs.length);
    } else {
        console.log('📂 Novo banco criado');
    }
} catch (e) {
    console.log('📂 Erro ao carregar:', e.message);
}

function salvarDB() {
    try {
        fs.writeFileSync(DB_FILE, JSON.stringify(database, null, 2));
    } catch (e) {}
}

setInterval(salvarDB, 30000);
process.on('SIGTERM', () => { salvarDB(); process.exit(0); });
process.on('SIGINT', () => { salvarDB(); process.exit(0); });

// ============================================
// 🧠 CÉREBRO IA - ANTI-ALUCINAÇÃO + HOOKS
// ============================================
class CerebroIA {
    constructor() {
        this.contexto = [];
        this.cache = {};
        this.cacheTimeout = 300000;
    }

    async pensar(prompt, dados = {}) {
        try {
            const cacheKey = crypto.createHash('md5').update(prompt).digest('hex');
            if (this.cache[cacheKey] && Date.now() - this.cache[cacheKey].timestamp < this.cacheTimeout) {
                return this.cache[cacheKey].resposta;
            }

            const hooksDetectados = database.hookLogs.slice(-50);
            const clientesComHooks = [...new Set(hooksDetectados.map(h => h.userId))];
            
            const todosSuspeitos = [];
            const scansComSuspeitos = [];
            
            database.antiCheatLogs.forEach(s => {
                if (s.suspeitos && s.suspeitos.length > 0) {
                    scansComSuspeitos.push({
                        suspeitos: s.suspeitos,
                        risco: s.riskLevel,
                        total: s.totalSuspeitos,
                        data: new Date(s.timestamp).toLocaleString('pt-BR'),
                        userId: s.userId
                    });
                    s.suspeitos.forEach(nome => {
                        if (!todosSuspeitos.includes(nome)) todosSuspeitos.push(nome);
                    });
                }
            });
            
            const frequenciaSuspeitos = {};
            database.antiCheatLogs.forEach(s => {
                if (s.suspeitos) {
                    s.suspeitos.forEach(nome => {
                        frequenciaSuspeitos[nome] = (frequenciaSuspeitos[nome] || 0) + 1;
                    });
                }
            });
            
            const suspeitosOrdenados = Object.entries(frequenciaSuspeitos)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 30)
                .map(([nome, count]) => ({ nome, vezes: count }));

            const agora = Date.now();
            const usuariosAtivos = Object.values(database.usuarios).filter(u => u.online);

            const dadosReais = {
                resumo: {
                    totalUsuarios: Object.keys(database.usuarios).length,
                    onlineAgora: usuariosAtivos.length,
                    totalScans: database.antiCheatLogs.length,
                    scansComSuspeitos: scansComSuspeitos.length,
                    totalHooksDetectados: database.hookLogs.length,
                    clientesComprometidos: clientesComHooks.length,
                    totalBans: database.metricas.bansEmitidos
                },
                hooks: {
                    total: database.hookLogs.length,
                    ultimos: hooksDetectados.slice(-10).reverse().map(h => ({
                        userId: h.userId,
                        hooks: h.hooks?.map(hk => hk.nome || hk) || [],
                        total: h.totalHooks,
                        data: new Date(h.timestamp).toLocaleString('pt-BR')
                    })),
                    clientesAfetados: clientesComHooks.length
                },
                suspeitosDetectados: suspeitosOrdenados,
                ultimosScansSuspeitos: scansComSuspeitos.slice(-10).reverse(),
                usuarios: Object.values(database.usuarios)
                    .sort((a, b) => (b.scans?.length || 0) - (a.scans?.length || 0))
                    .slice(0, 20)
                    .map(u => ({
                        nome: u.nome,
                        userId: u.userId,
                        placeId: u.placeId,
                        online: u.online,
                        scans: u.scans?.length || 0,
                        hooks: u.hooks?.length || 0,
                        ultimaVez: u.lastSeen ? new Date(u.lastSeen).toLocaleString('pt-BR') : 'Nunca'
                    })),
                blacklist: database.blacklist.slice(0, 20)
            };

            const response = await axios.post(GROQ_URL, {
                model: 'llama-3.1-8b-instant',
                messages: [
                    { 
                        role: 'system', 
                        content: `[SISTEMA ROBLOX - ANÁLISE AVANÇADA DE SEGURANÇA]
                        
                        ⚠️ REGRAS ABSOLUTAS:
                        1. NÃO cite VAC, EasyAntiCheat, BattlEye (PC)
                        2. NÃO cite Fortnite, PUBG, Call of Duty (PC)
                        3. SÓ analise DADOS REAIS de ModuleScripts e RemoteEvents do Roblox
                        4. Se vazio, diga "Nenhum suspeito encontrado"
                        5. Português brasileiro
                        6. Use EMOJIS
                        
                        CONTEXTO: Roblox. Hooks = executores detectados. Suspeitos = módulos anti-cheat nos jogos.`
                    },
                    { 
                        role: 'user', 
                        content: `DADOS REAIS DO SISTEMA ROBLOX:\n${JSON.stringify(dadosReais, null, 2)}\n\nPERGUNTA: ${prompt}\n\nUSE APENAS OS DADOS ACIMA. NÃO INVENTE!`
                    }
                ],
                temperature: 0.2,
                max_tokens: 500
            }, {
                headers: {
                    'Authorization': `Bearer ${GROQ_KEY}`,
                    'Content-Type': 'application/json'
                }
            });

            const resposta = response.data.choices[0].message.content;
            this.cache[cacheKey] = { resposta, timestamp: Date.now() };
            return resposta;
        } catch (e) {
            console.error('Erro Groq:', e.message);
            return "🟡 IA temporariamente offline.";
        }
    }
}

const cerebro = new CerebroIA();

// ============================================
// 📡 API ENDPOINTS (SEM AUTENTICAÇÃO)
// ============================================

// Registrar usuário
app.post('/api/registrar', (req, res) => {
    const { userId, nome, placeId, serverId } = req.body;
    if (!userId || !nome || !placeId) return res.status(400).json({ error: 'Dados incompletos' });
    
    if (!database.usuarios[userId]) {
        database.usuarios[userId] = { nome, userId, firstSeen: Date.now(), scans: [], hooks: [] };
    }
    
    database.usuarios[userId].online = true;
    database.usuarios[userId].lastSeen = Date.now();
    database.usuarios[userId].placeId = placeId;
    
    database.estatisticas.usersOnline = Object.values(database.usuarios).filter(u => u.online).length;
    res.json({ sucesso: true });
});

// Telemetria (Scans + Hooks)
app.post('/api/telemetria', (req, res) => {
    const { userId, tipo, dados } = req.body;
    if (!userId || !tipo || !dados) return res.status(400).json({ error: 'Dados incompletos' });
    
    if (!database.usuarios[userId]) {
        database.usuarios[userId] = { online: true, lastSeen: Date.now() };
    }
    database.usuarios[userId].lastSeen = Date.now();
    database.usuarios[userId].online = true;
    
    if (tipo === 'anti_cheat_scan') {
        const scanData = { userId, timestamp: Date.now(), tipo: 'scan', ...dados };
        database.antiCheatLogs.push(scanData);
        if (database.antiCheatLogs.length > 5000) database.antiCheatLogs = database.antiCheatLogs.slice(-5000);
        if (!database.usuarios[userId].scans) database.usuarios[userId].scans = [];
        database.usuarios[userId].scans.push(scanData);
    }
    
    if (tipo === 'hook_detectado') {
        const hookData = { userId, timestamp: Date.now(), tipo: 'hook', ...dados };
        database.hookLogs.push(hookData);
        database.metricas.hooksDetectados++;
        database.metricas.clientesComprometidos = [...new Set(database.hookLogs.map(h => h.userId))].length;
        if (!database.usuarios[userId].hooks) database.usuarios[userId].hooks = [];
        database.usuarios[userId].hooks.push(hookData);
    }
    
    res.json({ sucesso: true });
});

// Painel - Dados
app.get('/api/dados', (req, res) => {
    const agora = Date.now();
    for (let id in database.usuarios) {
        if (agora - database.usuarios[id].lastSeen > 60000) database.usuarios[id].online = false;
    }
    database.estatisticas.usersOnline = Object.values(database.usuarios).filter(u => u.online).length;
    
    const todosSuspeitos = [];
    database.antiCheatLogs.forEach(s => {
        if (s.suspeitos) s.suspeitos.forEach(n => { if (!todosSuspeitos.includes(n)) todosSuspeitos.push(n); });
    });
    
    res.json({
        estatisticas: database.estatisticas,
        metricas: database.metricas,
        suspeitosUnicos: todosSuspeitos,
        hooksDetectados: database.hookLogs.length,
        usuarios: Object.values(database.usuarios).map(u => ({
            nome: u.nome, userId: u.userId, online: u.online,
            placeId: u.placeId, lastSeen: u.lastSeen,
            totalScans: u.scans?.length || 0,
            totalHooks: u.hooks?.length || 0
        })),
        antiCheat: {
            logs: database.antiCheatLogs.slice(-20).reverse(),
            totalScans: database.antiCheatLogs.length
        }
    });
});

// Chat IA
app.post('/api/ia/chat', async (req, res) => {
    const { pergunta } = req.body;
    if (!pergunta) return res.json({ resposta: "Faça uma pergunta!" });
    const resposta = await cerebro.pensar(pergunta);
    res.json({ resposta });
});

// Health check
app.get('/api/testar', async (req, res) => {
    try {
        const start = Date.now();
        const response = await axios.post(GROQ_URL, {
            model: 'llama-3.1-8b-instant',
            messages: [{ role: 'user', content: 'OK' }]
        }, {
            headers: { 'Authorization': `Bearer ${GROQ_KEY}`, 'Content-Type': 'application/json' }
        });
        
        res.json({
            status: "online",
            ia: "conectado",
            latencia: Date.now() - start + "ms",
            uptime: process.uptime(),
            usuarios: database.estatisticas.usersOnline,
            scans: database.antiCheatLogs.length,
            hooks: database.hookLogs.length,
            db: fs.existsSync(DB_FILE) ? "salvo" : "memoria"
        });
    } catch (e) {
        res.json({ status: "degradado", ia: "offline", erro: e.message });
    }
});

// Limpeza
setInterval(() => {
    const agora = Date.now();
    for (let id in database.usuarios) {
        if (agora - database.usuarios[id].lastSeen > 300000) database.usuarios[id].online = false;
    }
    database.estatisticas.usersOnline = Object.values(database.usuarios).filter(u => u.online).length;
    
    for (let key in cerebro.cache) {
        if (agora - cerebro.cache[key].timestamp > cerebro.cacheTimeout) delete cerebro.cache[key];
    }
    
    const scansUltimaHora = database.antiCheatLogs.filter(s => agora - s.timestamp < 3600000).length;
    database.metricas.scansPorHora = scansUltimaHora;
}, 30000);

// Anti-sono
setInterval(async () => {
    try { await axios.get('https://cerebro-ia-mh3k.onrender.com/api/testar'); console.log('⏰ Ping'); } catch (e) {}
}, 300000);

// Iniciar
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log('🧠 qCloud rodando na porta ' + PORT);
    console.log('💾 Banco:', fs.existsSync(DB_FILE) ? 'Carregado' : 'Novo');
    console.log('👥 Usuários:', Object.keys(database.usuarios).length);
    console.log('🔍 Scans:', database.antiCheatLogs.length);
    console.log('🔓 Autenticação: DESATIVADA');
    console.log('✅ Sistema PRONTO!');
});
