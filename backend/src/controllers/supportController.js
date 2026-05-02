const fetch = require('node-fetch');

exports.chat = async (req, res) => {
    try {
        const { messages } = req.body;
        if (!messages || !Array.isArray(messages)) {
            return res.status(400).json({ error: 'messages array is required' });
        }

        const systemMessage = {
            role: 'system',
            content: `You are Sykle's friendly customer support assistant. Sykle is a cycling rewards app for London that converts verified cycling workouts from Apple Health into redeemable points called sykles at independent local cafes and bakeries.

Key facts about Sykle:
- Points formula: 100 sykles per km + 10 sykles per minute cycled
- CO2 saved calculated at 150g per km vs driving
- 22 partner businesses across London including coffee shops and bakeries
- Vouchers are valid until the partner closes on the day of redemption
- Sykles never expire
- HealthKit is required to verify cycling activity
- Any cycling workout in Apple Health counts including Apple Watch, Strava, Komoot
- Partners include: OA Coffee, Lannan, Cremerie, Dayz, Sede, Honu, Latte Club, Cado Cado, Browneria, Aleph, Petibon, Fufu, Varmuteo, Tio, Makeroom, Neulo, La Joconde, Been Bakery, Rosemund Bakery, Signorelli Pasticceria, Tamed Fox, Fifth Sip

Be helpful, friendly and concise. Keep responses short as this is a mobile chat interface.`
        };

        const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + process.env.GROQ_API_KEY
            },
            body: JSON.stringify({
                model: 'llama-3.1-8b-instant',
                max_tokens: 1024,
                messages: [systemMessage, ...messages]
            })
        });

        const data = await response.json();

        if (data.error) {
            return res.status(500).json({ error: data.error.message });
        }

        const reply = data.choices?.[0]?.message?.content || 'Sorry, I could not generate a response.';
        res.json({ reply });

    } catch (error) {
        console.error('Support chat error:', error);
        res.status(500).json({ error: 'Failed to get response' });
    }
};
