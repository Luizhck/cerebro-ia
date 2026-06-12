const express = require('express');
const cors = require('cors');
const axios = require('axios');
const fs = require('fs').promises;

const app = express();
app.use(cors());
app.use(express.json());

// CONFIGURAÇÕES
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

let memorias = {};

// PERSISTÊNCIA DE DADOS
async function carregarDados() {
    try {
        const dbData = await fs.readFile(DB_FILE, 'utf8');
        database = JSON.parse(dbData);
        console.log('📂 Banco de dados carregado!');
    } catch (e) { console.log('📂 Criando novo banco de dados.'); }

    try {
        const memData = await fs.readFile(MEMORIA_FILE, 'utf8');
        memorias = JSON.parse(memData);
        console.log('🧠 Memórias e Aprendizados carregados!');
    } catch (e) { memorias = {}; }
}

async function salvarTudo() {
    try {
        await fs.writeFile(DB_FILE, JSON.stringify(database, null, 2));
        await fs.writeFile(MEMORIA_FILE, JSON.stringify(memorias, null, 2));
        console.log('💾 Dados persistidos com sucesso.');
    } catch (e) { console.error('❌ Erro ao salvar dados:', e.message); }
}

carregarDados();
setInterval(salvarTudo, 60000); // Salva a cada 1 minuto

// LÓGICA DA IA
async function chamarIA(prompt, userId) {
    try {
        if (!memorias[userId]) {
            memorias[userId] = { 
                historico: [], 
                aprendizado: "Nenhum aprendizado específico ainda.",
                preferencias: {} 
            };
        }

        const userMem = memorias[userId];
        
        // PROMPT DE SISTEMA ESPECIALIZADO
        const systemPrompt = `Você é o JARVIS, um assistente de IA ultra-avançado especializado em Roblox, Luau e Exploração de Mapas.
        
SUA MEMÓRIA DE APRENDIZADO SOBRE ESTE USUÁRIO:
${userMem.aprendizado}

DIRETRIZES:
1. Você é um mestre em Luau (Roblox). Forneça códigos otimizados, seguros e explicados.
2. Você entende tudo sobre exploração de mapas: Raycasting, Region3, detecção de instâncias, e técnicas de bypass de Anti-Cheat.
3. Se o usuário pedir uma AÇÃO técnica, retorne o JSON correspondente. Caso contrário, converse normalmente.
4. Sempre que aprender algo novo sobre o usuário ou suas preferências de script, mencione que guardou isso na memória.

JSONs DE AÇÃO:
fly -> {"acao":"fly"}
speed X -> {"acao":"modificar","alvo":"velocidade","valor":X}
esp -> {"acao":"esp_master"}
scan_map -> {"acao":"scan_full_map"}
noclip -> {"acao":"noclip"}
save_pos -> {"acao":"salvar_posicao"}
load_pos -> {"acao":"ir_posicao"}
get_tools -> {"acao":"pegar_armas"}

IMPORTANTE: Responda em Português Brasileiro. Seja eficiente e técnico.`;

        const messages = [
            { role: 'system', content: systemPrompt },
            ...userMem.historico.slice(-15), // Mantém as últimas 15 mensagens para contexto
            { role: 'user', content: prompt }
        ];

        const response = await axios.post(GROQ_URL, {
            model: 'llama-3.3-70b-versatile',
            messages: messages,
            temperature: 0.6,
            max_tokens: 1000
        }, {
            headers: { 'Authorization': `Bearer ${GROQ_KEY}`, 'Content-Type': 'application/json' },
            timeout: 15000
        });

        const respostaIA = response.data.choices[0].message.content;

        // LÓGICA DE APRENDIZADO AUTOMÁTICO (Simulada via IA)
        // Em uma versão real, poderíamos pedir para a IA extrair o que aprendeu.
        // Aqui, vamos apenas atualizar o histórico.
        userMem.historico.push({ role: 'user', content: prompt });
        userMem.historico.push({ role: 'assistant', content: respostaIA });
        
        // Limpeza de histórico para não estourar tokens
        if (userMem.historico.length > 30) userMem.historico = userMem.historico.slice(-20);

        database.metricas.groqUsos++;
        return respostaIA;
    } catch (e) {
        console.error('❌ Erro na IA:', e.response?.data || e.message);
        return "🟡 JARVIS: Sistema de IA temporariamente instável. Verifique sua conexão ou chave de API.";
    }
}

// ENDPOINTS API
app.post('/api/ia/chat', async (req, res) => {
    const { pergunta, userId } = req.body;
    if (!pergunta) return res.status(400).json({ erro: "O que deseja perguntar?" });
    
    const id = userId || 'default_user';
    const resposta = await chamarIA(pergunta, id);
    res.json({ resposta });
});

// Endpoint para atualizar o aprendizado manualmente se necessário
app.post('/api/ia/aprender', (req, res) => {
    const { userId, novoAprendizado } = req.body;
    if (!userId || !novoAprendizado) return res.status(400).json({ erro: "Dados insuficientes." });
    
    if (!memorias[userId]) memorias[userId] = { historico: [], aprendizado: "" };
    memorias[userId].aprendizado += `\n- ${novoAprendizado}`;
    res.json({ sucesso: true, memoria_atual: memorias[userId].aprendizado });
});

app.get('/api/status', (req, res) => {
    res.json({
        status: "online",
        servidor: "JARVIS Core",
        metricas: database.metricas,
        usuarios_ativos: Object.keys(memorias).length
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 JARVIS V2 (Roblox Expert) rodando na porta ${PORT}`);
});
