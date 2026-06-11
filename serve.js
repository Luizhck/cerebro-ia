const express = require('express');
const cors = require('cors');
const axios = require('axios');
const fs = require('fs');

const app = express();
app.use(cors());
app.use(express.json());

const GROQ_KEY = process.env.GROQ_KEY;
const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const DB_FILE = 'database.json';

// ============================================
// 💾 BANCO DE DADOS COM PERSISTÊNCIA
// ============================================
let database = {
    usuarios: {},
    estatisticas: {
        usersOnline: 0,
        globalWinrate: 0
    },
    historico: [],
    antiCheatLogs: [],
    configuracoes: {}
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

setInterval(salvarDB, 60000);
process.on('SIGTERM', () => { salvarDB(); process.exit(0); });
process.on('SIGINT', () => { salvarDB(); process.exit(0); });

// ============================================
// 🧠 CÉREBRO IA - ANTI-ALUCINAÇÃO
// ============================================
class CerebroIA {
    constructor() {
        this.contexto = [];
    }

    async pensar(prompt, dados = {}) {
        try {
            // Dados REAIS do sistema
            const dadosReais = {
                totalUsuarios: Object.keys(database.usuarios).length,
                onlineAgora: Object.values(database.usuarios).filter(u => u.online).length,
                totalScans: database.antiCheatLogs.length,
                usuarios: Object.values(database.usuarios).slice(0, 20).map(u => ({
                    nome: u.nome,
                    userId: u.userId,
                    placeId: u.placeId,
                    online: u.online,
                    scans: u.scans?.length || 0,
                    ultimaVez: u.lastSeen ? new Date(u.lastSeen).toLocaleString('pt-BR') : 'Nunca'
                }))
            };

            const response = await axios.post(GROQ_URL, {
                model: 'llama-3.1-8b-instant',
                messages: [
                    { 
                        role: 'system', 
                        content: `[SISTEMA]: Modo ANALISTA DE DADOS REAIS.
                        
                        REGRAS ABSOLUTAS:
                        1. Você NÃO pode inventar números, nomes ou dados
                        2. Você NÃO pode sugerir código ou comandos
                        3. Você NÃO pode dar exemplos fictícios
                        4. Você SÓ analisa os DADOS REAIS fornecidos abaixo
                        5. Se a informação não estiver nos dados, diga "Não tenho esse dado"
                        6. Responda em português, de forma direta
                        7. Use EMOJIS para indicar nível de risco
                        
                        FORMATO:
                        🟢/🟡/🔴 RISCO: [nível]
                        📊 DADOS REAIS: [análise]
                        💡 SUGESTÃO: [recomendação baseada nos dados reais]`
                    },
                    { 
                        role: 'user', 
                        content: `DADOS REAIS DO SISTEMA (USE APENAS ISTO):
                        
                        ${JSON.stringify(dadosReais, null, 2)}
                        
                        PERGUNTA DO USUÁRIO: ${prompt}
                        
                        IMPORTANTE: Analise APENAS os dados acima.
                        Se perguntarem algo que não está nos dados, diga que não tem essa informação.`
                    }
                ],
                temperature: 0.5,
                max_tokens: 400
            }, {
                headers: {
                    'Authorization': `Bearer ${GROQ_KEY}`,
                    'Content-Type': 'application/json'
                }
            });

            return response.data.choices[0].message.content;
        } catch (e) {
            console.error('Erro Groq:', e.message);
            return "IA offline - usando configurações padrão";
        }
    }
}

const cerebro = new CerebroIA();

// ============================================
// 📡 API ENDPOINTS
// ============================================

app.post('/api/registrar', (req, res) => {
    const { userId, nome, placeId, serverId } = req.body;
    
    if (!database.usuarios[userId]) {
        database.usuarios[userId] = {
            nome, userId,
            firstSeen: Date.now(),
            scans: []
        };
    }
    
    database.usuarios[userId].online = true;
    database.usuarios[userId].lastSeen = Date.now();
    database.usuarios[userId].placeId = placeId || database.usuarios[userId].placeId;
    
    database.estatisticas.usersOnline = 
        Object.values(database.usuarios).filter(u => u.online).length;
    
    res.json({ sucesso: true });
});

app.post('/api/telemetria', async (req, res) => {
    const { userId, tipo, dados } = req.body;
    
    if (!database.usuarios[userId]) {
        database.usuarios[userId] = { online: true, lastSeen: Date.now() };
    }
    
    database.usuarios[userId].lastSeen = Date.now();
    database.usuarios[userId].online = true;
    
    if (tipo === 'anti_cheat_scan') {
        const scanData = { userId, timestamp: Date.now(), ...dados };
        database.antiCheatLogs.push(scanData);
        if (database.antiCheatLogs.length > 1000) {
            database.antiCheatLogs = database.antiCheatLogs.slice(-1000);
        }
        if (!database.usuarios[userId].scans) database.usuarios[userId].scans = [];
        database.usuarios[userId].scans.push(scanData);
    }
    
    res.json({ sucesso: true });
});

app.get('/api/dados', (req, res) => {
    const agora = Date.now();
    for (let id in database.usuarios) {
        if (agora - database.usuarios[id].lastSeen > 60000) {
            database.usuarios[id].online = false;
        }
    }
    database.estatisticas.usersOnline = 
        Object.values(database.usuarios).filter(u => u.online).length;
    
    res.json({
        estatisticas: database.estatisticas,
        usuarios: Object.values(database.usuarios).map(u => ({
            nome: u.nome,
            userId: u.userId,
            online: u.online,
            placeId: u.placeId,
            lastSeen: u.lastSeen,
            totalScans: u.scans?.length || 0
        })),
        antiCheat: {
            logs: database.antiCheatLogs.slice(-20).reverse(),
            totalScans: database.antiCheatLogs.length
        }
    });
});

app.post('/api/ia/chat', async (req, res) => {
    const { pergunta } = req.body;
    if (!pergunta) return res.json({ resposta: "Faça uma pergunta!" });
    const resposta = await cerebro.pensar(pergunta);
    res.json({ resposta });
});

app.get('/api/testar', async (req, res) => {
    try {
        const start = Date.now();
        const response = await axios.post(GROQ_URL, {
            model: 'llama-3.1-8b-instant',
            messages: [{ role: 'user', content: 'Responda apenas: OK' }]
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
            usuarios: database.estatisticas.usersOnline,
            scans: database.antiCheatLogs.length,
            db: fs.existsSync(DB_FILE) ? "salvo" : "memoria"
        });
    } catch (e) {
        res.json({
            status: "online",
            ia: "erro: " + e.message,
            db: fs.existsSync(DB_FILE) ? "salvo" : "memoria"
        });
    }
});

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

// Limpeza
setInterval(() => {
    const agora = Date.now();
    for (let id in database.usuarios) {
        if (agora - database.usuarios[id].lastSeen > 300000) {
            database.usuarios[id].online = false;
        }
    }
    database.estatisticas.usersOnline = 
        Object.values(database.usuarios).filter(u => u.online).length;
}, 30000);

// Anti-sono
setInterval(async () => {
    try {
        await axios.get('https://cerebro-ia-mh3k.onrender.com/api/testar');
        console.log('⏰ Ping');
    } catch (e) {}
}, 300000);

// Iniciar
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log('🧠 Cérebro IA rodando na porta ' + PORT);
    console.log('💾 Banco:', fs.existsSync(DB_FILE) ? 'Carregado' : 'Novo');
    console.log('👥 Usuários salvos:', Object.keys(database.usuarios).length);
});
