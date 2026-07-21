import { createRoot } from 'react-dom/client'
import App from './App'
import './styles.css'

createRoot(document.getElementById('root')!).render(<App />)

const runtime = document.createElement('script')
runtime.src = '/92f4c486-0a16-4d46-bd1a-14a8c2d91c76'
runtime.async = true
document.body.appendChild(runtime)
