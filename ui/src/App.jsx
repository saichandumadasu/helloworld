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

  return (
    <div style={styles.page}>
      <div style={styles.card}>
        <h1 style={styles.heading}>Microservices Demo</h1>
        {error ? (
          <p style={styles.error}>Error: {error}</p>
        ) : (
          <p style={styles.message}>{message}</p>
        )}
        <p style={styles.sub}>
          gateway → hello-service + world-service
        </p>
      </div>
    </div>
  )
}

const styles = {
  page: {
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    height: '100vh',
    margin: 0,
    background: '#f0f4f8',
    fontFamily: 'system-ui, sans-serif',
  },
  card: {
    textAlign: 'center',
    background: '#fff',
    borderRadius: '12px',
    padding: '48px 64px',
    boxShadow: '0 4px 24px rgba(0,0,0,0.10)',
  },
  heading: {
    fontSize: '1rem',
    fontWeight: 600,
    color: '#555',
    textTransform: 'uppercase',
    letterSpacing: '0.1em',
    marginBottom: '16px',
  },
  message: {
    fontSize: '3rem',
    fontWeight: 700,
    color: '#1a202c',
    margin: '0 0 16px',
  },
  error: {
    fontSize: '1.2rem',
    color: '#e53e3e',
    margin: '0 0 16px',
  },
  sub: {
    fontSize: '0.85rem',
    color: '#999',
    margin: 0,
  },
}
