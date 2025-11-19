# Express Hello World Server

A simple Express.js webserver that responds with "Hello World" on port 5000.

## Features

- Express.js webserver
- Hello World endpoint (`GET /`)
- Health check endpoint (`GET /health`)
- Request logging middleware
- Comprehensive test suite using Jest and Supertest

## Installation

```bash
npm install
```

## Running the Server

```bash
npm start
```

The server will start on `http://localhost:5000`

## Running Tests

```bash
npm test
```

To run tests in watch mode:

```bash
npm run test:watch
```

## Endpoints

- `GET /` - Returns "Hello World"
- `GET /health` - Returns JSON status `{ status: 'OK' }`
- Any other route - Returns 404 with `{ error: 'Not Found' }`

## Project Structure

```
.
├── server.js           # Main server file
├── server.test.js      # Test cases
├── package.json        # Project dependencies and scripts
└── README.md           # This file
```
