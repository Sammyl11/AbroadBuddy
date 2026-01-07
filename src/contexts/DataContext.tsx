import { createContext, useContext, useState, useEffect, useRef, ReactNode } from 'react';
import { Budget, Trip, WishlistItem, Expense } from '../types';
import { storage } from '../utils/supabaseStorage';
import { supabase } from '../lib/supabase';

interface DataContextType {
  budget: Budget | null;
  trips: Trip[];
  wishlist: WishlistItem[];
  expenses: Expense[];
  loading: boolean;
  refreshData: () => Promise<void>;
  updateBudget: (budget: Budget | null) => void;
  updateTrips: (trips: Trip[]) => void;
  updateWishlist: (wishlist: WishlistItem[]) => void;
  updateExpenses: (expenses: Expense[]) => void;
}

const DataContext = createContext<DataContextType | undefined>(undefined);

export function DataProvider({ children }: { children: ReactNode }) {
  const [budget, setBudget] = useState<Budget | null>(null);
  const [trips, setTrips] = useState<Trip[]>([]);
  const [wishlist, setWishlist] = useState<WishlistItem[]>([]);
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Track if we've completed initial load - after this, never show loading again
  const initialLoadComplete = useRef(false);

  const refreshData = async () => {
    // Only show loading spinner on initial load
    if (!initialLoadComplete.current) {
      setLoading(true);
    }
    
    // Set a timeout to ensure loading doesn't hang forever
    const timeoutId = setTimeout(() => {
      console.warn('Data loading timeout - stopping load');
      initialLoadComplete.current = true;
      setLoading(false);
    }, 10000);
    
    try {
      // Use getSession() instead of getUser() - it's synchronous and uses cached data
      // This prevents hanging when tab is in background
      const { data: { session } } = await supabase.auth.getSession();
      
      if (!session?.user) {
        setBudget(null);
        setTrips([]);
        setWishlist([]);
        setExpenses([]);
        clearTimeout(timeoutId);
        initialLoadComplete.current = true;
        setLoading(false);
        return;
      }
      
      // Fetch data
      const [savedBudget, savedTrips, savedWishlist, savedExpenses] = await Promise.all([
        storage.getBudget(),
        storage.getTrips(),
        storage.getWishlist(),
        storage.getExpenses(),
      ]);

      if (savedBudget) {
        // Recalculate spent and planned amounts to ensure accuracy
        const { spent: totalSpent, planned: totalPlanned } = await storage.calculateSpentAndPlanned();
        
        // Only update if the amounts have changed
        if (savedBudget.spent !== totalSpent || savedBudget.plannedSpending !== totalPlanned) {
          const updatedBudget = { ...savedBudget, spent: totalSpent, plannedSpending: totalPlanned };
          await storage.saveBudget(updatedBudget);
          setBudget(updatedBudget);
        } else {
          setBudget(savedBudget);
        }
      } else {
        setBudget(null);
      }

      setTrips(savedTrips);
      setWishlist(savedWishlist);
      setExpenses(savedExpenses);
    } catch (error: any) {
      console.error('Error loading data:', error);
      // On error, preserve existing data - don't clear it
    } finally {
      // Mark initial load as complete and hide loading
      clearTimeout(timeoutId);
      initialLoadComplete.current = true;
      setLoading(false);
    }
  };

  useEffect(() => {
    // Load data when component mounts
    refreshData();

    // Listen for auth state changes to reload data
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event) => {
      if (event === 'SIGNED_IN') {
        await refreshData();
      } else if (event === 'SIGNED_OUT') {
        setBudget(null);
        setTrips([]);
        setWishlist([]);
        setExpenses([]);
        setLoading(false);
        initialLoadComplete.current = false; // Reset for next sign in
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const updateBudget = (newBudget: Budget | null) => {
    setBudget(newBudget);
  };

  const updateTrips = (newTrips: Trip[]) => {
    setTrips(newTrips);
  };

  const updateWishlist = (newWishlist: WishlistItem[]) => {
    setWishlist(newWishlist);
  };

  const updateExpenses = (newExpenses: Expense[]) => {
    setExpenses(newExpenses);
  };

  return (
    <DataContext.Provider
      value={{
        budget,
        trips,
        wishlist,
        expenses,
        loading,
        refreshData,
        updateBudget,
        updateTrips,
        updateWishlist,
        updateExpenses,
      }}
    >
      {children}
    </DataContext.Provider>
  );
}

export function useData() {
  const context = useContext(DataContext);
  if (context === undefined) {
    throw new Error('useData must be used within a DataProvider');
  }
  return context;
}

