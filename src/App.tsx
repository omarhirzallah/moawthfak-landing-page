import { useEffect, useRef, useState } from 'react'
import pageTemplate from './pageTemplate'

export default function App() {
  const [ready, setReady] = useState(false)
  const [bootError, setBootError] = useState(false)
  const hasBooted = useRef(false)

  useEffect(() => {
    const bootTimeout = window.setTimeout(() => {
      if (!hasBooted.current) setBootError(true)
    }, 8000)

    const checkRuntime = () => {
      const root = document.querySelector<HTMLElement>('#dc-root')
      if (!root || hasBooted.current) return

      const hasRawTemplateText = root.textContent?.includes('{{') ?? false
      const heading = root.querySelector('h1')?.textContent?.trim()
      const runtimeHasRendered = Boolean(heading) && !hasRawTemplateText

      if (runtimeHasRendered) {
        hasBooted.current = true
        window.clearTimeout(bootTimeout)
        setBootError(false)
        setReady(true)
        observer.disconnect()
      }
    }

    const observer = new MutationObserver(checkRuntime)
    observer.observe(document.body, {
      childList: true,
      characterData: true,
      subtree: true,
    })
    checkRuntime()

    return () => {
      window.clearTimeout(bootTimeout)
      observer.disconnect()
    }
  }, [])

  useEffect(() => {
    document.documentElement.classList.toggle('site-booting', !ready)
    return () => document.documentElement.classList.remove('site-booting')
  }, [ready])

  return (
    <>
      <div
        className={`runtime-page${ready ? ' is-ready' : ''}`}
        dangerouslySetInnerHTML={{ __html: pageTemplate }}
      />
      <div
        className={`site-loader${ready ? ' is-hidden' : ''}`}
        role="status"
        aria-live="polite"
        aria-label="Loading Mowathfak"
      >
        <img
          src="/81963308-3a39-47b6-a5cf-f2ebbcb11590"
          alt=""
          aria-hidden="true"
        />
        <span>{bootError ? 'The page took too long to load.' : 'Loading Mowathfak…'}</span>
        {bootError && (
          <button type="button" onClick={() => window.location.reload()}>
            Reload page
          </button>
        )}
      </div>
    </>
  )
}
