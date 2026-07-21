import { useEffect, useRef, useState } from 'react'
import pageTemplate from './pageTemplate'

export default function App() {
  const [ready, setReady] = useState(false)
  const [bootError, setBootError] = useState(false)
  const hasBooted = useRef(false)

  useEffect(() => {
    const bootTimeout = window.setTimeout(() => {
      if (!hasBooted.current) setBootError(true)
    }, 12000)

    const checkRuntime = () => {
      const root = document.querySelector<HTMLElement>('#dc-root')
      if (!root) {
        setReady(false)
        return
      }

      const hasRawTemplateText = root.textContent?.includes('{{') ?? false
      const orbitCount = Array.from(root.querySelectorAll<HTMLElement>('.hub-stage *')).filter(
        (element) => element.style.animationName === 'orbit',
      ).length
      const sectionsAreReady =
        root.querySelectorAll('.pricing-grid > *').length === 3 &&
        root.querySelectorAll('.step-item').length === 3 &&
        root.querySelectorAll('#faq button').length === 6 &&
        root.querySelectorAll('.mq-item').length >= 14 &&
        orbitCount === 5

      const healthy = !hasRawTemplateText && sectionsAreReady
      if (healthy) {
        hasBooted.current = true
        window.clearTimeout(bootTimeout)
        setBootError(false)
      }
      setReady(hasBooted.current && healthy)
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
