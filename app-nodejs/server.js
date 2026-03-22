const express = require('express');
const redis = require('redis');

const app = express();
app.use(express.json());

const REDIS_HOST = process.env.REDIS_HOST || 'redis-service';
const REDIS_PORT = process.env.REDIS_PORT || 6379;
const PORT = process.env.PORT || 3000;

let client;

async function connectRedis() {
  client = redis.createClient({
    socket: { host: REDIS_HOST, port: REDIS_PORT }
  });
  client.on('error', (err) => console.log('Redis Error:', err));
  await client.connect();
  console.log('Connected to Redis');
}

// GET - Obtener lista de items
app.get('/items', async (req, res) => {
  try {
    const items = await client.lRange('items', 0, -1);
    res.json({ items, count: items.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST - Guardar item y retornar lista completa
app.post('/items', async (req, res) => {
  try {
    const { item } = req.body;
    if (!item) return res.status(400).json({ error: 'Item required' });
    
    await client.rPush('items', item);
    const items = await client.lRange('items', 0, -1);
    res.json({ message: 'Item saved', items, count: items.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok' }));

connectRedis().then(() => {
  app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
});
