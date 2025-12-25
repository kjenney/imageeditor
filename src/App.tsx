import './styles/index.css';
import { ImageEditor } from '@/components';

function App() {
  return (
    <div className="app">
      <header className="app-header">
        <h1>Image Editor</h1>
        <p className="app-subtitle">Powered by Konva</p>
      </header>
      <main className="app-main">
        <ImageEditor width={900} height={600} />
      </main>
    </div>
  );
}

export default App;
