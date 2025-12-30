import { Budget, Trip, WishlistItem, Expense } from '../types';

const STORAGE_KEYS = {
  BUDGET: 'globeBudget_budget',
  TRIPS: 'globeBudget_trips',
  WISHLIST: 'globeBudget_wishlist',
  EXPENSES: 'globeBudget_expenses',
} as const;

export const storage = {
  // Budget
  getBudget: (): Budget | null => {
    const data = localStorage.getItem(STORAGE_KEYS.BUDGET);
    return data ? JSON.parse(data) : null;
  },

  saveBudget: (budget: Budget): void => {
    localStorage.setItem(STORAGE_KEYS.BUDGET, JSON.stringify(budget));
  },

  // Trips
  getTrips: (): Trip[] => {
    const data = localStorage.getItem(STORAGE_KEYS.TRIPS);
    return data ? JSON.parse(data) : [];
  },

  saveTrips: (trips: Trip[]): void => {
    localStorage.setItem(STORAGE_KEYS.TRIPS, JSON.stringify(trips));
  },

  addTrip: (trip: Trip): void => {
    const trips = storage.getTrips();
    trips.push(trip);
    storage.saveTrips(trips);
  },

  updateTrip: (id: string, updates: Partial<Trip>): void => {
    const trips = storage.getTrips();
    const index = trips.findIndex(t => t.id === id);
    if (index !== -1) {
      trips[index] = { ...trips[index], ...updates };
      storage.saveTrips(trips);
    }
  },

  deleteTrip: (id: string): void => {
    const trips = storage.getTrips();
    storage.saveTrips(trips.filter(t => t.id !== id));
  },

  // Wishlist
  getWishlist: (): WishlistItem[] => {
    const data = localStorage.getItem(STORAGE_KEYS.WISHLIST);
    return data ? JSON.parse(data) : [];
  },

  saveWishlist: (items: WishlistItem[]): void => {
    localStorage.setItem(STORAGE_KEYS.WISHLIST, JSON.stringify(items));
  },

  addWishlistItem: (item: WishlistItem): void => {
    const items = storage.getWishlist();
    items.push(item);
    storage.saveWishlist(items);
  },

  updateWishlistItem: (id: string, updates: Partial<WishlistItem>): void => {
    const items = storage.getWishlist();
    const index = items.findIndex(i => i.id === id);
    if (index !== -1) {
      items[index] = { ...items[index], ...updates };
      storage.saveWishlist(items);
    }
  },

  deleteWishlistItem: (id: string): void => {
    const items = storage.getWishlist();
    storage.saveWishlist(items.filter(i => i.id !== id));
  },

  // Expenses
  getExpenses: (): Expense[] => {
    const data = localStorage.getItem(STORAGE_KEYS.EXPENSES);
    return data ? JSON.parse(data) : [];
  },

  saveExpenses: (expenses: Expense[]): void => {
    localStorage.setItem(STORAGE_KEYS.EXPENSES, JSON.stringify(expenses));
  },

  addExpense: (expense: Expense): void => {
    const expenses = storage.getExpenses();
    expenses.push(expense);
    storage.saveExpenses(expenses);
    
    // Update budget spent amount
    const budget = storage.getBudget();
    if (budget) {
      const totalSpent = storage.calculateTotalSpent();
      storage.saveBudget({ ...budget, spent: totalSpent });
    }
  },

  updateExpense: (id: string, updates: Partial<Expense>): void => {
    const expenses = storage.getExpenses();
    const index = expenses.findIndex(e => e.id === id);
    if (index !== -1) {
      expenses[index] = { ...expenses[index], ...updates };
      storage.saveExpenses(expenses);
      
      // Update budget spent amount
      const budget = storage.getBudget();
      if (budget) {
        const totalSpent = storage.calculateTotalSpent();
        storage.saveBudget({ ...budget, spent: totalSpent });
      }
    }
  },

  deleteExpense: (id: string): void => {
    const expenses = storage.getExpenses();
    storage.saveExpenses(expenses.filter(e => e.id !== id));
    
    // Update budget spent amount
    const budget = storage.getBudget();
    if (budget) {
      const totalSpent = storage.calculateTotalSpent();
      storage.saveBudget({ ...budget, spent: totalSpent });
    }
  },

  // Calculate total spent from trips and expenses
  calculateTotalSpent: (): number => {
    const trips = storage.getTrips();
    const expenses = storage.getExpenses();
    
    const tripSpent = trips.reduce((sum, trip) => {
      return sum + (trip.actualCost || trip.estimatedCost);
    }, 0);
    
    const expenseSpent = expenses.reduce((sum, expense) => {
      return sum + expense.amount;
    }, 0);
    
    return tripSpent + expenseSpent;
  },
};

