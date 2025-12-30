import { useState, useEffect } from 'react';
import { Budget, Trip } from '../types';
import { storage } from '../utils/localStorage';
import { 
  format, 
  startOfMonth, 
  endOfMonth, 
  eachDayOfInterval, 
  isSameMonth, 
  isSameDay,
  parseISO,
  isWithinInterval,
  startOfDay,
  addMonths,
  subMonths,
  differenceInDays,
  isAfter,
  isBefore,
  isToday
} from 'date-fns';
import { ChevronLeft, ChevronRight, DollarSign } from 'lucide-react';

export default function CalendarView() {
  const [currentDate, setCurrentDate] = useState(new Date());
  const [budget, setBudget] = useState<Budget | null>(null);
  const [trips, setTrips] = useState<Trip[]>([]);
  const [showDailyBudget, setShowDailyBudget] = useState(false);

  useEffect(() => {
    const loadData = () => {
      setBudget(storage.getBudget());
      setTrips(storage.getTrips());
    };
    loadData();
    
    const interval = setInterval(loadData, 1000);
    return () => clearInterval(interval);
  }, []);

  if (!budget) {
    return (
      <div className="bg-slate-800 rounded-lg p-6 shadow-lg text-center">
        <p className="text-gray-400">Please set up your budget first to view the calendar.</p>
      </div>
    );
  }

  const budgetStart = parseISO(budget.startDate);
  const budgetEnd = parseISO(budget.endDate);
  const remainingBudget = budget.semesterBudget - budget.spent;

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
  const dailyBudget = remainingBudget / remainingDays;

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

  return (
    <div className="bg-slate-800 rounded-lg p-6 shadow-lg">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-4">
          <button
            onClick={previousMonth}
            className="p-2 hover:bg-slate-700 rounded-lg transition-colors"
          >
            <ChevronLeft className="w-5 h-5 text-white" />
          </button>
          <h2 className="text-2xl font-bold text-white">
            {format(currentDate, 'MMMM yyyy')}
          </h2>
          <button
            onClick={nextMonth}
            className="p-2 hover:bg-slate-700 rounded-lg transition-colors"
          >
            <ChevronRight className="w-5 h-5 text-white" />
          </button>
        </div>
        <div className="flex items-center gap-4">
          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={showDailyBudget}
              onChange={(e) => setShowDailyBudget(e.target.checked)}
              className="w-4 h-4 text-primary-600 bg-slate-700 border-slate-600 rounded focus:ring-primary-500"
            />
            <span className="text-gray-300 flex items-center gap-2">
              <DollarSign className="w-4 h-4" />
              Show Daily Budget
            </span>
          </label>
        </div>
      </div>

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
          const isFutureDay = isAfter(day, today) || isCurrentDay;

          return (
            <div
              key={day.toISOString()}
              className={`
                aspect-square rounded-lg p-2 border-2 transition-all
                ${trip 
                  ? 'bg-primary-500 border-primary-400' 
                  : inBudgetPeriod 
                    ? 'bg-slate-700 border-slate-600 hover:border-slate-500' 
                    : 'bg-slate-600 border-slate-500 opacity-50'
                }
                ${isCurrentDay ? 'ring-2 ring-yellow-400 ring-offset-2 ring-offset-slate-800' : ''}
                ${!isCurrentMonth ? 'opacity-30' : ''}
              `}
            >
              <div className="flex flex-col h-full">
                <div className={`text-sm font-semibold ${isCurrentDay ? 'text-yellow-400' : trip ? 'text-white' : 'text-gray-300'}`}>
                  {format(day, 'd')}
                </div>
                {showDailyBudget && inBudgetPeriod && !trip && isFutureDay && (
                  <div className="mt-auto text-xs text-green-400 font-medium">
                    ${dailyBudget.toFixed(0)}
                  </div>
                )}
                {trip && (
                  <div className="mt-auto text-xs text-white truncate" title={trip.name}>
                    {trip.name}
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Summary */}
      <div className="mt-6 pt-6 border-t border-slate-700">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-slate-700 rounded-lg p-4">
            <div className="text-sm text-gray-400 mb-1">Remaining Budget</div>
            <div className="text-2xl font-bold text-white">
              ${remainingBudget.toFixed(2)}
            </div>
          </div>
          <div className="bg-slate-700 rounded-lg p-4">
            <div className="text-sm text-gray-400 mb-1">Remaining Days</div>
            <div className="text-2xl font-bold text-white">
              {remainingDays}
            </div>
          </div>
          <div className="bg-slate-700 rounded-lg p-4">
            <div className="text-sm text-gray-400 mb-1">Daily Budget</div>
            <div className="text-2xl font-bold text-green-400">
              ${dailyBudget.toFixed(2)}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

