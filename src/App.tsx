import { useState, useEffect } from 'react';
import { LayoutDashboard, Plane, Heart, CalendarDays, User } from 'lucide-react';
import { supabase } from './lib/supabase';
import { DataProvider } from './contexts/DataContext';
import TripCalendar from './components/TripCalendar';
import Wishlist from './components/Wishlist';
import Dashboard from './components/Dashboard';
import CalendarView from './components/CalendarView';
import Profile from './components/Profile';
import Auth from './components/Auth';
import type { User as SupabaseUser } from '@supabase/supabase-js';

type Tab = 'dashboard' | 'trips' | 'wishlist' | 'calendar' | 'profile';

function App() {
  const [activeTab, setActiveTab] = useState<Tab>('dashboard');
  const [user, setUser] = useState<SupabaseUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;
    
    // Timeout to ensure loading doesn't hang forever
    const timeout = setTimeout(() => {
      if (mounted && loading) {
        console.warn('Auth check timeout - showing login screen');
        setLoading(false);
      }
    }, 5000);

    // Check active session
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (mounted) {
        setUser(session?.user ?? null);
        setLoading(false);
      }
    }).catch((error) => {
      console.error('Error getting session:', error);
      if (mounted) {
        setLoading(false);
      }
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      if (mounted) {
        setUser(session?.user ?? null);
        setLoading(false);
      }
    });

    // Track when tab becomes hidden
    let hiddenTime: number | null = null;
    
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'hidden') {
        hiddenTime = Date.now();
      } else if (document.visibilityState === 'visible' && hiddenTime) {
        // If tab was hidden for more than 2 seconds, reload the page
        // This ensures a fresh Supabase connection
        const timeHidden = Date.now() - hiddenTime;
        if (timeHidden > 2000) {
          window.location.reload();
        }
        hiddenTime = null;
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      mounted = false;
      clearTimeout(timeout);
      subscription.unsubscribe();
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, []);

  const tabs = [
    { id: 'dashboard' as Tab, label: 'Dashboard', icon: LayoutDashboard },
    { id: 'trips' as Tab, label: 'Trips', icon: Plane },
    { id: 'calendar' as Tab, label: 'Calendar', icon: CalendarDays },
    { id: 'wishlist' as Tab, label: 'Wishlist', icon: Heart },
    { id: 'profile' as Tab, label: 'Profile', icon: User },
  ];

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center">
        <div className="text-white">Loading...</div>
      </div>
    );
  }

  if (!user) {
    return <Auth />;
  }

  return (
    <DataProvider>
      <div className="min-h-screen bg-slate-900">
      {/* Header */}
      <header className="bg-slate-800 border-b border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <h1 className="text-3xl font-bold text-white">🌍 AbroadBuddy</h1>
          <p className="text-gray-400 mt-1">Your Study Abroad Budget Planner</p>
        </div>
      </header>

      {/* Navigation */}
      <nav className="bg-slate-800 border-b border-slate-700 sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-center sm:justify-start">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center justify-center gap-2 px-4 sm:px-4 py-3 text-sm font-medium transition-colors whitespace-nowrap ${
                    activeTab === tab.id
                      ? 'text-primary-400 border-b-2 border-primary-400 bg-slate-700'
                      : 'text-gray-400 hover:text-white hover:bg-slate-700'
                  }`}
                  title={tab.label}
                >
                  <Icon className="w-5 h-5" />
                  <span className="hidden sm:inline">{tab.label}</span>
                </button>
              );
            })}
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {activeTab === 'dashboard' && <Dashboard />}
        {activeTab === 'trips' && <TripCalendar />}
        {activeTab === 'calendar' && <CalendarView />}
        {activeTab === 'wishlist' && <Wishlist />}
        {activeTab === 'profile' && <Profile />}
      </main>

      {/* Footer */}
      <footer className="bg-slate-800 border-t border-slate-700 mt-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <p className="text-center text-gray-400 text-sm">
            GlobeBudget - Plan your study abroad adventure with confidence
          </p>
        </div>
      </footer>
      </div>
    </DataProvider>
  );
}

export default App;
