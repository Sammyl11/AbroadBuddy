import { useState, useEffect } from 'react';
import { Budget, WishlistItem } from '../types';
import { storage } from '../utils/supabaseStorage';
import { DollarSign, Calendar, TrendingUp, Heart } from 'lucide-react';

export default function BudgetManager() {
  const [budget, setBudget] = useState<Budget | null>(null);
  const [wishlist, setWishlist] = useState<WishlistItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [semesterBudget, setSemesterBudget] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [isEditing, setIsEditing] = useState(false);
  const [includeWishlist, setIncludeWishlist] = useState(false);

  useEffect(() => {
    const loadData = async () => {
      try {
        setLoading(true);
        const [savedBudget, savedWishlist] = await Promise.all([
          storage.getBudget(),
          storage.getWishlist(),
        ]);
        
        if (savedBudget) {
          // Recalculate spent amount to ensure accuracy
          const totalSpent = await storage.calculateTotalSpent();
          const updatedBudget = { ...savedBudget, spent: totalSpent };
          await storage.saveBudget(updatedBudget);
          
          setBudget(updatedBudget);
          setSemesterBudget(updatedBudget.semesterBudget.toString());
          setStartDate(updatedBudget.startDate);
          setEndDate(updatedBudget.endDate);
        } else {
          setIsEditing(true);
        }
        
        setWishlist(savedWishlist);
      } catch (error) {
        console.error('Error loading data:', error);
      } finally {
        setLoading(false);
      }
    };
    
    loadData();
  }, []);

  const handleSave = async () => {
    if (!semesterBudget || !startDate || !endDate) {
      alert('Please fill in all fields');
      return;
    }

    try {
      const newBudget: Budget = {
        semesterBudget: parseFloat(semesterBudget),
        startDate,
        endDate,
        spent: budget?.spent || 0,
      };

      await storage.saveBudget(newBudget);
      setBudget(newBudget);
      setIsEditing(false);
    } catch (error: any) {
      alert('Error saving budget: ' + (error.message || 'Unknown error'));
    }
  };

  const handleCancel = () => {
    if (budget) {
      setSemesterBudget(budget.semesterBudget.toString());
      setStartDate(budget.startDate);
      setEndDate(budget.endDate);
      setIsEditing(false);
    }
  };

  if (!budget && !isEditing) {
    return null;
  }

  // Calculate wishlist total cost
  const wishlistTotal = wishlist.reduce((sum, item) => sum + item.estimatedCost, 0);
  
  // Calculate budget with/without wishlist
  const totalSpent = budget ? budget.spent : 0;
  const totalSpentWithWishlist = totalSpent + wishlistTotal;
  const remaining = budget ? budget.semesterBudget - totalSpent : 0;
  const remainingWithWishlist = budget ? budget.semesterBudget - totalSpentWithWishlist : 0;
  const percentageUsed = budget ? (totalSpent / budget.semesterBudget) * 100 : 0;
  const percentageUsedWithWishlist = budget ? (totalSpentWithWishlist / budget.semesterBudget) * 100 : 0;

  return (
    <div className="bg-slate-800 rounded-lg p-6 shadow-lg">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-2xl font-bold text-white flex items-center gap-2">
          <DollarSign className="w-6 h-6 text-primary-400" />
          Budget Overview
        </h2>
        {!isEditing && (
          <button
            onClick={() => setIsEditing(true)}
            className="px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors"
          >
            Edit
          </button>
        )}
      </div>

      {isEditing ? (
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
              onClick={handleSave}
              className="flex-1 px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors"
            >
              Save
            </button>
            {budget && (
              <button
                onClick={handleCancel}
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
  );
}

