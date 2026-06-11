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
const API_KEYS_FILE = 'api_keys.json';
const VALID_API_KEY = process.env.VALID_API_KEY || 'lr-chave-secreta-2024';

// ============================================
// 💾 BANCO DE DADOS COM PERSISTÊNCIA
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
    configuracoes: {},
    apiKeys: {},
    blacklist: [],
    metricas: {
        requisições: 0,
        erros: 0,
        latenciaMedia: 0,
        scansPorHora: 0,
        bansEmitidos: 0
    }
};

// Carregar banco do arquivo
try {
    if (fs.existsSync(DB_FILE)) {
        const data = fs.readFileSync(DB_FILE, 'utf8');
        const carregado = JSON.parse(data);
        database = { ...database, ...carregado };
        console.log('📂 Banco carregado!');
        console.log('👥 Usuários:', Object.keys(database.usuarios).length);
        console.log('🔍 Scans:', database.antiCheatLogs.length);
    } else {
        console.log('📂 Novo banco criado');
    }
} catch (e) {
    console.log('📂 Erro ao carregar:', e.message);
}

// Salvar banco
function salvarDB() {
    try {
        fs.writeFileSync(DB_FILE, JSON.stringify(database, null, 2));
    } catch (e) {}
}

setInterval(salvarDB, 30000); // Salva a cada 30s (mais seguro)
process.on('SIGTERM', () => { salvarDB(); process.exit(0); });
process.on('SIGINT', () => { salvarDB(); process.exit(0); });

// ============================================
// 🔐 SISTEMA DE AUTENTICAÇÃO
// ============================================
function generateApiKey() {
    return 'lr-' + crypto.randomBytes(24).toString('hex');
}

function authenticateApiKey(req, res, next) {
    const apiKey = req.headers['x-api-key'];
    
    // Lista de endpoints públicos (sem autenticação)
    const publicEndpoints = ['/api/testar', '/api/dados'];
    if (publicEndpoints.includes(req.path)) {
        return next();
    }
    
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

// Middleware de rate limiting
const rateLimits = {};
function rateLimiter(maxRequests = 30, windowMs = 60000) {
    return (req, res, next) => {
        const key = req.headers['x-api-key'] || req.ip;
        
        if (!rateLimits[key]) {
            rateLimits[key] = { requests: 0, resetAt: Date.now() + windowMs };
        }
        
        if (Date.now() > rateLimits[key].resetAt) {
            rateLimits[key] = { requests: 0, resetAt: Date.now() + windowMs };
        }
        
        rateLimits[key].requests++;
        
        if (rateLimits[key].requests > maxRequests) {
            database.metricas.erros++;
            return res.status(429).json({ error: 'Muitas requisições. Tente novamente mais tarde.' });
        }
        
        next();
    };
}

// Middleware de validação Roblox
async function validateRobloxServer(placeId, jobId) {
    try {
        // Valida PlaceId contra API do Roblox
        const response = await axios.get(`https://games.roblox.com/v1/games?universeIds=${placeId}`);
        if (response.data.data && response.data.data.length > 0) {
            return true;
        }
        return false;
    } catch (e) {
        // Se a API do Roblox falhar, permitimos mesmo assim (modo permissivo)
        console.log('⚠️ Não foi possível validar com a API do Roblox');
        return true;
    }
}

// Middleware de logging
function requestLogger(req, res, next) {
    const start = Date.now();
    
    res.on('finish', () => {
        const duration = Date.now() - start;
        database.metricas.requisições++;
        database.metricas.latenciaMedia = 
            (database.metricas.latenciaMedia * (database.metricas.requisições - 1) + duration) / 
            database.metricas.requisições;
        
        if (res.statusCode >= 400) {
            database.metricas.erros++;
        }
        
        console.log(`📡 ${req.method} ${req.path} - ${res.statusCode} (${duration}ms)`);
    });
    
    next();
}

// Aplicar middlewares
app.use(requestLogger);
app.use(rateLimiter(60, 60000)); // 60 requisições por minuto
app.use('/api', authenticateApiKey);

// ============================================
// 🧠 CÉREBRO IA - ANTI-ALUCINAÇÃO
// ============================================
class CerebroIA {
    constructor() {
        this.contexto = [];
        this.cache = {};
        this.cacheTimeout = 300000; // 5 minutos
    }

    async pensar(prompt, dados = {}) {
        try {
            // Verifica cache
            const cacheKey = crypto.createHash('md5').update(prompt).digest('hex');
            if (this.cache[cacheKey] && Date.now() - this.cache[cacheKey].timestamp < this.cacheTimeout) {
                return this.cache[cacheKey].resposta;
            }

            // Pega TODOS os suspeitos únicos já encontrados
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
                        if (!todosSuspeitos.includes(nome)) {
                            todosSuspeitos.push(nome);
                        }
                    });
                }
            });
            
            // Conta frequência de cada suspeito
            const frequenciaSuspeitos = {};
            database.antiCheatLogs.forEach(s => {
                if (s.suspeitos) {
                    s.suspeitos.forEach(nome => {
                        frequenciaSuspeitos[nome] = (frequenciaSuspeitos[nome] || 0) + 1;
                    });
                }
            });
            
            // Ordena por mais frequente
            const suspeitosOrdenados = Object.entries(frequenciaSuspeitos)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 30)
                .map(([nome, count]) => ({ nome, vezes: count }));

            // Calcula métricas avançadas
            const agora = Date.now();
            const scansUltimaHora = database.antiCheatLogs.filter(s => agora - s.timestamp < 3600000);
            const scansUltimoDia = database.antiCheatLogs.filter(s => agora - s.timestamp < 86400000);
            
            const usuariosAtivos = Object.values(database.usuarios).filter(u => u.online);
            const usuariosTotal = Object.keys(database.usuarios).length;

            // Dados REAIS e RICOS do sistema
            const dadosReais = {
                resumo: {
                    totalUsuarios: usuariosTotal,
                    onlineAgora: usuariosAtivos.length,
                    totalScans: database.antiCheatLogs.length,
                    scansComSuspeitos: scansComSuspeitos.length,
                    scansUltimaHora: scansUltimaHora.length,
                    scansUltimoDia: scansUltimoDia.length,
                    totalBans: database.metricas.bansEmitidos
                },
                suspeitosDetectados: suspeitosOrdenados,
                ultimosScansSuspeitos: scansComSuspeitos.slice(-15).reverse(),
                usuarios: Object.values(database.usuarios)
                    .sort((a, b) => (b.scans?.length || 0) - (a.scans?.length || 0))
                    .slice(0, 30)
                    .map(u => ({
                        nome: u.nome,
                        userId: u.userId,
                        placeId: u.placeId,
                        online: u.online,
                        scans: u.scans?.length || 0,
                        ultimaVez: u.lastSeen ? new Date(u.lastSeen).toLocaleString('pt-BR') : 'Nunca'
                    })),
                blacklist: database.blacklist.slice(0, 20)
            };

            const response = await axios.post(GROQ_URL, {
                model: 'llama-3.1-8b-instant',
                messages: [
                    { 
                        role: 'system', 
                        content: `[SISTEMA ROBLOX - ANÁLISE DE SEGURANÇA]
                        
                        ⚠️ REGRAS ABSOLUTAS ⚠️
                        1. Você NÃO conhece VAC, EasyAntiCheat, BattlEye (são de PC, não Roblox)
                        2. Você NÃO conhece Fortnite, PUBG, Call of Duty (são de PC/console)
                        3. Você SÓ analisa DADOS REAIS de módulos Roblox
                        4. Se os dados estiverem vazios, diga "Nenhum suspeito encontrado no Roblox"
                        5. NÃO invente nomes de jogos ou anti-cheats
                        6. NÃO sugira código ou comandos
                        7. Responda em português brasileiro
                        8. Use EMOJIS para indicar nível de risco
                        
                        CONTEXTO: Estamos no ROBLOX, analisando ModuleScripts e RemoteEvents.
                        Os "suspeitos" são MÓDULOS encontrados nos jogos do Roblox.`
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
            
            // Salva no cache
            this.cache[cacheKey] = { resposta, timestamp: Date.now() };
            
            return resposta;
        } catch (e) {
            console.error('Erro Groq:', e.message);
            return "🟡 IA temporariamente offline. Sistema continuará funcionando normalmente.";
        }
    }
}

const cerebro = new CerebroIA();

// ============================================
// 📡 API ENDPOINTS
// ============================================

// Gerenciar API Keys
app.post('/api/admin/gerar-chave', (req, res) => {
    const { adminKey, nome } = req.body;
    
    if (adminKey !== VALID_API_KEY) {
        return res.status(403).json({ error: 'Chave admin inválida' });
    }
    
    const newKey = generateApiKey();
    database.apiKeys[newKey] = {
        nome: nome || 'Usuário',
        criada: Date.now(),
        usos: 0
    };
    
    res.json({ chave: newKey, nome: nome });
});

app.get('/api/admin/chaves', (req, res) => {
    const adminKey = req.headers['x-admin-key'];
    
    if (adminKey !== VALID_API_KEY) {
        return res.status(403).json({ error: 'Acesso negado' });
    }
    
    const chaves = Object.entries(database.apiKeys).map(([key, data]) => ({
        chave: key.substring(0, 10) + '...',
        nome: data.nome,
        criada: new Date(data.criada).toLocaleString('pt-BR'),
        usos: data.usos
    }));
    
    res.json({ chaves });
});

// Registro de usuário com validação Roblox
app.post('/api/registrar', async (req, res) => {
    const { userId, nome, placeId, serverId } = req.body;
    
    // Validação de entrada
    if (!userId || !nome || !placeId) {
        return res.status(400).json({ error: 'Dados incompletos' });
    }
    
    // Valida PlaceId
    const isValid = await validateRobloxServer(placeId, serverId);
    if (!isValid) {
        return res.status(403).json({ error: 'Servidor Roblox inválido' });
    }
    
    // Verifica blacklist
    if (database.blacklist.includes(userId)) {
        return res.status(403).json({ error: 'Usuário banido do sistema' });
    }
    
    if (!database.usuarios[userId]) {
        database.usuarios[userId] = {
            nome, userId,
            firstSeen: Date.now(),
            scans: [],
            partidas: []
        };
    }
    
    database.usuarios[userId].online = true;
    database.usuarios[userId].lastSeen = Date.now();
    database.usuarios[userId].placeId = placeId;
    database.usuarios[userId].serverId = serverId;
    
    // Atualiza contagem de API key
    const apiKey = req.headers['x-api-key'];
    if (database.apiKeys[apiKey]) {
        database.apiKeys[apiKey].usos++;
    }
    
    database.estatisticas.usersOnline = 
        Object.values(database.usuarios).filter(u => u.online).length;
    
    res.json({ sucesso: true, mensagem: 'Registrado com sucesso' });
});

// Telemetria com validação
app.post('/api/telemetria', async (req, res) => {
    const { userId, tipo, dados } = req.body;
    
    if (!userId || !tipo || !dados) {
        return res.status(400).json({ error: 'Dados incompletos' });
    }
    
    if (!database.usuarios[userId]) {
        database.usuarios[userId] = { online: true, lastSeen: Date.now() };
    }
    
    database.usuarios[userId].lastSeen = Date.now();
    database.usuarios[userId].online = true;
    
    if (tipo === 'anti_cheat_scan') {
        const scanData = { 
            userId, 
            timestamp: Date.now(), 
            ...dados,
            ip: req.ip,
            userAgent: req.headers['user-agent']
        };
        
        database.antiCheatLogs.push(scanData);
        
        // Mantém apenas últimos 5000 scans
        if (database.antiCheatLogs.length > 5000) {
            database.antiCheatLogs = database.antiCheatLogs.slice(-5000);
        }
        
        if (!database.usuarios[userId].scans) {
            database.usuarios[userId].scans = [];
        }
        database.usuarios[userId].scans.push(scanData);
        
        // Detecta padrões suspeitos
        const usuarioScans = database.usuarios[userId].scans;
        if (usuarioScans.length > 100) {
            const scansRecentes = usuarioScans.slice(-50);
            const todosBaixoRisco = scansRecentes.every(s => s.riskLevel === 'BAIXO');
            
            if (todosBaixoRisco && scansComSuspeitos.length === 0) {
                // Possível evasão de detecção
                database.configuracoes.alertaSilencioso = {
                    userId,
                    motivo: 'Possível evasão de detecção',
                    timestamp: Date.now()
                };
            }
        }
    }
    
    if (tipo === 'dados_ia') {
        database.usuarios[userId].ia = dados.oracle || dados;
        database.estatisticas.totalEngagements += dados.oracle?.engajamentos || 0;
    }
    
    res.json({ sucesso: true });
});

// Dados do painel
app.get('/api/dados', (req, res) => {
    const agora = Date.now();
    
    for (let id in database.usuarios) {
        if (agora - database.usuarios[id].lastSeen > 60000) {
            database.usuarios[id].online = false;
        }
    }
    
    database.estatisticas.usersOnline = 
        Object.values(database.usuarios).filter(u => u.online).length;
    
    // Suspeitos únicos
    const todosSuspeitos = [];
    database.antiCheatLogs.forEach(s => {
        if (s.suspeitos) {
            s.suspeitos.forEach(nome => {
                if (!todosSuspeitos.includes(nome)) {
                    todosSuspeitos.push(nome);
                }
            });
        }
    });
    
    res.json({
        estatisticas: database.estatisticas,
        metricas: database.metricas,
        suspeitosUnicos: todosSuspeitos,
        usuarios: Object.values(database.usuarios).map(u => ({
            nome: u.nome,
            userId: u.userId,
            online: u.online,
            placeId: u.placeId,
            lastSeen: u.lastSeen,
            totalScans: u.scans?.length || 0
        })),
        antiCheat: {
            logs: database.antiCheatLogs.slice(-30).reverse(),
            totalScans: database.antiCheatLogs.length
        }
    });
});

// Chat com IA
app.post('/api/ia/chat', async (req, res) => {
    const { pergunta } = req.body;
    if (!pergunta) return res.json({ resposta: "Faça uma pergunta!" });
    
    const resposta = await cerebro.pensar(pergunta);
    res.json({ resposta });
});

// Análise completa
app.post('/api/ia/analisar', async (req, res) => {
    const analise = await cerebro.pensar(
        "Faça uma análise completa de segurança do sistema baseado nos dados atuais"
    );
    res.json({ analise });
});

// Banir usuário
app.post('/api/admin/banir', (req, res) => {
    const { adminKey, userId, motivo } = req.body;
    
    if (adminKey !== VALID_API_KEY) {
        return res.status(403).json({ error: 'Acesso negado' });
    }
    
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

// Health check
app.get('/api/testar', async (req, res) => {
    try {
        const start = Date.now();
        const response = await axios.post(GROQ_URL, {
            model: 'llama-3.1-8b-instant',
            messages: [{ role: 'user', content: 'OK' }]
        }, {
            headers: {
                'Authorization': `Bearer ${GROQ_KEY}`,
                'Content-Type': 'application/json'
            }
        });
        
        res.json({
            status: "online",
            ia: "conectado",
            latencia: Date.now() - start + "ms",
            uptime: process.uptime(),
            usuarios: database.estatisticas.usersOnline,
            scans: database.antiCheatLogs.length,
            db: fs.existsSync(DB_FILE) ? "salvo" : "memoria",
            metricas: database.metricas
        });
    } catch (e) {
        res.json({
            status: "degradado",
            ia: "offline",
            db: fs.existsSync(DB_FILE) ? "salvo" : "memoria",
            erro: e.message
        });
    }
});

// Métricas do sistema
app.get('/api/admin/metricas', (req, res) => {
    const adminKey = req.headers['x-admin-key'];
    
    if (adminKey !== VALID_API_KEY) {
        return res.status(403).json({ error: 'Acesso negado' });
    }
    
    res.json({
        metricas: database.metricas,
        performance: {
            uptime: process.uptime(),
            memoria: process.memoryUsage(),
            cpu: process.cpuUsage()
        }
    });
});

// Comandos remotos
app.post('/api/comandos', (req, res) => {
    database.configuracoes.comandoPendente = { 
        comando: req.body.comando, 
        valor: req.body.valor, 
        timestamp: Date.now() 
    };
    res.json({ sucesso: true });
});

app.get('/api/comandos/:userId', (req, res) => {
    const cmd = database.configuracoes.comandoPendente;
    if (cmd && Date.now() - cmd.timestamp < 10000) {
        res.json(cmd);
    } else {
        res.json({});
    }
});

// ============================================
// 🧹 LIMPEZA AUTOMÁTICA
// ============================================
setInterval(() => {
    const agora = Date.now();
    
    // Marca offline
    for (let id in database.usuarios) {
        if (agora - database.usuarios[id].lastSeen > 300000) {
            database.usuarios[id].online = false;
        }
    }
    
    // Limpa cache da IA
    for (let key in cerebro.cache) {
        if (agora - cerebro.cache[key].timestamp > cerebro.cacheTimeout) {
            delete cerebro.cache[key];
        }
    }
    
    // Reseta rate limits
    for (let key in rateLimits) {
        if (agora > rateLimits[key].resetAt) {
            delete rateLimits[key];
        }
    }
    
    database.estatisticas.usersOnline = 
        Object.values(database.usuarios).filter(u => u.online).length;
    
    // Calcula scans por hora
    const scansUltimaHora = database.antiCheatLogs.filter(
        s => agora - s.timestamp < 3600000
    ).length;
    database.metricas.scansPorHora = scansUltimaHora;
    
}, 30000);

// ============================================
// ⏰ ANTI-SONO
// ============================================
setInterval(async () => {
    try {
        await axios.get('https://cerebro-ia-mh3k.onrender.com/api/testar');
        console.log('⏰ Ping');
    } catch (e) {}
}, 300000);

// ============================================
// 🚀 INICIAR SERVIDOR
// ============================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log('🧠 Cérebro IA v2.0 rodando na porta ' + PORT);
    console.log('💾 Banco:', fs.existsSync(DB_FILE) ? 'Carregado' : 'Novo');
    console.log('👥 Usuários:', Object.keys(database.usuarios).length);
    console.log('🔍 Scans:', database.antiCheatLogs.length);
    console.log('🔐 Autenticação:', 'ATIVA');
    console.log('🛡️ Rate Limit:', 'ATIVO');
    console.log('✅ Sistema PRONTO!');
});
