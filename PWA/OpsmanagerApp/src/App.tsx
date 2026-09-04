import { Router, Route } from "preact-router";
import "./App.css";

import Splash from "./pages/Splash"; // Or wherever you saved it
import Welcome from "./pages/Welcome";
import Login from "./pages/Login";
import Dashboard from './pages/Dashboard';

function App() {
  return (
    <Splash>
      <Router>
        <Route path="/" component={Welcome} />
        <Route path="/login" component={Login} />
        <Route path="/dashboard" component={Dashboard} />
      </Router>
    </Splash>
  );
}

export default App;