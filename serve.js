const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
app.use(cors());
app.use(express.json());

const GROQ_KEY = process.env.GROQ_KEY;

app.post('/api/ia/chat', async (req, res) => {
    const { pergunta } = req.body;
    if (!pergunta) return res.json({ resposta: "Qual a pergunta?" });
    
    try {
        const response = await axios.post(
            'https://api.groq.com/openai/v1/chat/completions',
            {
                model: 'llama3-8b-8192',
                messages: [
                    { role: 'system', content: 'Responda em português.' },
                    { role: 'user', content: pergunta }
                ]
            },
            {
                headers: {
                    'Authorization': `Bearer ${GROQ_KEY}`,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        res.json({ resposta: response.data.choices[0].message.content });
    } catch (e) {
        res.json({ resposta: "IA offline: " + e.message });
    }
});

app.get('/api/testar', (req, res) => {
    res.json({ status: "online" });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log('Servidor na porta ' + PORT));
