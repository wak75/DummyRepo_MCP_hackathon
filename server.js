import express from 'express';

const app = express();
const PORT = 4000;

// Root endpoint - returns Hello World
app.get('/', (req, res) => {
  res.send('Hello World');
});



// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK' });
});

// Start server only if this file is run directly
if (import.meta.url === `file://${process.argv[1]}`) {
  app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
  });
}

export { app };
