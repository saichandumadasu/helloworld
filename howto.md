# How to Build This — Simple Microservices Hello World

A step-by-step guide to building a microservices web app with **FastAPI**, **uv**, and **React (Vite)** — all running locally.

---

## What We're Building

Three Python backend services + one React frontend, all running locally.

```
Browser (localhost:5173)
    │
    │  fetch /api/
    ▼
gateway (localhost:8000)          ← FastAPI, calls the two services below
    │              │
    ▼              ▼
hello-service   world-service     ← FastAPI, each returns one word
(localhost:8001) (localhost:8002)
```

The final result in your browser: a card showing **"Hello, World!"**

---

## Prerequisites

Install these before starting:

```bash
# 1. uv — Python package manager (replaces pip + venv)
curl -LsSf https://astral.sh/uv/install.sh | sh
uv --version   # should print a version

# 2. Node.js (v18+) — for the React UI
node --version
npm --version
```

---

## Project Structure

```
helloworld/
├── hello-service/
│   ├── pyproject.toml    ← declares deps (fastapi, uvicorn)
│   └── main.py           ← one GET / endpoint → {"message": "Hello"}
├── world-service/
│   ├── pyproject.toml
│   └── main.py           ← one GET / endpoint → {"message": "World"}
├── gateway/
│   ├── pyproject.toml    ← deps: fastapi, uvicorn, httpx
│   └── main.py           ← calls hello + world, returns combined message
└── ui/
    ├── package.json      ← React + Vite deps
    ├── vite.config.js    ← proxy /api → http://localhost:8000
    ├── index.html        ← HTML shell
    └── src/
        ├── main.jsx      ← mounts React app
        └── App.jsx       ← fetches gateway, renders message
```

---

## Step 1 — hello-service

### File: `hello-service/pyproject.toml`

This is the uv project manifest. Like `package.json` for Python.

```toml
[project]
name = "hello-service"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.110",
    "uvicorn[standard]>=0.29",
]
```

- `fastapi` — the web framework
- `uvicorn[standard]` — ASGI server that runs FastAPI

### File: `hello-service/main.py`

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def hello():
    return {"message": "Hello"}
```

- `app = FastAPI()` — creates the app instance
- `@app.get("/")` — registers a GET handler on the root path
- Returns a dict — FastAPI auto-converts it to JSON

### Run it

```bash
cd hello-service
uv run uvicorn main:app --port 8001 --reload
```

- `uv run` — installs deps into an isolated env and runs the command
- `main:app` — `main.py` file, `app` variable inside it
- `--reload` — restarts on file changes (dev mode)

Test it:

```bash
curl http://localhost:8001/
# → {"message":"Hello"}
```

---

## Step 2 — world-service

Identical structure to hello-service, just returns a different word.

### File: `world-service/pyproject.toml`

```toml
[project]
name = "world-service"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.110",
    "uvicorn[standard]>=0.29",
]
```

### File: `world-service/main.py`

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def world():
    return {"message": "World"}
```

### Run it

```bash
cd world-service
uv run uvicorn main:app --port 8002 --reload
```

Test it:

```bash
curl http://localhost:8002/
# → {"message":"World"}
```

---

## Step 3 — gateway

The gateway is the only service the UI talks to. It calls the other two services internally and combines the responses.

### File: `gateway/pyproject.toml`

```toml
[project]
name = "gateway"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.110",
    "uvicorn[standard]>=0.29",
    "httpx>=0.27",
]
```

- `httpx` — async HTTP client used to call hello-service and world-service

### File: `gateway/main.py`

```python
import os
import httpx
from fastapi import FastAPI, HTTPException

app = FastAPI()

HELLO_URL = os.getenv("HELLO_URL", "http://localhost:8001")
WORLD_URL = os.getenv("WORLD_URL", "http://localhost:8002")

@app.get("/")
async def gateway():
    async with httpx.AsyncClient() as client:
        try:
            hello = await client.get(f"{HELLO_URL}/")
            world = await client.get(f"{WORLD_URL}/")
        except httpx.RequestError as exc:
            raise HTTPException(status_code=503, detail=f"Service unreachable: {exc}")
    hello_msg = hello.json()["message"]
    world_msg = world.json()["message"]
    return {"message": f"{hello_msg}, {world_msg}!"}
```

Key points:
- `os.getenv(...)` — reads service URLs from environment. Defaults to `localhost` for local dev. Later, in Docker, you'll override these with container names.
- `async def` + `await` — FastAPI supports async natively. Use it when making IO calls (like HTTP requests).
- `httpx.AsyncClient()` — async HTTP client. Used as a context manager so connections are cleaned up.
- If a downstream service is unreachable, returns HTTP 503 instead of crashing.

### Run it

```bash
cd gateway
uv run uvicorn main:app --port 8000 --reload
```

Test it (hello-service and world-service must be running):

```bash
curl http://localhost:8000/
# → {"message":"Hello, World!"}
```

---

## Step 4 — UI (React + Vite)

### File: `ui/package.json`

```json
{
  "name": "ui",
  "version": "0.1.0",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.3.4",
    "vite": "^6.3.5"
  }
}
```

### File: `ui/vite.config.js`

```js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },
})
```

**Why the proxy?**

When the browser loads the React app from `localhost:5173` and tries to call `localhost:8000`, the browser blocks it (CORS policy). The proxy makes Vite's dev server forward requests — the browser only ever talks to `:5173`, never directly to `:8000`.

- `/api/hello` → strips `/api` → calls `http://localhost:8000/hello`
- `/api/` → strips `/api` → calls `http://localhost:8000/`

### File: `ui/index.html`

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Hello World</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
```

Standard Vite HTML shell. React mounts into `<div id="root">`.

### File: `ui/src/main.jsx`

```jsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
)
```

Boots the React app into the DOM. `StrictMode` catches potential issues during development.

### File: `ui/src/App.jsx`

```jsx
import { useEffect, useState } from 'react'

export default function App() {
  const [message, setMessage] = useState('Loading...')
  const [error, setError] = useState(null)

  useEffect(() => {
    fetch('/api/')
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`)
        return res.json()
      })
      .then((data) => setMessage(data.message))
      .catch((err) => setError(err.message))
  }, [])

  // ... render
}
```

- `useState` — tracks the message and any error
- `useEffect(..., [])` — runs once after the component mounts (page load)
- `fetch('/api/')` — Vite proxies this to `http://localhost:8000/`

### Install deps and run

```bash
cd ui
npm install
npm run dev
```

Open `http://localhost:5173` — you'll see the **Hello, World!** card.

---

## Step 5 — Running Everything Together

You need **4 terminals** open simultaneously.

```bash
# Terminal 1 — hello-service
cd helloworld/hello-service
uv run uvicorn main:app --port 8001 --reload

# Terminal 2 — world-service
cd helloworld/world-service
uv run uvicorn main:app --port 8002 --reload

# Terminal 3 — gateway
cd helloworld/gateway
uv run uvicorn main:app --port 8000 --reload

# Terminal 4 — UI
cd helloworld/ui
npm install   # only needed first time
npm run dev
```

### Verify each layer

```bash
# Layer 1: individual services
curl http://localhost:8001/   # → {"message":"Hello"}
curl http://localhost:8002/   # → {"message":"World"}

# Layer 2: gateway combines them
curl http://localhost:8000/   # → {"message":"Hello, World!"}

# Layer 3: browser
open http://localhost:5173    # → React UI showing "Hello, World!"
```

---

## How uv Works (Quick Reference)

| Command | What it does |
|---|---|
| `uv run uvicorn main:app` | Installs deps (if needed) + runs the command |
| `uv add httpx` | Adds a dep to pyproject.toml + installs it |
| `uv sync` | Installs all deps from pyproject.toml |
| `uv lock` | Generates/updates uv.lock (lockfile) |

uv automatically creates an isolated virtual environment per project inside `.venv/`. You never need to activate it manually when using `uv run`.

---

## Common Errors

| Error | Cause | Fix |
|---|---|---|
| `curl: Connection refused` on :8000 | Gateway not running | Start Terminal 3 |
| `503 Service unreachable` from gateway | hello/world not running | Start Terminals 1 and 2 |
| UI shows `Error: HTTP 404` | Wrong fetch path | Check vite proxy config |
| `npm: command not found` | Node.js not installed | Install Node.js from nodejs.org |

---

## What's Next — Dockerize

Once this all works locally, the next step is to add a `Dockerfile` to each service and wire them with `docker-compose.yml`.

Key difference in Docker:
- Service-to-service calls use **container names** as hostnames, not `localhost`
- Gateway env vars change: `HELLO_URL=http://hello-service:8001`
- UI build gets `VITE_GATEWAY_URL` baked in at build time

That's a separate phase.
