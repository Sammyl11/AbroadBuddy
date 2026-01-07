import { useState, useEffect } from 'react';
import { 
  format, 
  startOfMonth, 
  endOfMonth, 
  eachDayOfInterval, 
  isSameMonth, 
  isSameDay,
  parseISO,
  startOfDay,
  addMonths,
  subMonths,
  addWeeks,
  subWeeks,
  addDays,
  startOfWeek,
  differenceInDays,
  isAfter,
  isBefore,
  isToday
} from 'date-fns';
import { ChevronLeft, ChevronRight, Heart, X, Plus, Trash2 } from 'lucide-react';
import { useData } from '../contexts/DataContext';
import { Trip, WeeklyPlan, WeeklyPlanEvent } from '../types';
import { storage } from '../utils/supabaseStorage';

export default function CalendarView() {
  const { budget, trips, wishlist, expenses, loading } = useData();
  const [currentDate, setCurrentDate] = useState(new Date());
  const [selectedDay, setSelectedDay] = useState<Date | null>(null);
  const [includeWishlist, setIncludeWishlist] = useState(false);
  
  // Weekly planner state
  const [selectedWeek, setSelectedWeek] = useState(() => startOfWeek(new Date(), { weekStartsOn: 1 }));
  const [weeklyPlan, setWeeklyPlan] = useState<WeeklyPlan | null>(null);
  const [loadingPlan, setLoadingPlan] = useState(false);
  const [showAddEventModal, setShowAddEventModal] = useState(false);
  const [newEventDay, setNewEventDay] = useState<number>(0);
  const [newEventName, setNewEventName] = useState('');
  const [newEventAmount, setNewEventAmount] = useState('');

  // Load weekly plan when selected week changes
  useEffect(() => {
    const loadWeeklyPlan = async () => {
      setLoadingPlan(true);
      try {
        const weekStart = format(selectedWeek, 'yyyy-MM-dd');
        const plan = await storage.getWeeklyPlan(weekStart);
        setWeeklyPlan(plan);
        
        // Also update the cache
        if (plan) {
          setWeeklyPlansCache(prev => new Map(prev).set(weekStart, plan));
        }
      } catch (error) {
        console.error('Error loading weekly plan:', error);
      } finally {
        setLoadingPlan(false);
      }
    };
    
    loadWeeklyPlan();
  }, [selectedWeek]);

  const handlePreviousWeek = () => {
    setSelectedWeek(subWeeks(selectedWeek, 1));
  };

  const handleNextWeek = () => {
    setSelectedWeek(addWeeks(selectedWeek, 1));
  };

  const handleAddEvent = async () => {
    if (!newEventName.trim()) return;
    
    try {
      const weekStart = format(selectedWeek, 'yyyy-MM-dd');
      
      // Create or get the plan for this week
      let plan = weeklyPlan;
      if (!plan) {
        plan = await storage.createOrGetWeeklyPlan(weekStart);
      }
      
      // Add the event
      const newEvent = await storage.addWeeklyPlanEvent(plan.id, {
        dayOfWeek: newEventDay,
        eventName: newEventName.trim(),
        amount: parseFloat(newEventAmount) || 0,
      });
      
      // Update local state
      const updatedPlan = {
        ...plan,
        events: [...plan.events, newEvent],
      };
      setWeeklyPlan(updatedPlan);
      
      // Update cache
      setWeeklyPlansCache(prev => new Map(prev).set(weekStart, updatedPlan));
      
      // Reset form and close modal
      setNewEventDay(0);
      setNewEventName('');
      setNewEventAmount('');
      setShowAddEventModal(false);
    } catch (error) {
      console.error('Error adding event:', error);
      alert('Error adding event. Please try again.');
    }
  };

  const handleDeleteEvent = async (eventId: string) => {
    if (!weeklyPlan) return;
    
    try {
      await storage.deleteWeeklyPlanEvent(eventId);
      
      // Update local state
      const updatedPlan = {
        ...weeklyPlan,
        events: weeklyPlan.events.filter(e => e.id !== eventId),
      };
      setWeeklyPlan(updatedPlan);
      
      // Update cache
      const weekStart = format(selectedWeek, 'yyyy-MM-dd');
      setWeeklyPlansCache(prev => new Map(prev).set(weekStart, updatedPlan));
    } catch (error) {
      console.error('Error deleting event:', error);
      alert('Error deleting event. Please try again.');
    }
  };

  const getEventsForDay = (dayOfWeek: number): WeeklyPlanEvent[] => {
    if (!weeklyPlan) return [];
    return weeklyPlan.events.filter(e => e.dayOfWeek === dayOfWeek);
  };

  const getDayTotal = (dayOfWeek: number): number => {
    return getEventsForDay(dayOfWeek).reduce((sum, e) => sum + e.amount, 0);
  };

  const getWeekTotal = (): number => {
    if (!weeklyPlan) return 0;
    return weeklyPlan.events.reduce((sum, e) => sum + e.amount, 0);
  };

  // State to store weekly plans for different weeks (cache)
  const [weeklyPlansCache, setWeeklyPlansCache] = useState<Map<string, WeeklyPlan | null>>(new Map());

  // Calculate allocated amount for a specific day (expenses + weekly plan events)
  const getAllocatedForDay = (date: Date): number => {
    let total = 0;
    
    // Add expenses for this date
    const dateStr = format(date, 'yyyy-MM-dd');
    const dayExpenses = expenses.filter(e => e.date === dateStr);
    total += dayExpenses.reduce((sum, e) => sum + e.amount, 0);
    
    // Add weekly plan events for this day
    const dayOfWeek = (date.getDay() + 6) % 7; // Convert to 0=Mon, 6=Sun
    const dateWeekStart = startOfWeek(date, { weekStartsOn: 1 });
    const weekStartStr = format(dateWeekStart, 'yyyy-MM-dd');
    
    // Check if this week's plan is in cache
    const cachedPlan = weeklyPlansCache.get(weekStartStr);
    if (cachedPlan) {
      const dayEvents = cachedPlan.events.filter(e => e.dayOfWeek === dayOfWeek);
      total += dayEvents.reduce((sum, e) => sum + e.amount, 0);
    } else if (format(dateWeekStart, 'yyyy-MM-dd') === format(selectedWeek, 'yyyy-MM-dd') && weeklyPlan) {
      // Use currently loaded weekly plan if it matches
      const dayEvents = weeklyPlan.events.filter(e => e.dayOfWeek === dayOfWeek);
      total += dayEvents.reduce((sum, e) => sum + e.amount, 0);
    } else {
      // Load this week's plan asynchronously and cache it
      storage.getWeeklyPlan(weekStartStr).then(plan => {
        if (plan) {
          setWeeklyPlansCache(prev => new Map(prev).set(weekStartStr, plan));
        }
      }).catch(err => console.error('Error loading weekly plan for day:', err));
    }
    
    return total;
  };

  if (loading) {
    return (
      <div className="bg-slate-800 rounded-lg p-6 shadow-lg text-center">
        <p className="text-gray-400">Loading...</p>
      </div>
    );
  }

  if (!budget) {
    return (
      <div className="bg-slate-800 rounded-lg p-6 shadow-lg text-center">
        <p className="text-gray-400">Please set up your budget first to view the calendar.</p>
      </div>
    );
  }

  const budgetStart = parseISO(budget.startDate);
  const budgetEnd = parseISO(budget.endDate);
  
  // Calculate wishlist total cost
  const wishlistTotal = wishlist.reduce((sum, item) => sum + item.estimatedCost, 0);
  
  // Calculate trip costs
  const totalPlanned = trips.reduce((sum, trip) => sum + trip.plannedCost, 0);
  
  // Calculate remaining budget with/without wishlist
  // For tracking mode, there's no budget limit, so we show 0
  const totalSpent = budget.spent;
  const hasLimit = budget.budgetMode !== 'tracking' && budget.semesterBudget > 0;
  
  // For "remaining" mode: semesterBudget is what user currently has, don't subtract spent
  // For "total" mode: semesterBudget is total budget, subtract both spent and planned
  let remainingBudget = 0;
  let remainingBudgetWithWishlist = 0;
  
  if (hasLimit) {
    if (budget.budgetMode === 'remaining') {
      // In remaining mode, semesterBudget IS the current remaining, only subtract planned
      remainingBudget = budget.semesterBudget - totalPlanned;
      remainingBudgetWithWishlist = budget.semesterBudget - totalPlanned - wishlistTotal;
    } else {
      // In total mode, subtract both spent and planned
      remainingBudget = budget.semesterBudget - totalSpent - totalPlanned;
      remainingBudgetWithWishlist = budget.semesterBudget - totalSpent - totalPlanned - wishlistTotal;
    }
  }

  // Calculate remaining days in the budget period
  const today = startOfDay(new Date());
  let remainingDays = 1;
  
  if (isBefore(today, budgetStart)) {
    // Budget hasn't started yet
    remainingDays = differenceInDays(budgetEnd, budgetStart) + 1;
  } else if (isAfter(today, budgetEnd)) {
    // Budget period has ended
    remainingDays = 1;
  } else {
    // We're within the budget period - count days from today to end
    remainingDays = differenceInDays(budgetEnd, today) + 1;
  }

  // Calculate daily budget: divide remaining budget evenly across remaining days
  // For tracking mode, show 0 since there's no limit
  const dailyBudget = hasLimit ? remainingBudget / remainingDays : 0;
  const dailyBudgetWithWishlist = hasLimit ? remainingBudgetWithWishlist / remainingDays : 0;
  
  // Calculate weekly budget
  const weeklyBudget = dailyBudget * 7;
  const weeklyBudgetWithWishlist = dailyBudgetWithWishlist * 7;

  // Get all days in the current month view
  const monthStart = startOfMonth(currentDate);
  const monthEnd = endOfMonth(currentDate);
  const daysInMonth = eachDayOfInterval({ start: monthStart, end: monthEnd });

  // Get first day of week for the month (to pad the calendar)
  const firstDayOfWeek = monthStart.getDay();
  const paddedDays = Array(firstDayOfWeek === 0 ? 6 : firstDayOfWeek - 1).fill(null);

  // Check if a date is within a trip
  const isDateInTrip = (date: Date): Trip | null => {
    const dateStart = startOfDay(date);
    for (const trip of trips) {
      const tripStart = startOfDay(parseISO(trip.startDate));
      const tripEnd = startOfDay(parseISO(trip.endDate));
      
      if (dateStart >= tripStart && dateStart <= tripEnd) {
        return trip;
      }
    }
    return null;
  };

  // Check if date is within budget period
  const isDateInBudgetPeriod = (date: Date): boolean => {
    const dateStart = startOfDay(date);
    return dateStart >= startOfDay(budgetStart) && dateStart <= startOfDay(budgetEnd);
  };

  const previousMonth = () => {
    setCurrentDate(subMonths(currentDate, 1));
  };

  const nextMonth = () => {
    setCurrentDate(addMonths(currentDate, 1));
  };

  const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Get info for selected day
  const getSelectedDayInfo = () => {
    if (!selectedDay) return null;
    
    const trip = isDateInTrip(selectedDay);
    const inBudgetPeriod = isDateInBudgetPeriod(selectedDay);
    const isFutureDay = isAfter(selectedDay, today) || isSameDay(selectedDay, today);
    
    return { trip, inBudgetPeriod, isFutureDay };
  };

  const selectedDayInfo = getSelectedDayInfo();

  return (
    <div className="bg-slate-800 rounded-lg p-6 shadow-lg">
      <div className="flex items-center gap-4 mb-6">
        <button
          onClick={previousMonth}
          className="p-2 hover:bg-slate-700 rounded-lg transition-colors"
        >
          <ChevronLeft className="w-5 h-5 text-white" />
        </button>
        <h2 className="text-xl sm:text-2xl font-bold text-white">
          {format(currentDate, 'MMMM yyyy')}
        </h2>
        <button
          onClick={nextMonth}
          className="p-2 hover:bg-slate-700 rounded-lg transition-colors"
        >
          <ChevronRight className="w-5 h-5 text-white" />
        </button>
      </div>

      {/* Summary */}
      <div className="mb-6 pb-6 border-b border-slate-700">
        {budget.budgetMode === 'tracking' ? (
          /* Tracking mode - show spending summary */
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-slate-700 rounded-lg p-4">
              <div className="text-sm text-gray-400 mb-1">Total Spent</div>
              <div className="text-2xl font-bold text-red-400">
                ${totalSpent.toFixed(2)}
              </div>
            </div>
            <div className="bg-slate-700 rounded-lg p-4">
              <div className="text-sm text-gray-400 mb-1">Planned Spending</div>
              <div className="text-2xl font-bold text-yellow-400">
                ${totalPlanned.toFixed(2)}
              </div>
            </div>
            <div className="bg-slate-700 rounded-lg p-4">
              <div className="text-sm text-gray-400 mb-1">Remaining Days</div>
              <div className="text-2xl font-bold text-white">
                {remainingDays}
              </div>
            </div>
          </div>
        ) : (
          /* Budget mode - show remaining and daily/weekly budgets */
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-slate-700 rounded-lg p-4">
              <div className="text-sm text-gray-400 mb-1">
                {budget.budgetMode === 'remaining' ? 'Balance After Planned Trips' : 'Available Budget'}
              </div>
              <div className={`text-2xl font-bold ${
                (includeWishlist ? remainingBudgetWithWishlist : remainingBudget) >= 0 
                  ? 'text-white' 
                  : 'text-red-400'
              }`}>
                ${(includeWishlist ? remainingBudgetWithWishlist : remainingBudget).toFixed(2)}
              </div>
              <div className="text-xs text-gray-400 mt-1">
                {budget.budgetMode === 'remaining' ? 'Remaining - Planned' : 'After spent + planned'}
              </div>
            </div>
            <div className="bg-slate-700 rounded-lg p-4">
              <div className="text-sm text-gray-400 mb-1">Remaining Days</div>
              <div className="text-2xl font-bold text-white">
                {remainingDays}
              </div>
            </div>
            <div className="bg-slate-700 rounded-lg p-4">
              <div className="flex items-center justify-between mb-1">
                <div className="text-sm text-gray-400">Budget</div>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={includeWishlist}
                    onChange={(e) => setIncludeWishlist(e.target.checked)}
                    className="w-4 h-4 text-primary-600 bg-slate-600 border-slate-500 rounded focus:ring-primary-500"
                  />
                  <span className="text-xs text-gray-300 flex items-center gap-1">
                    <Heart className="w-3 h-3" />
                    Wishlist
                  </span>
                </label>
              </div>
              <div className="space-y-1">
                <div className="flex items-center gap-2">
                  <span className={`text-xl font-bold ${
                    (includeWishlist ? dailyBudgetWithWishlist : dailyBudget) >= 0 
                      ? 'text-green-400' 
                      : 'text-red-400'
                  }`}>
                    ${(includeWishlist ? dailyBudgetWithWishlist : dailyBudget).toFixed(2)}
                  </span>
                  <span className="text-sm text-gray-400">/ day</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className={`text-xl font-bold ${
                    (includeWishlist ? weeklyBudgetWithWishlist : weeklyBudget) >= 0 
                      ? 'text-blue-400' 
                      : 'text-red-400'
                  }`}>
                    ${(includeWishlist ? weeklyBudgetWithWishlist : weeklyBudget).toFixed(2)}
                  </span>
                  <span className="text-sm text-gray-400">/ week</span>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Selected Day Info Box */}
      {selectedDay ? (
        <div className="mb-6 bg-slate-700 rounded-lg px-4 py-3 flex items-center justify-between">
          <div>
            <div className="text-sm text-gray-400">{format(selectedDay, 'EEEE, MMM d')}</div>
            {selectedDayInfo?.trip ? (
              <div className="text-lg font-bold text-primary-400">{selectedDayInfo.trip.name}</div>
            ) : selectedDayInfo?.inBudgetPeriod && selectedDayInfo?.isFutureDay ? (
              (() => {
                const allocated = getAllocatedForDay(selectedDay);
                const budget = (includeWishlist ? dailyBudgetWithWishlist : dailyBudget);
                
                return (
                  <div className="flex items-center gap-2">
                    <span className={`text-lg font-bold ${allocated > 0 ? 'text-yellow-400' : 'text-green-400'}`}>
                      {allocated > 0 ? `$${allocated.toFixed(2)}/$${budget.toFixed(2)}` : `$${budget.toFixed(2)}`}
                    </span>
                    <span className="text-sm text-gray-400">daily budget</span>
                  </div>
                );
              })()
            ) : selectedDayInfo?.inBudgetPeriod ? (
              <div className="text-lg font-bold text-gray-400">Past day</div>
            ) : (
              <div className="text-lg font-bold text-gray-500">Outside budget period</div>
            )}
          </div>
          <button
            onClick={() => setSelectedDay(null)}
            className="p-1 hover:bg-slate-600 rounded transition-colors"
          >
            <X className="w-4 h-4 text-gray-400" />
          </button>
        </div>
      ) : (
        <div className="mb-6 text-gray-400 text-sm">
          Click a day to see details
        </div>
      )}

      {/* Legend */}
      <div className="flex items-center gap-6 mb-4 text-sm">
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-slate-700 rounded"></div>
          <span className="text-gray-300">Open Day</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-primary-500 rounded"></div>
          <span className="text-gray-300">Trip Day</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-slate-600 border-2 border-slate-400 rounded"></div>
          <span className="text-gray-300">Outside Budget Period</span>
        </div>
      </div>

      {/* Calendar Grid */}
      <div className="grid grid-cols-7 gap-2">
        {/* Week day headers */}
        {weekDays.map((day) => (
          <div
            key={day}
            className="text-center text-sm font-semibold text-gray-400 py-2"
          >
            {day}
          </div>
        ))}

        {/* Padding for first week */}
        {paddedDays.map((_, index) => (
          <div key={`pad-${index}`} className="aspect-square"></div>
        ))}

        {/* Calendar days */}
        {daysInMonth.map((day) => {
          const trip = isDateInTrip(day);
          const inBudgetPeriod = isDateInBudgetPeriod(day);
          const isCurrentDay = isToday(day);
          const isCurrentMonth = isSameMonth(day, currentDate);
          const isSelected = selectedDay && isSameDay(day, selectedDay);

          return (
            <button
              key={day.toISOString()}
              onClick={() => setSelectedDay(day)}
              className={`
                aspect-square rounded-lg p-2 border-2 transition-all cursor-pointer
                ${trip 
                  ? 'bg-primary-500 border-primary-400 hover:bg-primary-400' 
                  : inBudgetPeriod 
                    ? 'bg-slate-700 border-slate-600 hover:border-slate-500 hover:bg-slate-650' 
                    : 'bg-slate-600 border-slate-500 opacity-50 hover:opacity-70'
                }
                ${isCurrentDay ? 'ring-2 ring-yellow-400 ring-offset-2 ring-offset-slate-800' : ''}
                ${isSelected ? 'ring-2 ring-white ring-offset-1 ring-offset-slate-800' : ''}
                ${!isCurrentMonth ? 'opacity-30' : ''}
              `}
            >
              <div className="flex flex-col h-full">
                <div className={`text-sm font-semibold ${isCurrentDay ? 'text-yellow-400' : trip ? 'text-white' : 'text-gray-300'}`}>
                  {format(day, 'd')}
                </div>
                {trip && (
                  <div className="mt-auto text-xs text-white truncate" title={trip.name}>
                    {trip.name}
                  </div>
                )}
              </div>
            </button>
          );
        })}
      </div>

      {/* Weekly Budget Planner */}
      <div className="mt-6 pt-6 border-t border-slate-700">
        {/* Week Selector */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
          <div className="flex flex-col sm:flex-row sm:items-center gap-3 w-full sm:w-auto">
            <div>
              <h3 className="text-lg font-bold text-white">Weekly Budget Planner</h3>
              <p className="text-xs text-gray-400">Plan out your week - this won't affect your actual budget</p>
            </div>
            <div className="flex items-center gap-2 bg-slate-700 rounded-lg px-3 py-2 w-full sm:w-auto justify-center">
              <button
                onClick={handlePreviousWeek}
                className="p-2 hover:bg-slate-600 rounded-lg transition-colors"
              >
                <ChevronLeft className="w-5 h-5 text-white" />
              </button>
              <div className="text-white font-medium text-sm sm:text-base text-center flex-1 sm:flex-initial">
                {format(selectedWeek, 'MMM d')} - {format(addDays(selectedWeek, 6), 'MMM d, yyyy')}
              </div>
              <button
                onClick={handleNextWeek}
                className="p-2 hover:bg-slate-600 rounded-lg transition-colors"
              >
                <ChevronRight className="w-5 h-5 text-white" />
              </button>
            </div>
          </div>
          <button
            onClick={() => setShowAddEventModal(true)}
            className="w-full sm:w-auto px-3 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors flex items-center justify-center gap-2 text-sm"
          >
            <Plus className="w-4 h-4" />
            Add Event
          </button>
        </div>

        {loadingPlan ? (
          <div className="text-center py-8">
            <p className="text-gray-400">Loading week plan...</p>
          </div>
        ) : (
          <>
            {/* Days Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-3">
              {weekDays.map((day, index) => {
                const dayEvents = getEventsForDay(index);
                const dayTotal = getDayTotal(index);
                
                return (
                  <div key={day} className="bg-slate-700 rounded-lg p-3 min-h-[120px] flex flex-col">
                    <div className="flex items-center justify-between mb-2">
                      <div className="text-sm font-semibold text-gray-300">{day}</div>
                      {dayTotal > 0 && (
                        <div className="text-xs font-bold text-yellow-400">${dayTotal.toFixed(0)}</div>
                      )}
                    </div>
                    
                    {/* Events List */}
                    <div className="flex-1 space-y-1">
                      {dayEvents.length === 0 ? (
                        <div className="text-xs text-gray-500 italic">No events</div>
                      ) : (
                        dayEvents.map((event) => (
                          <div 
                            key={event.id} 
                            className="bg-slate-600 rounded px-2 py-1 flex items-center justify-between group"
                          >
                            <div className="flex-1 min-w-0">
                              <div className="text-xs text-white truncate">{event.eventName}</div>
                              {event.amount > 0 && (
                                <div className="text-xs text-green-400">${event.amount.toFixed(0)}</div>
                              )}
                            </div>
                            <button
                              onClick={() => handleDeleteEvent(event.id)}
                              className="p-1 text-gray-400 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity"
                            >
                              <Trash2 className="w-3 h-3" />
                            </button>
                          </div>
                        ))
                      )}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Week Plan Summary */}
            {(() => {
              const plannedTotal = getWeekTotal();
              const actualWeeklyBudget = includeWishlist ? weeklyBudgetWithWishlist : weeklyBudget;
              const difference = actualWeeklyBudget - plannedTotal;
              
              return (
                <div className="mt-4 grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div className="bg-slate-700 rounded-lg p-3">
                    <div className="text-xs text-gray-400 mb-1">Planned This Week</div>
                    <div className="text-xl font-bold text-yellow-400">
                      ${plannedTotal.toFixed(2)}
                    </div>
                    <div className="text-xs text-gray-500 mt-1">
                      {weeklyPlan?.events.length || 0} events
                    </div>
                  </div>
                  <div className="bg-slate-700 rounded-lg p-3">
                    <div className="text-xs text-gray-400 mb-1">Weekly Budget</div>
                    <div className={`text-xl font-bold ${actualWeeklyBudget >= 0 ? 'text-blue-400' : 'text-red-400'}`}>
                      ${actualWeeklyBudget.toFixed(2)}
                    </div>
                  </div>
                  <div className="bg-slate-700 rounded-lg p-3">
                    <div className="text-xs text-gray-400 mb-1">
                      {difference >= 0 ? 'Under Budget' : 'Over Budget'}
                    </div>
                    <div className={`text-xl font-bold ${difference >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                      ${Math.abs(difference).toFixed(2)}
                    </div>
                  </div>
                </div>
              );
            })()}
          </>
        )}
      </div>

      {/* Add Event Modal */}
      {showAddEventModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-slate-800 rounded-lg p-6 max-w-md w-full">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-xl font-bold text-white">Add Event</h3>
              <button
                onClick={() => {
                  setShowAddEventModal(false);
                  setNewEventName('');
                  setNewEventAmount('');
                  setNewEventDay(0);
                }}
                className="p-2 text-gray-400 hover:text-white hover:bg-slate-700 rounded transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Day
                </label>
                <select
                  value={newEventDay}
                  onChange={(e) => setNewEventDay(parseInt(e.target.value))}
                  className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                >
                  {weekDays.map((day, index) => (
                    <option key={day} value={index}>
                      {day} ({format(addDays(selectedWeek, index), 'MMM d')})
                    </option>
                  ))}
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Event Name *
                </label>
                <input
                  type="text"
                  value={newEventName}
                  onChange={(e) => setNewEventName(e.target.value)}
                  className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                  placeholder="e.g., Dinner with friends, Movie night"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Amount ($)
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={newEventAmount}
                  onChange={(e) => setNewEventAmount(e.target.value)}
                  className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                  placeholder="0.00"
                />
              </div>
              
              <div className="flex gap-2 pt-2">
                <button
                  onClick={handleAddEvent}
                  disabled={!newEventName.trim()}
                  className="flex-1 px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Add Event
                </button>
                <button
                  onClick={() => {
                    setShowAddEventModal(false);
                    setNewEventName('');
                    setNewEventAmount('');
                    setNewEventDay(0);
                  }}
                  className="flex-1 px-4 py-2 bg-slate-600 hover:bg-slate-700 text-white rounded-lg transition-colors"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

