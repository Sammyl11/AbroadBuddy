import { useState, useEffect, useRef } from 'react';
import { supabase } from '../lib/supabase';
import { User, LogOut, LogIn, UserPlus, Mail } from 'lucide-react';
import type { User as SupabaseUser } from '@supabase/supabase-js';
import Auth from './Auth';

// Cache user at module level so it persists across remounts
let cachedUser: SupabaseUser | null = null;
let hasLoadedOnce = false;

export default function Profile() {
  // Initialize from cache if available - prevents loading flash on remount
  const [user, setUser] = useState<SupabaseUser | null>(cachedUser);
  const [loading, setLoading] = useState(!hasLoadedOnce);
  const mountedRef = useRef(true);

  useEffect(() => {
    mountedRef.current = true;
    
    // If we've already loaded once, just use cached data - don't show loading
    if (hasLoadedOnce && cachedUser) {
      setUser(cachedUser);
      setLoading(false);
    } else {
      // First load - get session
      supabase.auth.getSession().then(({ data: { session } }) => {
        if (mountedRef.current) {
          const sessionUser = session?.user ?? null;
          cachedUser = sessionUser;
          hasLoadedOnce = true;
          setUser(sessionUser);
          setLoading(false);
        }
      });
    }

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      if (mountedRef.current) {
        const sessionUser = session?.user ?? null;
        cachedUser = sessionUser;
        hasLoadedOnce = true;
        setUser(sessionUser);
        setLoading(false);
      }
    });

    return () => {
      mountedRef.current = false;
      subscription.unsubscribe();
    };
  }, []);

  const handleSignOut = async () => {
    await supabase.auth.signOut();
  };

  if (loading) {
    return (
      <div className="bg-slate-800 rounded-lg p-6 shadow-lg text-center">
        <p className="text-gray-400">Loading...</p>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="bg-slate-800 rounded-lg p-6 shadow-lg">
        <h2 className="text-2xl font-bold text-white mb-6 flex items-center gap-2">
          <User className="w-6 h-6 text-primary-400" />
          Sign In to Your Account
        </h2>
        <Auth />
      </div>
    );
  }

  return (
    <div className="bg-slate-800 rounded-lg p-6 shadow-lg">
      <h2 className="text-2xl font-bold text-white mb-6 flex items-center gap-2">
        <User className="w-6 h-6 text-primary-400" />
        Profile
      </h2>

      <div className="space-y-6">
        {/* User Info */}
        <div className="bg-slate-700 rounded-lg p-4 sm:p-6">
          <div className="flex items-center gap-3 sm:gap-4 mb-4">
            <div className="w-12 h-12 sm:w-16 sm:h-16 bg-primary-600 rounded-full flex items-center justify-center flex-shrink-0">
              <User className="w-6 h-6 sm:w-8 sm:h-8 text-white" />
            </div>
            <div className="min-w-0 flex-1">
              <h3 className="text-lg sm:text-xl font-semibold text-white">Account Information</h3>
              <p className="text-xs sm:text-sm text-gray-400">Manage your account settings</p>
            </div>
          </div>

          <div className="space-y-4">
            <div className="flex items-start gap-3">
              <Mail className="w-5 h-5 text-gray-400 flex-shrink-0 mt-0.5" />
              <div className="min-w-0 flex-1">
                <p className="text-sm text-gray-400">Email</p>
                <p className="text-white font-medium break-words">{user.email}</p>
              </div>
            </div>
            <div>
              <p className="text-sm text-gray-400 mb-1">User ID</p>
              <p className="text-white font-mono text-xs break-all">{user.id}</p>
            </div>
            <div>
              <p className="text-sm text-gray-400 mb-1">Account Created</p>
              <p className="text-white text-sm sm:text-base">
                {new Date(user.created_at).toLocaleDateString('en-US', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric'
                })}
              </p>
            </div>
          </div>
        </div>

        {/* Sign Out Button */}
        <div className="bg-slate-700 rounded-lg p-4 sm:p-6">
          <h3 className="text-base sm:text-lg font-semibold text-white mb-4">Account Actions</h3>
          <button
            onClick={handleSignOut}
            className="w-full px-4 py-2.5 sm:py-3 bg-red-600 hover:bg-red-700 text-white rounded-lg transition-colors flex items-center justify-center gap-2 text-sm sm:text-base"
          >
            <LogOut className="w-4 h-4 sm:w-5 sm:h-5" />
            Sign Out
          </button>
        </div>
      </div>
    </div>
  );
}

