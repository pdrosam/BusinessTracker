import { ComponentChildren } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import { route } from 'preact-router';
import { supabase, supabaseUrl, supabaseAnonKey } from '../lib/supabase'; // Adjust path if needed

interface SplashProps {
  children: ComponentChildren;
}

export default function Splash({ children }: SplashProps) {

  const [termsAccepted, setTermsAccepted] = useState(
    localStorage.getItem('termsAccepted') === 'true'
  );
  const [checkboxAccepted, setCheckboxAccepted] = useState(false);

  const [appStatus, setAppStatus] = useState<'checking' | 'error' | 'ready'>('checking');

  useEffect(() => {
    if (!termsAccepted) return;

    let active = true;

    const initializeApp = async () => {
      try {

        if (!navigator.onLine) {
          throw new Error("Device is offline");
        }

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000);

        const healthCheck = await fetch(`${supabaseUrl}/auth/v1/health`, {
          headers: {
            'apikey': supabaseAnonKey
          },
          signal: controller.signal
        });

        clearTimeout(timeoutId);

        if (!healthCheck.ok) {
          throw new Error("Supabase API is down");
        }

        const { data } = await supabase.auth.getSession();

        if (active) {
          if (!data.session && window.location.pathname !== '/login' && window.location.pathname !== '/') {
            route('/login', true);
          }
          setAppStatus('ready');
        }
      } catch (error) {
        console.error("Connection Check Failed:", error);
        if (active) {
          setAppStatus('error');
        }
      }
    };

    initializeApp();

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!session && window.location.pathname !== '/login' && window.location.pathname !== '/') {
        route('/login', true);
      }
    });

    return () => {
      active = false;
      subscription.unsubscribe();
    };
  }, [termsAccepted]);

  const handleAcceptTerms = () => {
    localStorage.setItem('termsAccepted', 'true');
    setTermsAccepted(true);
  };

  // State A: Terms not accepted yet
  if (!termsAccepted) {
    return (
      <main class="center-container">
        <mdui-card class="terms-card">
          <h1 class="main-title">Terms and Conditions</h1>
          <mdui-card variant="filled" class="terms-content">
            <p>Welcome to Ops Manager.</p>
            <p>
              By using this application, you agree to use the service responsibly and to keep
              your account credentials secure. This app may access business data through the
              connected Supabase service. Please ensure you have the necessary authorization to
              use the platform and that your organization permits data processing in this app.
            </p>
            <p>
              We do not guarantee uninterrupted availability. Service may be temporarily
              unavailable due to maintenance, connectivity issues, or external provider status.
            </p>
            <p>
              Continued use of this app signifies acceptance of these terms and your
              responsibility for all actions performed through your account.
            </p>
          </mdui-card>

          <label class="terms-check">
            <mdui-checkbox
              checked={checkboxAccepted}
              onChange={(e: any) => setCheckboxAccepted(e.target.checked)}
            ></mdui-checkbox>
            I agree to the terms and conditions
          </label>

          <mdui-button
            variant="filled"
            disabled={!checkboxAccepted}
            onClick={handleAcceptTerms}
          >
            Continue
          </mdui-button>
        </mdui-card>
      </main>
    );
  }

  // State B: API is unreachable
  if (appStatus === 'error') {
    return (
      <main class="center-container">
        <h1 class="main-title" style={{ color: 'var(--mdui-color-error, #B3261E)' }}>
          Service not available
        </h1>
        <p>Unable to connect to the server. Please try again later.</p>
      </main>
    );
  }

  // State C: Loading API and Session Check
  if (appStatus === 'checking') {
    return (
      <main class="center-container">
        <img
          src="/favicon.svg"
          alt="Loading App..."
          class="splash-logo"
        />
      </main>
    );
  }

  // State D: Everything is verified, render the application routes
  return <>{children}</>;
}