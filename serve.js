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
const VALID_API_KEY = process.env.VALID_API_KEY || 'lr-chave-secreta-2024';

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
    apiKeys: {},
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
// 🔐 SISTEMA DE AUTENTICAÇÃO
// ============================================
function generateApiKey() {
    return 'lr-' + crypto.randomBytes(24).toString('hex');
}

function authenticateApiKey(req, res, next) {
    const publicEndpoints = ['/api/testar', '/api/dados'];
    if (publicEndpoints.includes(req.path)) return next();
    
    const apiKey = req.headers['x-api-key'];
    if (!apiKey) {
        database.metricas.erros++;
        return res.status(401).json({ error: 'Não autorizado: Chave de API necessária' });
    }
    
    if (apiKey !== VALID_API_KEY && !database.apiKeys[apiKey]) {
        database.metricas.erros++;
        return res.status(401).json({ error: 'Não autorizado: Chave de API inválida' });
    }
    
    next();
}

const rateLimits = {};
function rateLimiter(maxRequests = 60, windowMs = 60000) {
    return (req, res, next) => {
        const key = req.headers['x-api-key'] || req.ip;
        if (!rateLimits[key]) rateLimits[key] = { requests: 0, resetAt: Date.now() + windowMs };
        if (Date.now() > rateLimits[key].resetAt) rateLimits[key] = { requests: 0, resetAt: Date.now() + windowMs };
        rateLimits[key].requests++;
        if (rateLimits[key].requests > maxRequests) {
            database.metricas.erros++;
            return res.status(429).json({ error: 'Muitas requisições. Tente novamente mais tarde.' });
        }
        next();
    };
}

async function validateRobloxServer(placeId, jobId) {
    try {
        const response = await axios.get(`https://games.roblox.com/v1/games?universeIds=${placeId}`);
        if (response.data.data && response.data.data.length > 0) return true;
        return false;
    } catch (e) {
        console.log('⚠️ Não foi possível validar com a API do Roblox');
        return true;
    }
}

function requestLogger(req, res, next) {
    const start = Date.now();
    res.on('finish', () => {
        const duration = Date.now() - start;
        database.metricas.requisições++;
        database.metricas.latenciaMedia = 
            (database.metricas.latenciaMedia * (database.metricas.requisições - 1) + duration) / 
            database.metricas.requisições;
        if (res.statusCode >= 400) database.metricas.erros++;
        console.log(`📡 ${req.method} ${req.path} - ${res.statusCode} (${duration}ms)`);
    });
    next();
}

app.use(requestLogger);
app.use(rateLimiter(60, 60000));
app.use('/api', authenticateApiKey);

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

            // Dados de HOOKS
            const hooksDetectados = database.hookLogs.slice(-50);
            const clientesComHooks = [...new Set(hooksDetectados.map(h => h.userId))];
            
            // Dados de SCANS
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
// 📡 API ENDPOINTS
// ============================================

// Admin - Gerar API Key
app.post('/api/admin/gerar-chave', (req, res) => {
    const { adminKey, nome } = req.body;
    if (adminKey !== VALID_API_KEY) return res.status(403).json({ error: 'Chave admin inválida' });
    
    const newKey = generateApiKey();
    database.apiKeys[newKey] = { nome: nome || 'Usuário', criada: Date.now(), usos: 0 };
    res.json({ chave: newKey, nome: nome });
});

// Admin - Listar chaves
app.get('/api/admin/chaves', (req, res) => {
    const adminKey = req.headers['x-admin-key'];
    if (adminKey !== VALID_API_KEY) return res.status(403).json({ error: 'Acesso negado' });
    
    const chaves = Object.entries(database.apiKeys).map(([key, data]) => ({
        chave: key.substring(0, 10) + '...',
        nome: data.nome,
        criada: new Date(data.criada).toLocaleString('pt-BR'),
        usos: data.usos
    }));
    res.json({ chaves });
});

// Admin - Banir usuário
app.post('/api/admin/banir', (req, res) => {
    const { adminKey, userId, motivo } = req.body;
    if (adminKey !== VALID_API_KEY) return res.status(403).json({ error: 'Acesso negado' });
    
    if (!database.blacklist.includes(userId)) {
        database.blacklist.push(userId);
        database.metricas.bansEmitidos++;
        if (database.usuarios[userId]) {
            database.usuarios[userId].banido = true;
            database.usuarios[userId].motivoBan = motivo;
        }
    }
    res.json({ sucesso: true, mensagem: 'Usuário banido' });
});

// Admin - Métricas
app.get('/api/admin/metricas', (req, res) => {
    const adminKey = req.headers['x-admin-key'];
    if (adminKey !== VALID_API_KEY) return res.status(403).json({ error: 'Acesso negado' });
    
    res.json({
        metricas: database.metricas,
        performance: {
            uptime: process.uptime(),
            memoria: process.memoryUsage(),
            cpu: process.cpuUsage()
        }
    });
});

// Registrar usuário
app.post('/api/registrar', async (req, res) => {
    const { userId, nome, placeId, serverId } = req.body;
    if (!userId || !nome || !placeId) return res.status(400).json({ error: 'Dados incompletos' });
    
    if (database.blacklist.includes(userId)) return res.status(403).json({ error: 'Usuário banido' });
    
    if (!database.usuarios[userId]) {
        database.usuarios[userId] = { nome, userId, firstSeen: Date.now(), scans: [], hooks: [] };
    }
    
    database.usuarios[userId].online = true;
    database.usuarios[userId].lastSeen = Date.now();
    database.usuarios[userId].placeId = placeId;
    
    const apiKey = req.headers['x-api-key'];
    if (database.apiKeys[apiKey]) database.apiKeys[apiKey].usos++;
    
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
    
    // Scan anti-cheat
    if (tipo === 'anti_cheat_scan') {
        const scanData = { userId, timestamp: Date.now(), tipo: 'scan', ...dados };
        database.antiCheatLogs.push(scanData);
        if (database.antiCheatLogs.length > 5000) database.antiCheatLogs = database.antiCheatLogs.slice(-5000);
        if (!database.usuarios[userId].scans) database.usuarios[userId].scans = [];
        database.usuarios[userId].scans.push(scanData);
    }
    
    // Hook detectado
    if (tipo === 'hook_detectado') {
        const hookData = { userId, timestamp: Date.now(), tipo: 'hook', ...dados };
        database.hookLogs.push(hookData);
        database.metricas.hooksDetectados++;
        database.metricas.clientesComprometidos = [...new Set(database.hookLogs.map(h => h.userId))].length;
        if (!database.usuarios[userId].hooks) database.usuarios[userId].hooks = [];
        database.usuarios[userId].hooks.push(hookData);
        
        // Alerta crítico
        database.configuracoes.ultimoAlerta = `🚨 CRÍTICO: ${dados.totalHooks || dados.hooks?.length || 0} hooks no cliente ${userId}!`;
        res.json({ sucesso: true, alerta: "Hooks detectados!" });
        return;
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

// Análise completa
app.post('/api/ia/analisar', async (req, res) => {
    const analise = await cerebro.pensar("Análise completa de segurança incluindo hooks, scans e métricas");
    res.json({ analise });
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
            db: fs.existsSync(DB_FILE) ? "salvo" : "memoria",
            metricas: database.metricas
        });
    } catch (e) {
        res.json({ status: "degradado", ia: "offline", erro: e.message });
    }
});

// Comandos remotos
app.post('/api/comandos', (req, res) => {
    database.configuracoes.comandoPendente = { 
        comando: req.body.comando, valor: req.body.valor, timestamp: Date.now() 
    };
    res.json({ sucesso: true });
});

app.get('/api/comandos/:userId', (req, res) => {
    const cmd = database.configuracoes.comandoPendente;
    if (cmd && Date.now() - cmd.timestamp < 10000) res.json(cmd);
    else res.json({});
});

// ============================================
// 🧹 LIMPEZA AUTOMÁTICA
// ============================================
setInterval(() => {
    const agora = Date.now();
    for (let id in database.usuarios) {
        if (agora - database.usuarios[id].lastSeen > 300000) database.usuarios[id].online = false;
    }
    database.estatisticas.usersOnline = Object.values(database.usuarios).filter(u => u.online).length;
    
    for (let key in cerebro.cache) {
        if (agora - cerebro.cache[key].timestamp > cerebro.cacheTimeout) delete cerebro.cache[key];
    }
    for (let key in rateLimits) {
        if (agora > rateLimits[key].resetAt) delete rateLimits[key];
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
    console.log('🧠 qCloud Fusion v3.0 rodando na porta ' + PORT);
    console.log('💾 Banco:', fs.existsSync(DB_FILE) ? 'Carregado' : 'Novo');
    console.log('👥 Usuários:', Object.keys(database.usuarios).length);
    console.log('🔍 Scans:', database.antiCheatLogs.length);
    console.log('🪝 Hooks:', database.hookLogs.length);
    console.log('🔐 Autenticação: ATIVA');
    console.log('🛡️ Rate Limit: ATIVO');
    console.log('✅ Sistema FUSION PRONTO!');
});
