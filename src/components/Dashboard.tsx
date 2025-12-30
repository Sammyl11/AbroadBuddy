import { useState, useEffect } from 'react';
import { Budget, Trip, Expense, WishlistItem } from '../types';
import { storage } from '../utils/localStorage';
import { Calendar, Plus, DollarSign, X, Heart, TrendingUp } from 'lucide-react';
import { format, parseISO } from 'date-fns';

export default function Dashboard() {
  const [budget, setBudget] = useState<Budget | null>(null);
  const [wishlist, setWishlist] = useState<WishlistItem[]>([]);
  const [trips, setTrips] = useState<Trip[]>([]);
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [isEditingBudget, setIsEditingBudget] = useState(false);
  const [semesterBudget, setSemesterBudget] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [includeWishlist, setIncludeWishlist] = useState(false);
  const [showExpenseModal, setShowExpenseModal] = useState(false);
  const [expenseForm, setExpenseForm] = useState({
    description: '',
    amount: '',
    date: format(new Date(), 'yyyy-MM-dd'),
    category: '',
    notes: '',
  });

  useEffect(() => {
    const loadData = () => {
      const savedBudget = storage.getBudget();
      const savedWishlist = storage.getWishlist();
      const savedTrips = storage.getTrips();
      const savedExpenses = storage.getExpenses();
      
      if (savedBudget) {
        // Recalculate spent amount to ensure accuracy
        const totalSpent = storage.calculateTotalSpent();
        const updatedBudget = { ...savedBudget, spent: totalSpent };
        storage.saveBudget(updatedBudget);
        
        setBudget(updatedBudget);
        setSemesterBudget(updatedBudget.semesterBudget.toString());
        setStartDate(updatedBudget.startDate);
        setEndDate(updatedBudget.endDate);
      } else {
        setIsEditingBudget(true);
      }
      
      setWishlist(savedWishlist);
      setTrips(savedTrips);
      setExpenses(savedExpenses);
    };

    loadData();
    
    // Listen for storage changes (when data is updated in other components)
    const handleStorageChange = () => {
      loadData();
    };
    
    window.addEventListener('storage', handleStorageChange);
    // Also check periodically for changes (since same-tab updates don't trigger storage event)
    const interval = setInterval(loadData, 1000);
    
    return () => {
      window.removeEventListener('storage', handleStorageChange);
      clearInterval(interval);
    };
  }, []);

  const handleSaveBudget = () => {
    if (!semesterBudget || !startDate || !endDate) {
      alert('Please fill in all fields');
      return;
    }

    const newBudget: Budget = {
      semesterBudget: parseFloat(semesterBudget),
      startDate,
      endDate,
      spent: budget?.spent || 0,
    };

    storage.saveBudget(newBudget);
    setBudget(newBudget);
    setIsEditingBudget(false);
  };

  const handleCancelBudget = () => {
    if (budget) {
      setSemesterBudget(budget.semesterBudget.toString());
      setStartDate(budget.startDate);
      setEndDate(budget.endDate);
      setIsEditingBudget(false);
    }
  };

  // Calculate wishlist total cost
  const wishlistTotal = wishlist.reduce((sum, item) => sum + item.estimatedCost, 0);
  
  // Calculate budget with/without wishlist
  const totalSpent = budget ? budget.spent : 0;
  const totalSpentWithWishlist = totalSpent + wishlistTotal;
  const remaining = budget ? budget.semesterBudget - totalSpent : 0;
  const remainingWithWishlist = budget ? budget.semesterBudget - totalSpentWithWishlist : 0;
  const percentageUsed = budget ? (totalSpent / budget.semesterBudget) * 100 : 0;
  const percentageUsedWithWishlist = budget ? (totalSpentWithWishlist / budget.semesterBudget) * 100 : 0;

  const handleAddExpense = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!expenseForm.description || !expenseForm.amount) {
      alert('Please fill in description and amount');
      return;
    }

    const expense: Expense = {
      id: Date.now().toString(),
      description: expenseForm.description,
      amount: parseFloat(expenseForm.amount),
      date: expenseForm.date,
      category: expenseForm.category || undefined,
      notes: expenseForm.notes || undefined,
    };

    storage.addExpense(expense);
    
    // Reload data
    const savedBudget = storage.getBudget();
    const savedTrips = storage.getTrips();
    const savedExpenses = storage.getExpenses();
    
    setBudget(savedBudget);
    setTrips(savedTrips);
    setExpenses(savedExpenses);

    // Reset form and close modal
    setExpenseForm({
      description: '',
      amount: '',
      date: format(new Date(), 'yyyy-MM-dd'),
      category: '',
      notes: '',
    });
    setShowExpenseModal(false);
  };

  const handleDeleteExpense = (id: string) => {
    if (confirm('Are you sure you want to delete this expense?')) {
      storage.deleteExpense(id);
      
      // Reload data
      const savedBudget = storage.getBudget();
      const savedTrips = storage.getTrips();
      const savedExpenses = storage.getExpenses();
      
      setBudget(savedBudget);
      setTrips(savedTrips);
      setExpenses(savedExpenses);
    }
  };

  const upcomingTrips = trips.filter(trip => {
    const tripDate = parseISO(trip.startDate);
    return tripDate > new Date();
  }).slice(0, 3);

  const recentExpenses = [...expenses]
    .sort((a, b) => parseISO(b.date).getTime() - parseISO(a.date).getTime())
    .slice(0, 5);

  return (
    <div className="space-y-6">
      {/* Budget Overview */}
      <div className="bg-slate-800 rounded-lg p-6 shadow-lg">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-white flex items-center gap-2">
            <DollarSign className="w-6 h-6 text-primary-400" />
            Budget Overview
          </h2>
          {!isEditingBudget && budget && (
            <div className="flex items-center gap-2">
              <button
                onClick={() => setShowExpenseModal(true)}
                className="px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors flex items-center gap-2"
              >
                <Plus className="w-4 h-4" />
                Add Expense
              </button>
              <button
                onClick={() => setIsEditingBudget(true)}
                className="px-4 py-2 bg-slate-600 hover:bg-slate-700 text-white rounded-lg transition-colors"
              >
                Edit
              </button>
            </div>
          )}
        </div>

        {isEditingBudget ? (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Semester Budget ($)
              </label>
              <input
                type="number"
                value={semesterBudget}
                onChange={(e) => setSemesterBudget(e.target.value)}
                className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                placeholder="Enter your total budget"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Start Date
              </label>
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                End Date
              </label>
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
              />
            </div>
            <div className="flex gap-2">
              <button
                onClick={handleSaveBudget}
                className="flex-1 px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors"
              >
                Save
              </button>
              {budget && (
                <button
                  onClick={handleCancelBudget}
                  className="flex-1 px-4 py-2 bg-slate-600 hover:bg-slate-700 text-white rounded-lg transition-colors"
                >
                  Cancel
                </button>
              )}
            </div>
          </div>
        ) : budget ? (
          <div className="space-y-4">
            {/* Toggle for including wishlist */}
            <div className="flex items-center justify-between bg-slate-700 rounded-lg p-4">
              <div className="flex items-center gap-3">
                <Heart className="w-5 h-5 text-primary-400" />
                <div>
                  <label className="text-sm font-medium text-white cursor-pointer">
                    Include Wishlist in Budget
                  </label>
                  <p className="text-xs text-gray-400">
                    {wishlist.length > 0 
                      ? `${wishlist.length} item(s) • $${wishlistTotal.toLocaleString()} total`
                      : 'No wishlist items'}
                  </p>
                </div>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input
                  type="checkbox"
                  checked={includeWishlist}
                  onChange={(e) => setIncludeWishlist(e.target.checked)}
                  className="sr-only peer"
                />
                <div className="w-11 h-6 bg-slate-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-800 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600"></div>
              </label>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="bg-slate-700 rounded-lg p-4">
                <div className="flex items-center gap-2 text-gray-300 mb-1">
                  <DollarSign className="w-4 h-4" />
                  <span className="text-sm">Total Budget</span>
                </div>
                <p className="text-2xl font-bold text-white">
                  ${budget.semesterBudget.toLocaleString()}
                </p>
              </div>
              <div className="bg-slate-700 rounded-lg p-4">
                <div className="flex items-center gap-2 text-gray-300 mb-1">
                  <TrendingUp className="w-4 h-4" />
                  <span className="text-sm">Spent</span>
                  {includeWishlist && wishlistTotal > 0 && (
                    <span className="text-xs text-primary-400 ml-1">(+ wishlist)</span>
                  )}
                </div>
                <p className="text-2xl font-bold text-red-400">
                  ${(includeWishlist ? totalSpentWithWishlist : totalSpent).toLocaleString()}
                </p>
                {includeWishlist && wishlistTotal > 0 && (
                  <p className="text-xs text-gray-400 mt-1">
                    Actual: ${totalSpent.toLocaleString()}
                  </p>
                )}
              </div>
              <div className="bg-slate-700 rounded-lg p-4">
                <div className="flex items-center gap-2 text-gray-300 mb-1">
                  <Calendar className="w-4 h-4" />
                  <span className="text-sm">Remaining</span>
                </div>
                <p className={`text-2xl font-bold ${
                  (includeWishlist ? remainingWithWishlist : remaining) >= 0 
                    ? 'text-green-400' 
                    : 'text-red-400'
                }`}>
                  ${(includeWishlist ? remainingWithWishlist : remaining).toLocaleString()}
                </p>
                {includeWishlist && wishlistTotal > 0 && (
                  <p className="text-xs text-gray-400 mt-1">
                    Without wishlist: ${remaining.toLocaleString()}
                  </p>
                )}
              </div>
            </div>

            <div>
              <div className="flex justify-between text-sm text-gray-300 mb-2">
                <span>Budget Usage</span>
                <span>{(includeWishlist ? percentageUsedWithWishlist : percentageUsed).toFixed(1)}%</span>
              </div>
              <div className="w-full bg-slate-700 rounded-full h-3">
                <div
                  className={`h-3 rounded-full transition-all ${
                    (includeWishlist ? percentageUsedWithWishlist : percentageUsed) > 100
                      ? 'bg-red-500'
                      : 'bg-primary-500'
                  }`}
                  style={{ 
                    width: `${Math.min(includeWishlist ? percentageUsedWithWishlist : percentageUsed, 100)}%` 
                  }}
                />
              </div>
              {includeWishlist && wishlistTotal > 0 && (
                <p className="text-xs text-gray-400 mt-2">
                  Without wishlist: {percentageUsed.toFixed(1)}%
                </p>
              )}
            </div>
          </div>
        ) : null}
      </div>

      {!budget && !isEditingBudget ? (
        <div className="bg-slate-800 rounded-lg p-6 shadow-lg text-center">
          <p className="text-gray-400">Please set up your budget first.</p>
        </div>
      ) : (
        <>
      {upcomingTrips.length > 0 && (
        <div className="bg-slate-800 rounded-lg p-6 shadow-lg">
          <h2 className="text-2xl font-bold text-white mb-4 flex items-center gap-2">
            <Calendar className="w-6 h-6 text-primary-400" />
            Upcoming Trips
          </h2>
          <div className="space-y-3">
            {upcomingTrips.map((trip) => (
              <div key={trip.id} className="bg-slate-700 rounded-lg p-4">
                <div className="flex justify-between items-start">
                  <div>
                    <h3 className="text-lg font-semibold text-white">{trip.name}</h3>
                    <p className="text-sm text-gray-400">{trip.destination}</p>
                    <p className="text-sm text-gray-300 mt-1">
                      {format(parseISO(trip.startDate), 'MMM d')} - {format(parseISO(trip.endDate), 'MMM d, yyyy')}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-lg font-bold text-primary-400">
                      ${(trip.actualCost || trip.estimatedCost).toLocaleString()}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="bg-slate-800 rounded-lg p-6 shadow-lg">
        <h2 className="text-2xl font-bold text-white mb-4 flex items-center gap-2">
          <DollarSign className="w-6 h-6 text-primary-400" />
          Recent Expenses
        </h2>
        {recentExpenses.length === 0 ? (
          <p className="text-gray-400">No expenses recorded yet. Click "Add Expense" to track your spending.</p>
        ) : (
          <div className="space-y-3">
            {recentExpenses.map((expense) => (
              <div key={expense.id} className="bg-slate-700 rounded-lg p-4 flex items-center justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-3">
                    <h3 className="text-lg font-semibold text-white">{expense.description}</h3>
                    {expense.category && (
                      <span className="text-xs px-2 py-1 bg-primary-600 text-white rounded">
                        {expense.category}
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-4 mt-1 text-sm text-gray-400">
                    <span>{format(parseISO(expense.date), 'MMM d, yyyy')}</span>
                    {expense.notes && <span>• {expense.notes}</span>}
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <span className="text-xl font-bold text-red-400">
                    ${expense.amount.toFixed(2)}
                  </span>
                  <button
                    onClick={() => handleDeleteExpense(expense.id)}
                    className="p-2 text-red-400 hover:bg-slate-600 rounded transition-colors"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {showExpenseModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-slate-800 rounded-lg p-6 max-w-md w-full max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-2xl font-bold text-white">Add Expense</h3>
              <button
                onClick={() => setShowExpenseModal(false)}
                className="p-2 text-gray-400 hover:text-white hover:bg-slate-700 rounded transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <form onSubmit={handleAddExpense} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Description *
                </label>
                <input
                  type="text"
                  value={expenseForm.description}
                  onChange={(e) => setExpenseForm({ ...expenseForm, description: e.target.value })}
                  className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                  placeholder="e.g., Groceries, Restaurant, Transportation"
                  required
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">
                    Amount ($) *
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    value={expenseForm.amount}
                    onChange={(e) => setExpenseForm({ ...expenseForm, amount: e.target.value })}
                    className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                    required
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">
                    Date *
                  </label>
                  <input
                    type="date"
                    value={expenseForm.date}
                    onChange={(e) => setExpenseForm({ ...expenseForm, date: e.target.value })}
                    className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                    required
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Category
                </label>
                <input
                  type="text"
                  value={expenseForm.category}
                  onChange={(e) => setExpenseForm({ ...expenseForm, category: e.target.value })}
                  className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                  placeholder="e.g., Food, Transport, Shopping"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Notes
                </label>
                <textarea
                  value={expenseForm.notes}
                  onChange={(e) => setExpenseForm({ ...expenseForm, notes: e.target.value })}
                  className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                  rows={3}
                  placeholder="Additional notes..."
                />
              </div>
              <div className="flex gap-2">
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors"
                >
                  Add Expense
                </button>
                <button
                  type="button"
                  onClick={() => setShowExpenseModal(false)}
                  className="flex-1 px-4 py-2 bg-slate-600 hover:bg-slate-700 text-white rounded-lg transition-colors"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
        </>
      )}
    </div>
  );
}
