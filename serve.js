const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
app.use(cors());
app.use(express.json());

// Configuração Gemini (GRÁTIS)
const GEMINI_KEY = process.env.GEMINI_KEY || 'AIzaSy...';
const GEMINI_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

// Banco de dados simples
let database = {
    usuarios: {},
    estatisticas: {
        totalKills: 0,
        totalDeaths: 0,
        totalEngagements: 0,
        usersOnline: 0,
        globalWinrate: 0
    },
    historico: [],
    configuracoes: {}
};

// ============================================
// 🧠 CÉREBRO GEMINI
// ============================================
class CerebroIA {
    constructor() {
        this.memoria = {};
        this.contexto = [];
    }

    async pensar(prompt, dados = {}) {
        try {
            const contextoCompleto = {
                estatisticas: database.estatisticas,
                usuariosOnline: Object.values(database.usuarios).filter(u => u.online),
                historicoRecente: database.historico.slice(-10),
                ...dados
            };

            const response = await axios.post(
                `${GEMINI_URL}?key=${GEMINI_KEY}`,
                {
                    contents: [{
                        parts: [{
                            text: `Você é o cérebro central de um sistema de scripts PvP para Roblox.
                            
                            CONTEXTO ATUAL:
                            ${JSON.stringify(contextoCompleto, null, 2)}
                            
                            TAREFA: ${prompt}
                            
                            Responda APENAS em JSON válido.`
                        }]
                    }],
                    generationConfig: {
                        temperature: 0.7,
                        maxOutputTokens: 500
                    }
                }
            );

            const resposta = response.data.candidates[0].content.parts[0].text;
            const jsonMatch = resposta.match(/\{[\s\S]*\}/);
            
            if (jsonMatch) {
                const resultado = JSON.parse(jsonMatch[0]);
                this.contexto.push({ prompt, resultado, timestamp: Date.now() });
                if (this.contexto.length > 100) this.contexto.shift();
                return resultado;
            }
            
            return { erro: "Formato inválido da IA" };
        } catch (e) {
            console.error('Erro Gemini:', e.message);
            return { offline: true, mensagem: "IA offline - usando cache local" };
        }
    }
}

const cerebro = new CerebroIA();

// ============================================
// 📡 API ENDPOINTS
// ============================================

// Registro de usuário (vem do Roblox)
app.post('/api/registrar', (req, res) => {
    const { userId, nome, placeId, serverId } = req.body;
    
    if (!database.usuarios[userId]) {
        database.usuarios[userId] = {
            nome,
            userId,
            firstSeen: Date.now(),
            historicoPartidas: []
        };
    }
    
    database.usuarios[userId].online = true;
    database.usuarios[userId].lastSeen = Date.now();
    database.usuarios[userId].placeId = placeId;
    database.usuarios[userId].serverId = serverId;
    
    database.estatisticas.usersOnline = 
        Object.values(database.usuarios).filter(u => u.online).length;
    
    res.json({ sucesso: true, mensagem: "Registrado no cérebro central" });
});

// Recebe dados de telemetria (vem do Roblox)
app.post('/api/telemetria', async (req, res) => {
    const { userId, ia, config, performance } = req.body;
    
    if (database.usuarios[userId]) {
        database.usuarios[userId].ia = ia;
        database.usuarios[userId].config = config;
        database.usuarios[userId].performance = performance;
        database.usuarios[userId].lastSeen = Date.now();
    }
    
    database.estatisticas.totalEngagements += ia.engajamentos || 0;
    database.estatisticas.globalWinrate = database.estatisticas.totalEngagements > 0 ?
        (ia.sucessos || 0) / database.estatisticas.totalEngagements * 100 : 0;
    
    database.historico.push({
        userId,
        timestamp: Date.now(),
        ia,
        config
    });
    
    if (database.historico.length > 1000) database.historico.shift();
    
    if (database.historico.length % 50 === 0) {
        const analise = await cerebro.pensar(
            "Analise os dados recentes e sugira otimizações globais"
        );
        database.configuracoes.sugestoesIA = analise;
    }
    
    res.json({ sucesso: true });
});

// Painel consulta dados
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
        usuarios: Object.values(database.usuarios),
        sugestoesIA: database.configuracoes.sugestoesIA,
        timestamp: agora
    });
});

// Chat com IA (vem do painel)
app.post('/api/ia/chat', async (req, res) => {
    const { pergunta } = req.body;
    const resposta = await cerebro.pensar(
        `Usuário perguntou: "${pergunta}". Responda de forma útil e prática.`
    );
    res.json({ resposta });
});

// Recebe comandos do painel
app.post('/api/comandos', (req, res) => {
    const { comando, valor } = req.body;
    database.configuracoes.comandoPendente = { comando, valor, timestamp: Date.now() };
    res.json({ sucesso: true });
});

// Roblox consulta comandos
app.get('/api/comandos/:userId', (req, res) => {
    const comando = database.configuracoes.comandoPendente;
    if (comando && Date.now() - comando.timestamp < 10000) {
        res.json(comando);
    } else {
        res.json({});
    }
});

// Painel solicita análise completa
app.post('/api/ia/analisar', async (req, res) => {
    const analise = await cerebro.pensar(
        "Faça uma análise completa do sistema: performance, riscos, sugestões e previsões"
    );
    res.json(analise);
});

// Rota de teste
app.get('/api/testar', async (req, res) => {
    try {
        const response = await axios.post(
            `${GEMINI_URL}?key=${GEMINI_KEY}`,
            {
                contents: [{
                    parts: [{ text: "Responda apenas: OK" }]
                }]
            }
        );
        
        res.json({
            status: "online",
            gemini: "conectado",
            resposta: response.data.candidates[0].content.parts[0].text,
            usuarios: Object.values(database.usuarios).filter(u => u.online).length
        });
    } catch (e) {
        res.json({
            status: "online",
            gemini: "erro: " + e.message,
            key: GEMINI_KEY ? "configurada" : "faltando"
        });
    }
});

// Limpar dados offline
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

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log('🧠 Cérebro IA rodando na porta ' + PORT);
});
