import { useState, useEffect } from 'react';
import { Budget, Expense, BudgetMode } from '../types';
import { storage } from '../utils/supabaseStorage';
import { useData } from '../contexts/DataContext';
import { Calendar, Plus, DollarSign, X, Heart, TrendingUp, Target, Wallet, BarChart3 } from 'lucide-react';
import { format, parseISO } from 'date-fns';

const BUDGET_MODE_INFO = {
  remaining: {
    name: 'Remaining Budget',
    description: 'Start with how much you have left - perfect if you\'re already mid-semester',
    icon: Wallet,
  },
  total: {
    name: 'Total Budget',
    description: 'Set your total budget for the semester and track spending against it',
    icon: Target,
  },
  tracking: {
    name: 'Spending Tracker',
    description: 'No budget limit - just track what you spend and plan to spend',
    icon: BarChart3,
  },
};

export default function Dashboard() {
  const { budget, wishlist, trips, expenses, loading, refreshData, updateBudget } = useData();
  const [isEditingBudget, setIsEditingBudget] = useState(false);
  const [budgetMode, setBudgetMode] = useState<BudgetMode>('remaining');
  const [semesterBudget, setSemesterBudget] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [includeWishlist, setIncludeWishlist] = useState(false);
  const [showExpenseModal, setShowExpenseModal] = useState(false);
  const [expenseModalTab, setExpenseModalTab] = useState<'expense' | 'balance'>('expense');
  const [showExpenseConfirm, setShowExpenseConfirm] = useState(false);
  const [showBalanceConfirm, setShowBalanceConfirm] = useState(false);
  const [newBalanceAmount, setNewBalanceAmount] = useState('');
  const [pendingExpense, setPendingExpense] = useState<{
    description: string;
    amount: number;
    date: string;
    category?: string;
    notes?: string;
  } | null>(null);
  const [expenseForm, setExpenseForm] = useState({
    description: '',
    amount: '',
    date: format(new Date(), 'yyyy-MM-dd'),
    category: '',
    notes: '',
  });

  useEffect(() => {
    // Only set edit mode if budget is null AND not loading
    // This prevents showing edit mode during initial load
    if (budget) {
      setBudgetMode(budget.budgetMode);
      setSemesterBudget(budget.semesterBudget.toString());
      setStartDate(budget.startDate);
      setEndDate(budget.endDate);
      setIsEditingBudget(false);
    } else if (!loading) {
      // Only show edit mode if we're done loading and still have no budget
      setIsEditingBudget(true);
    }
  }, [budget, loading]);

  const handleSaveBudget = async () => {
    if ((budgetMode !== 'tracking' && !semesterBudget) || !startDate || !endDate) {
      alert('Please fill in all required fields');
      return;
    }

    try {
      const newBudget: Budget = {
        budgetMode,
        semesterBudget: budgetMode === 'tracking' ? 0 : parseFloat(semesterBudget),
        startDate,
        endDate,
        spent: budget?.spent || 0,
        plannedSpending: budget?.plannedSpending || 0,
      };

      await storage.saveBudget(newBudget);
      updateBudget(newBudget);
      setIsEditingBudget(false);
    } catch (error: any) {
      alert('Error saving budget: ' + (error.message || 'Unknown error'));
    }
  };

  const handleCancelBudget = () => {
    if (budget) {
      setBudgetMode(budget.budgetMode);
      setSemesterBudget(budget.semesterBudget.toString());
      setStartDate(budget.startDate);
      setEndDate(budget.endDate);
      setIsEditingBudget(false);
    }
  };

  // Calculate wishlist total cost
  const wishlistTotal = wishlist.reduce((sum, item) => sum + item.estimatedCost, 0);
  
  // Calculate trip totals
  const tripsPrepaid = trips.reduce((sum, trip) => sum + trip.prepaidCost, 0);
  const tripsPlanned = trips.reduce((sum, trip) => sum + trip.plannedCost, 0);
  const expensesTotal = expenses.reduce((sum, expense) => sum + expense.amount, 0);
  
  // Total spent = prepaid trips + expenses
  const totalSpent = tripsPrepaid + expensesTotal;
  // Total planned = planned trip costs
  const totalPlanned = tripsPlanned;
  
  // Calculate budget with/without wishlist
  const totalSpentWithWishlist = totalSpent + wishlistTotal;
  const remaining = budget ? budget.semesterBudget - totalSpent : 0;
  const remainingWithWishlist = budget ? budget.semesterBudget - totalSpentWithWishlist : 0;
  const remainingAfterPlanned = remaining - totalPlanned;
  const remainingAfterPlannedWithWishlist = remainingWithWishlist - totalPlanned;
  
  const percentageUsed = budget && budget.semesterBudget > 0 ? (totalSpent / budget.semesterBudget) * 100 : 0;
  const percentageUsedWithWishlist = budget && budget.semesterBudget > 0 ? (totalSpentWithWishlist / budget.semesterBudget) * 100 : 0;
  const percentageCommitted = budget && budget.semesterBudget > 0 ? ((totalSpent + totalPlanned) / budget.semesterBudget) * 100 : 0;

  const [isSaving, setIsSaving] = useState(false);

  // For remaining budget mode: show confirmation before adding expense
  const handleExpenseFormSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!expenseForm.description || !expenseForm.amount) {
      alert('Please fill in description and amount');
      return;
    }

    const amount = parseFloat(expenseForm.amount);
    
    // For remaining budget mode, show confirmation with new balance
    if (budget?.budgetMode === 'remaining') {
      setPendingExpense({
        description: expenseForm.description,
        amount,
        date: expenseForm.date,
        category: expenseForm.category || undefined,
        notes: expenseForm.notes || undefined,
      });
      setShowExpenseConfirm(true);
    } else {
      // For other modes, add directly
      handleAddExpense({
        description: expenseForm.description,
        amount,
        date: expenseForm.date,
        category: expenseForm.category || undefined,
        notes: expenseForm.notes || undefined,
      });
    }
  };

  const handleAddExpense = async (expenseData: {
    description: string;
    amount: number;
    date: string;
    category?: string;
    notes?: string;
  }) => {
    if (isSaving) return; // Prevent double submission
    setIsSaving(true);

    // Timeout to prevent hanging
    const timeoutId = setTimeout(() => {
      setIsSaving(false);
      alert('Request timed out. Please refresh the page and try again.');
    }, 10000);

    try {
      const expense: Expense = {
        id: crypto.randomUUID(),
        description: expenseData.description,
        amount: expenseData.amount,
        date: expenseData.date,
        category: expenseData.category,
        notes: expenseData.notes,
      };

      await storage.addExpense(expense);
      clearTimeout(timeoutId);
      
      // Refresh all data to update budget spent amount
      await refreshData();

      // Reset form and close modal
      setExpenseForm({
        description: '',
        amount: '',
        date: format(new Date(), 'yyyy-MM-dd'),
        category: '',
        notes: '',
      });
      setPendingExpense(null);
      setShowExpenseConfirm(false);
      setShowExpenseModal(false);
    } catch (error: any) {
      clearTimeout(timeoutId);
      alert('Error adding expense: ' + (error.message || 'Unknown error'));
    } finally {
      setIsSaving(false);
    }
  };

  // Handle updating balance for remaining budget mode
  const handleUpdateBalance = async () => {
    if (!newBalanceAmount || !budget) {
      alert('Please enter your new balance');
      return;
    }

    setShowBalanceConfirm(true);
  };

  const confirmUpdateBalance = async () => {
    if (!budget || !newBalanceAmount) return;

    if (isSaving) return;
    setIsSaving(true);

    const timeoutId = setTimeout(() => {
      setIsSaving(false);
      alert('Request timed out. Please refresh the page and try again.');
    }, 10000);

    try {
      const newBalance = parseFloat(newBalanceAmount);
      const currentBalance = budget.semesterBudget;
      const difference = currentBalance - newBalance;

      // Update the budget with new remaining amount
      const updatedBudget: Budget = {
        ...budget,
        semesterBudget: newBalance,
      };

      // If difference is positive, add an expense for the difference
      if (difference > 0) {
        const expense: Expense = {
          id: crypto.randomUUID(),
          description: 'Balance Update',
          amount: difference,
          date: format(new Date(), 'yyyy-MM-dd'),
          category: 'Balance Adjustment',
          notes: `Balance updated from $${currentBalance.toLocaleString()} to $${newBalance.toLocaleString()}`,
        };
        await storage.addExpense(expense);
      }

      await storage.saveBudget(updatedBudget);
      clearTimeout(timeoutId);
      
      await refreshData();

      // Reset and close
      setNewBalanceAmount('');
      setShowBalanceConfirm(false);
      setShowExpenseModal(false);
    } catch (error: any) {
      clearTimeout(timeoutId);
      alert('Error updating balance: ' + (error.message || 'Unknown error'));
    } finally {
      setIsSaving(false);
    }
  };

  const handleDeleteExpense = async (id: string) => {
    if (confirm('Are you sure you want to delete this expense?')) {
      try {
        await storage.deleteExpense(id);
        
        // Refresh all data to update budget spent amount
        await refreshData();
      } catch (error: any) {
        alert('Error deleting expense: ' + (error.message || 'Unknown error'));
      }
    }
  };

  const upcomingTrips = trips.filter(trip => {
    const tripDate = parseISO(trip.startDate);
    return tripDate > new Date();
  }).slice(0, 3);

  const recentExpenses = [...expenses]
    .sort((a, b) => parseISO(b.date).getTime() - parseISO(a.date).getTime())
    .slice(0, 5);

  if (loading) {
    return (
      <div className="bg-slate-800 rounded-lg p-6 shadow-lg text-center">
        <p className="text-gray-400">Loading...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Budget Overview */}
      <div className="bg-slate-800 rounded-lg p-6 shadow-lg">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
          <h2 className="text-xl sm:text-2xl font-bold text-white flex items-center gap-2">
            <DollarSign className="w-5 h-5 sm:w-6 sm:h-6 text-primary-400" />
            Budget Overview
          </h2>
          {!isEditingBudget && budget && (
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
              <button
                onClick={() => {
                  setExpenseModalTab('expense');
                  setShowExpenseModal(true);
                }}
                className="px-4 py-2 text-sm sm:text-base bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors flex items-center justify-center gap-2"
              >
                <Plus className="w-4 h-4" />
                {budget.budgetMode === 'remaining' ? 'Add Expense / Update Balance' : 'Add Expense'}
              </button>
              <button
                onClick={() => setIsEditingBudget(true)}
                className="px-4 py-2 text-sm sm:text-base bg-slate-600 hover:bg-slate-700 text-white rounded-lg transition-colors"
              >
                Edit Mode
              </button>
            </div>
          )}
        </div>

        {isEditingBudget ? (
          <div className="space-y-4">
            {/* Budget Mode Selection */}
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-3">
                How do you want to track your budget?
              </label>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                {(Object.keys(BUDGET_MODE_INFO) as BudgetMode[]).map((mode) => {
                  const info = BUDGET_MODE_INFO[mode];
                  const Icon = info.icon;
                  return (
                    <button
                      key={mode}
                      type="button"
                      onClick={() => setBudgetMode(mode)}
                      className={`p-4 rounded-lg border-2 transition-all text-left ${
                        budgetMode === mode
                          ? 'border-primary-500 bg-primary-500/10'
                          : 'border-slate-600 bg-slate-700 hover:border-slate-500'
                      }`}
                    >
                      <Icon className={`w-5 h-5 mb-2 ${budgetMode === mode ? 'text-primary-400' : 'text-gray-400'}`} />
                      <h4 className="font-medium text-white text-sm">{info.name}</h4>
                      <p className="text-xs text-gray-400 mt-1">{info.description}</p>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Budget Amount - only for total and remaining modes */}
            {budgetMode !== 'tracking' && (
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  {budgetMode === 'total' ? 'Total Budget ($)' : 'Current Remaining ($)'}
                </label>
                <input
                  type="number"
                  value={semesterBudget}
                  onChange={(e) => setSemesterBudget(e.target.value)}
                  className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                  placeholder={budgetMode === 'total' ? 'Enter your total budget' : 'Enter how much you have left'}
                  required
                />
                {budgetMode === 'remaining' && (
                  <p className="text-xs text-gray-500 mt-1">
                    Enter the amount you currently have available. Add prepaid expenses as trips.
                  </p>
                )}
              </div>
            )}

            {budgetMode === 'tracking' && (
              <div className="bg-slate-700 rounded-lg p-4">
                <p className="text-sm text-gray-300">
                  In tracking mode, there's no budget limit. You'll see a summary of what you've spent and what you plan to spend.
                </p>
              </div>
            )}

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Start Date
                </label>
                <input
                  type="date"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                  required
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
                  required
                />
              </div>
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
            {/* Mode indicator */}
            <div className="flex items-center gap-2 text-sm text-gray-400">
              {(() => {
                const Icon = BUDGET_MODE_INFO[budget.budgetMode].icon;
                return <Icon className="w-4 h-4" />;
              })()}
              <span>{BUDGET_MODE_INFO[budget.budgetMode].name}</span>
            </div>

            {/* Toggle for including wishlist - only for modes with a budget */}
            {budget.budgetMode !== 'tracking' && (
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
            )}

            {/* Budget Overview - Different layouts per mode */}
            {budget.budgetMode === 'tracking' ? (
              /* Tracking Mode - No budget limit */
              <div className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="bg-slate-700 rounded-lg p-4">
                    <div className="flex items-center gap-2 text-gray-300 mb-1">
                      <DollarSign className="w-4 h-4" />
                      <span className="text-sm">Total Spent</span>
                    </div>
                    <p className="text-2xl font-bold text-red-400">
                      ${totalSpent.toLocaleString()}
                    </p>
                    <p className="text-xs text-gray-400 mt-1">
                      Trips: ${tripsPrepaid.toLocaleString()} | Expenses: ${expensesTotal.toLocaleString()}
                    </p>
                  </div>
                  <div className="bg-slate-700 rounded-lg p-4">
                    <div className="flex items-center gap-2 text-gray-300 mb-1">
                      <Calendar className="w-4 h-4" />
                      <span className="text-sm">Planned Spending</span>
                    </div>
                    <p className="text-2xl font-bold text-yellow-400">
                      ${totalPlanned.toLocaleString()}
                    </p>
                    <p className="text-xs text-gray-400 mt-1">
                      Future trip costs
                    </p>
                  </div>
                  <div className="bg-slate-700 rounded-lg p-4">
                    <div className="flex items-center gap-2 text-gray-300 mb-1">
                      <TrendingUp className="w-4 h-4" />
                      <span className="text-sm">Total Committed</span>
                    </div>
                    <p className="text-2xl font-bold text-primary-400">
                      ${(totalSpent + totalPlanned).toLocaleString()}
                    </p>
                    <p className="text-xs text-gray-400 mt-1">
                      Spent + Planned
                    </p>
                  </div>
                </div>
                {wishlistTotal > 0 && (
                  <div className="bg-slate-700 rounded-lg p-4">
                    <div className="flex items-center gap-2 text-gray-300 mb-1">
                      <Heart className="w-4 h-4 text-primary-400" />
                      <span className="text-sm">Wishlist Total</span>
                    </div>
                    <p className="text-xl font-bold text-gray-300">
                      ${wishlistTotal.toLocaleString()}
                    </p>
                  </div>
                )}
              </div>
            ) : budget.budgetMode === 'remaining' ? (
              /* Remaining Budget Mode - Different layout */
              <div className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                  {/* 1. Current Remaining (the input value) */}
                  <div className="bg-slate-700 rounded-lg p-4">
                    <div className="flex items-center gap-2 text-gray-300 mb-1">
                      <Wallet className="w-4 h-4" />
                      <span className="text-sm">Current Remaining</span>
                    </div>
                    <p className="text-2xl font-bold text-green-400">
                      ${budget.semesterBudget.toLocaleString()}
                    </p>
                    <p className="text-xs text-gray-400 mt-1">
                      Your available funds
                    </p>
                  </div>
                  {/* 2. Planned */}
                  <div className="bg-slate-700 rounded-lg p-4">
                    <div className="flex items-center gap-2 text-gray-300 mb-1">
                      <Calendar className="w-4 h-4" />
                      <span className="text-sm">Planned</span>
                    </div>
                    <p className="text-2xl font-bold text-yellow-400">
                      ${(includeWishlist ? totalPlanned + wishlistTotal : totalPlanned).toLocaleString()}
                    </p>
                    <p className="text-xs text-gray-400 mt-1">
                      Future trip costs
                    </p>
                  </div>
                  {/* 3. After Planned Spending */}
                  <div className="bg-slate-700 rounded-lg p-4">
                    <div className="flex items-center gap-2 text-gray-300 mb-1">
                      <Target className="w-4 h-4" />
                      <span className="text-sm">After Planned</span>
                    </div>
                    <p className={`text-2xl font-bold ${
                      (budget.semesterBudget - (includeWishlist ? totalPlanned + wishlistTotal : totalPlanned)) >= 0 
                        ? 'text-primary-400' 
                        : 'text-red-400'
                    }`}>
                      ${(budget.semesterBudget - (includeWishlist ? totalPlanned + wishlistTotal : totalPlanned)).toLocaleString()}
                    </p>
                    <p className="text-xs text-gray-400 mt-1">
                      Remaining - Planned
                    </p>
                  </div>
                  {/* 4. Spent/Prepaid */}
                  <div className="bg-slate-700 rounded-lg p-4">
                    <div className="flex items-center gap-2 text-gray-300 mb-1">
                      <TrendingUp className="w-4 h-4" />
                      <span className="text-sm">Spent / Prepaid</span>
                    </div>
                    <p className="text-2xl font-bold text-red-400">
                      ${totalSpent.toLocaleString()}
                    </p>
                    <p className="text-xs text-gray-400 mt-1">
                      Already paid
                    </p>
                  </div>
                </div>

                {/* Progress bar - only planned vs remaining */}
                <div className="space-y-3">
                  <div>
                    <div className="flex justify-between text-sm text-gray-300 mb-1">
                      <span>Planned Usage</span>
                      <span>{budget.semesterBudget > 0 ? (((includeWishlist ? totalPlanned + wishlistTotal : totalPlanned) / budget.semesterBudget) * 100).toFixed(1) : 0}%</span>
                    </div>
                    <div className="w-full bg-slate-700 rounded-full h-2">
                      <div
                        className={`h-2 rounded-full transition-all ${
                          (includeWishlist ? totalPlanned + wishlistTotal : totalPlanned) > budget.semesterBudget
                            ? 'bg-red-500'
                            : 'bg-yellow-400'
                        }`}
                        style={{ 
                          width: `${Math.min(budget.semesterBudget > 0 ? ((includeWishlist ? totalPlanned + wishlistTotal : totalPlanned) / budget.semesterBudget) * 100 : 0, 100)}%` 
                        }}
                      />
                    </div>
                  </div>
                </div>
              </div>
            ) : (
              /* Total Budget Mode */
              <div className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
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
                      <span className="text-sm">Planned</span>
                    </div>
                    <p className="text-2xl font-bold text-yellow-400">
                      ${totalPlanned.toLocaleString()}
                    </p>
                    <p className="text-xs text-gray-400 mt-1">
                      Future trip costs
                    </p>
                  </div>
                  <div className="bg-slate-700 rounded-lg p-4">
                    <div className="flex items-center gap-2 text-gray-300 mb-1">
                      <Wallet className="w-4 h-4" />
                      <span className="text-sm">Available</span>
                    </div>
                    <p className={`text-2xl font-bold ${
                      (includeWishlist ? remainingAfterPlannedWithWishlist : remainingAfterPlanned) >= 0 
                        ? 'text-green-400' 
                        : 'text-red-400'
                    }`}>
                      ${(includeWishlist ? remainingAfterPlannedWithWishlist : remainingAfterPlanned).toLocaleString()}
                    </p>
                    <p className="text-xs text-gray-400 mt-1">
                      After planned spending
                    </p>
                  </div>
                </div>

                {/* Progress bars */}
                <div className="space-y-3">
                  <div>
                    <div className="flex justify-between text-sm text-gray-300 mb-1">
                      <span>Spent</span>
                      <span>{(includeWishlist ? percentageUsedWithWishlist : percentageUsed).toFixed(1)}%</span>
                    </div>
                    <div className="w-full bg-slate-700 rounded-full h-2">
                      <div
                        className={`h-2 rounded-full transition-all ${
                          (includeWishlist ? percentageUsedWithWishlist : percentageUsed) > 100
                            ? 'bg-red-500'
                            : 'bg-red-400'
                        }`}
                        style={{ 
                          width: `${Math.min(includeWishlist ? percentageUsedWithWishlist : percentageUsed, 100)}%` 
                        }}
                      />
                    </div>
                  </div>
                  <div>
                    <div className="flex justify-between text-sm text-gray-300 mb-1">
                      <span>Committed (Spent + Planned)</span>
                      <span>{percentageCommitted.toFixed(1)}%</span>
                    </div>
                    <div className="w-full bg-slate-700 rounded-full h-2">
                      <div
                        className={`h-2 rounded-full transition-all ${
                          percentageCommitted > 100 ? 'bg-red-500' : 'bg-primary-500'
                        }`}
                        style={{ width: `${Math.min(percentageCommitted, 100)}%` }}
                      />
                    </div>
                  </div>
                </div>
              </div>
            )}
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
                      ${(trip.prepaidCost + trip.plannedCost).toLocaleString()}
                    </p>
                    {trip.prepaidCost > 0 && (
                      <p className="text-xs text-green-400">Prepaid: ${trip.prepaidCost.toLocaleString()}</p>
                    )}
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
              <h3 className="text-2xl font-bold text-white">
                {budget?.budgetMode === 'remaining' 
                  ? (expenseModalTab === 'expense' ? 'Add Expense' : 'Update Balance')
                  : 'Add Expense'}
              </h3>
              <button
                onClick={() => {
                  setShowExpenseModal(false);
                  setShowExpenseConfirm(false);
                  setShowBalanceConfirm(false);
                  setPendingExpense(null);
                }}
                className="p-2 text-gray-400 hover:text-white hover:bg-slate-700 rounded transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Tabs for Remaining Budget Mode */}
            {budget?.budgetMode === 'remaining' && (
              <div className="flex gap-2 mb-4">
                <button
                  type="button"
                  onClick={() => {
                    setExpenseModalTab('expense');
                    setShowBalanceConfirm(false);
                  }}
                  className={`flex-1 px-4 py-2 rounded-lg transition-colors text-sm font-medium ${
                    expenseModalTab === 'expense'
                      ? 'bg-primary-600 text-white'
                      : 'bg-slate-700 text-gray-300 hover:bg-slate-600'
                  }`}
                >
                  Add Expense
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setExpenseModalTab('balance');
                    setShowExpenseConfirm(false);
                    setPendingExpense(null);
                  }}
                  className={`flex-1 px-4 py-2 rounded-lg transition-colors text-sm font-medium ${
                    expenseModalTab === 'balance'
                      ? 'bg-primary-600 text-white'
                      : 'bg-slate-700 text-gray-300 hover:bg-slate-600'
                  }`}
                >
                  Update Balance
                </button>
              </div>
            )}

            {/* Add Expense Tab */}
            {expenseModalTab === 'expense' && !showExpenseConfirm && (
              <form onSubmit={handleExpenseFormSubmit} className="space-y-4">
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
                    disabled={isSaving}
                    className="flex-1 px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isSaving ? 'Saving...' : 'Add Expense'}
                  </button>
                  <button
                    type="button"
                    onClick={() => setShowExpenseModal(false)}
                    disabled={isSaving}
                    className="flex-1 px-4 py-2 bg-slate-600 hover:bg-slate-700 text-white rounded-lg transition-colors disabled:opacity-50"
                  >
                    Cancel
                  </button>
                </div>
              </form>
            )}

            {/* Expense Confirmation for Remaining Budget Mode */}
            {expenseModalTab === 'expense' && showExpenseConfirm && pendingExpense && budget && (
              <div className="space-y-4">
                <div className="bg-slate-700 rounded-lg p-4">
                  <p className="text-sm text-gray-300 mb-3">Confirm this expense:</p>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span className="text-gray-400">Description:</span>
                      <span className="text-white">{pendingExpense.description}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-400">Amount:</span>
                      <span className="text-red-400">${pendingExpense.amount.toLocaleString()}</span>
                    </div>
                  </div>
                </div>
                <div className="bg-primary-500/10 border border-primary-500 rounded-lg p-4">
                  <p className="text-sm text-gray-300 mb-2">Your new Current Remaining will be:</p>
                  <p className="text-2xl font-bold text-green-400">
                    ${(budget.semesterBudget - pendingExpense.amount).toLocaleString()}
                  </p>
                  <p className="text-xs text-gray-400 mt-1">
                    (was ${budget.semesterBudget.toLocaleString()})
                  </p>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => {
                      handleAddExpense(pendingExpense);
                      // Also update the budget's remaining amount
                      if (budget) {
                        const updatedBudget: Budget = {
                          ...budget,
                          semesterBudget: budget.semesterBudget - pendingExpense.amount,
                        };
                        storage.saveBudget(updatedBudget);
                      }
                    }}
                    disabled={isSaving}
                    className="flex-1 px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isSaving ? 'Saving...' : 'Yes, Add Expense'}
                  </button>
                  <button
                    onClick={() => {
                      setShowExpenseConfirm(false);
                      setPendingExpense(null);
                    }}
                    disabled={isSaving}
                    className="flex-1 px-4 py-2 bg-slate-600 hover:bg-slate-700 text-white rounded-lg transition-colors disabled:opacity-50"
                  >
                    Go Back
                  </button>
                </div>
              </div>
            )}

            {/* Update Balance Tab */}
            {expenseModalTab === 'balance' && !showBalanceConfirm && budget && (
              <div className="space-y-4">
                <div className="bg-slate-700 rounded-lg p-4">
                  <p className="text-sm text-gray-400 mb-1">Current Remaining</p>
                  <p className="text-xl font-bold text-green-400">
                    ${budget.semesterBudget.toLocaleString()}
                  </p>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">
                    New Remaining Amount ($)
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    value={newBalanceAmount}
                    onChange={(e) => setNewBalanceAmount(e.target.value)}
                    className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                    placeholder="Enter your new balance"
                  />
                  <p className="text-xs text-gray-500 mt-1">
                    Enter how much you currently have available
                  </p>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={handleUpdateBalance}
                    disabled={!newBalanceAmount || isSaving}
                    className="flex-1 px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    Update Balance
                  </button>
                  <button
                    onClick={() => setShowExpenseModal(false)}
                    disabled={isSaving}
                    className="flex-1 px-4 py-2 bg-slate-600 hover:bg-slate-700 text-white rounded-lg transition-colors disabled:opacity-50"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            )}

            {/* Balance Update Confirmation */}
            {expenseModalTab === 'balance' && showBalanceConfirm && budget && newBalanceAmount && (
              <div className="space-y-4">
                {(() => {
                  const newBalance = parseFloat(newBalanceAmount);
                  const difference = budget.semesterBudget - newBalance;
                  return (
                    <>
                      <div className="bg-slate-700 rounded-lg p-4">
                        <div className="grid grid-cols-2 gap-4">
                          <div>
                            <p className="text-sm text-gray-400 mb-1">Old Balance</p>
                            <p className="text-lg font-bold text-white">
                              ${budget.semesterBudget.toLocaleString()}
                            </p>
                          </div>
                          <div>
                            <p className="text-sm text-gray-400 mb-1">New Balance</p>
                            <p className="text-lg font-bold text-green-400">
                              ${newBalance.toLocaleString()}
                            </p>
                          </div>
                        </div>
                      </div>
                      {difference > 0 ? (
                        <div className="bg-yellow-500/10 border border-yellow-500 rounded-lg p-4">
                          <p className="text-sm text-gray-300 mb-2">
                            Your balance decreased by <span className="text-red-400 font-bold">${difference.toLocaleString()}</span>
                          </p>
                          <p className="text-sm text-gray-400">
                            Do you want to add ${difference.toLocaleString()} to your Spent/Prepaid total?
                          </p>
                        </div>
                      ) : difference < 0 ? (
                        <div className="bg-green-500/10 border border-green-500 rounded-lg p-4">
                          <p className="text-sm text-gray-300">
                            Your balance increased by <span className="text-green-400 font-bold">${Math.abs(difference).toLocaleString()}</span>
                          </p>
                        </div>
                      ) : (
                        <div className="bg-slate-700 rounded-lg p-4">
                          <p className="text-sm text-gray-300">Balance unchanged</p>
                        </div>
                      )}
                      <div className="flex gap-2">
                        <button
                          onClick={confirmUpdateBalance}
                          disabled={isSaving}
                          className="flex-1 px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                          {isSaving ? 'Saving...' : 'Yes, Update Balance'}
                        </button>
                        <button
                          onClick={() => setShowBalanceConfirm(false)}
                          disabled={isSaving}
                          className="flex-1 px-4 py-2 bg-slate-600 hover:bg-slate-700 text-white rounded-lg transition-colors disabled:opacity-50"
                        >
                          Go Back
                        </button>
                      </div>
                    </>
                  );
                })()}
              </div>
            )}
          </div>
        </div>
      )}
        </>
      )}
    </div>
  );
}
