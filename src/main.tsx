import { render } from 'preact'
import './index.css'
import { App } from './app.tsx'
import 'mdui/mdui.css';
import 'mdui';

render(<App />, document.getElementById('app')!)
