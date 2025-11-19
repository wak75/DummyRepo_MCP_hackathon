import request from 'supertest';
import { app } from './server.js';

describe('Express Server Tests', () => {
  describe('GET /', () => {
    it('should return Hello World', async () => {
      const res = await request(app)
        .get('/')
        .expect(200);
      
      expect(res.text).toBe('Hello World');
    });

    it('should have correct content-type', async () => {
      const res = await request(app)
        .get('/')
        .expect('Content-Type', /html/);
      
      expect(res.status).toBe(200);
    });
  });

  describe('GET /health', () => {
    it('should return health status', async () => {
      const res = await request(app)
        .get('/health')
        .expect(200);
      
      expect(res.body).toEqual({ status: 'OK' });
    });

    it('should return JSON content-type', async () => {
      const res = await request(app)
        .get('/health')
        .expect('Content-Type', /json/);
      
      expect(res.status).toBe(200);
    });
  });

  describe('404 Handler', () => {
    it('should return 404 for unknown routes', async () => {
      const res = await request(app)
        .get('/unknown-route')
        .expect(404);
    });
  });
});
