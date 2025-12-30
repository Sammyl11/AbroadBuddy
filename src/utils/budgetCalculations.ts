import { Budget, Trip, WeeklyBudget, Expense } from '../types';
import { format, startOfWeek, endOfWeek, eachWeekOfInterval, isWithinInterval, parseISO, addWeeks } from 'date-fns';

export const calculateWeeklyBudgets = (budget: Budget, trips: Trip[], expenses: Expense[] = []): WeeklyBudget[] => {
  if (!budget.startDate || !budget.endDate) return [];

  const start = parseISO(budget.startDate);
  const end = parseISO(budget.endDate);
  const weeks = eachWeekOfInterval({ start, end }, { weekStartsOn: 1 });

  const totalWeeks = weeks.length;
  const weeklyBudgetAmount = budget.semesterBudget / totalWeeks;

  return weeks.map((weekStart, index) => {
    const weekEnd = endOfWeek(weekStart, { weekStartsOn: 1 });
    const weekKey = format(weekStart, 'yyyy-MM-dd');

    // Calculate spending for trips in this week
    const tripSpent = trips.reduce((sum, trip) => {
      const tripStart = parseISO(trip.startDate);
      const tripEnd = parseISO(trip.endDate);
      
      // Check if trip overlaps with this week
      if (
        isWithinInterval(tripStart, { start: weekStart, end: weekEnd }) ||
        isWithinInterval(tripEnd, { start: weekStart, end: weekEnd }) ||
        (tripStart <= weekStart && tripEnd >= weekEnd)
      ) {
        // Allocate proportional cost if trip spans multiple weeks
        const tripDuration = Math.max(1, Math.ceil((tripEnd.getTime() - tripStart.getTime()) / (1000 * 60 * 60 * 24)));
        const weeksInTrip = Math.ceil(tripDuration / 7);
        const costPerWeek = (trip.actualCost || trip.estimatedCost) / weeksInTrip;
        return sum + costPerWeek;
      }
      return sum;
    }, 0);

    // Calculate spending for expenses in this week
    const expenseSpent = expenses.reduce((sum, expense) => {
      const expenseDate = parseISO(expense.date);
      if (isWithinInterval(expenseDate, { start: weekStart, end: weekEnd })) {
        return sum + expense.amount;
      }
      return sum;
    }, 0);

    const weekSpent = tripSpent + expenseSpent;

    return {
      week: weekKey,
      budget: weeklyBudgetAmount,
      spent: weekSpent,
      remaining: weeklyBudgetAmount - weekSpent,
    };
  });
};

export const calculateRemainingBudget = (budget: Budget, trips: Trip[], expenses: Expense[] = []): number => {
  const tripSpent = trips.reduce((sum, trip) => {
    return sum + (trip.actualCost || trip.estimatedCost);
  }, 0);
  const expenseSpent = expenses.reduce((sum, expense) => {
    return sum + expense.amount;
  }, 0);
  return budget.semesterBudget - (tripSpent + expenseSpent);
};

export const getCurrentWeekBudget = (weeklyBudgets: WeeklyBudget[]): WeeklyBudget | null => {
  const today = new Date();
  const currentWeek = format(startOfWeek(today, { weekStartsOn: 1 }), 'yyyy-MM-dd');
  return weeklyBudgets.find(w => w.week === currentWeek) || null;
};

export const getRecommendations = (
  budget: Budget,
  trips: Trip[],
  weeklyBudgets: WeeklyBudget[],
  expenses: Expense[] = []
): string[] => {
  const recommendations: string[] = [];
  const remaining = calculateRemainingBudget(budget, trips, expenses);
  const currentWeek = getCurrentWeekBudget(weeklyBudgets);

  if (remaining < 0) {
    recommendations.push('⚠️ You have exceeded your budget. Consider reducing trip costs or removing some trips.');
  } else if (remaining < budget.semesterBudget * 0.1) {
    recommendations.push('💰 You have less than 10% of your budget remaining. Be mindful of spending.');
  }

  if (currentWeek && currentWeek.remaining < 0) {
    recommendations.push('📅 This week you are over budget. Try to reduce spending in upcoming weeks.');
  } else if (currentWeek && currentWeek.remaining < currentWeek.budget * 0.2) {
    recommendations.push('📅 You have limited budget remaining for this week. Plan accordingly.');
  }

  const upcomingTrips = trips.filter(trip => {
    const tripDate = parseISO(trip.startDate);
    return tripDate > new Date();
  });

  if (upcomingTrips.length > 0) {
    const totalUpcomingCost = upcomingTrips.reduce((sum, trip) => {
      return sum + (trip.actualCost || trip.estimatedCost);
    }, 0);
    
    if (totalUpcomingCost > remaining) {
      recommendations.push(`✈️ You have ${upcomingTrips.length} upcoming trip(s) totaling $${totalUpcomingCost.toFixed(2)}, but only $${remaining.toFixed(2)} remaining. Consider adjusting your plans.`);
    }
  }

  if (recommendations.length === 0) {
    recommendations.push('✅ Your budget looks good! Keep tracking your spending.');
  }

  return recommendations;
};

