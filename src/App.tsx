import pageTemplate from './pageTemplate'

export default function App() {
  return <div dangerouslySetInnerHTML={{ __html: pageTemplate }} />
}
