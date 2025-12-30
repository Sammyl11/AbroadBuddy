import { useState } from 'react';
import { LayoutDashboard, DollarSign, Calendar, Heart, CalendarDays } from 'lucide-react';
import BudgetManager from './components/BudgetManager';
import TripCalendar from './components/TripCalendar';
import Wishlist from './components/Wishlist';
import Dashboard from './components/Dashboard';
import CalendarView from './components/CalendarView';

type Tab = 'dashboard' | 'budget' | 'trips' | 'wishlist' | 'calendar';

function App() {
  const [activeTab, setActiveTab] = useState<Tab>('dashboard');

  const tabs = [
    { id: 'dashboard' as Tab, label: 'Dashboard', icon: LayoutDashboard },
    { id: 'budget' as Tab, label: 'Budget', icon: DollarSign },
    { id: 'trips' as Tab, label: 'Trips', icon: Calendar },
    { id: 'calendar' as Tab, label: 'Calendar', icon: CalendarDays },
    { id: 'wishlist' as Tab, label: 'Wishlist', icon: Heart },
  ];

  return (
    <div className="min-h-screen bg-slate-900">
      {/* Header */}
      <header className="bg-slate-800 border-b border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <h1 className="text-3xl font-bold text-white">🌍 GlobeBudget</h1>
          <p className="text-gray-400 mt-1">Your Study Abroad Budget Planner</p>
        </div>
      </header>

      {/* Navigation */}
      <nav className="bg-slate-800 border-b border-slate-700 sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex space-x-1 overflow-x-auto">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center gap-2 px-4 py-3 text-sm font-medium transition-colors whitespace-nowrap ${
                    activeTab === tab.id
                      ? 'text-primary-400 border-b-2 border-primary-400 bg-slate-700'
                      : 'text-gray-400 hover:text-white hover:bg-slate-700'
                  }`}
                >
                  <Icon className="w-5 h-5" />
                  <span>{tab.label}</span>
                </button>
              );
            })}
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {activeTab === 'dashboard' && <Dashboard />}
        {activeTab === 'budget' && <BudgetManager />}
        {activeTab === 'trips' && <TripCalendar />}
        {activeTab === 'calendar' && <CalendarView />}
        {activeTab === 'wishlist' && <Wishlist />}
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
  );
}

export default App;
