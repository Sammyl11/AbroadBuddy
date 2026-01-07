export type BudgetMode = 'total' | 'remaining' | 'tracking';

export interface Trip {
  id: string;
  name: string;
  destination: string;
  startDate: string;
  endDate: string;
  prepaidCost: number;      // Already paid/spent on this trip
  plannedCost: number;      // Still plan to spend on this trip
  // Legacy fields for backward compatibility
  estimatedCost?: number;
  actualCost?: number;
  notes?: string;
}

export interface WishlistItem {
  id: string;
  name: string;
  location: string;
  estimatedCost: number;
  priority: 'high' | 'medium' | 'low';
  notes?: string;
}

export interface Budget {
  budgetMode: BudgetMode;
  // For 'total' mode: the total budget for the semester
  // For 'remaining' mode: the initial remaining amount when user started tracking
  // For 'tracking' mode: optional target/goal (0 if not set)
  semesterBudget: number;
  startDate: string;
  endDate: string;
  spent: number;            // Total actually spent (prepaid trips + expenses)
  plannedSpending: number;  // Total planned but not yet spent
}

export interface WeeklyBudget {
  week: string;
  budget: number;
  spent: number;
  remaining: number;
}

export interface Expense {
  id: string;
  description: string;
  amount: number;
  date: string;
  category?: string;
  notes?: string;
}

export interface WeeklyPlanEvent {
  id: string;
  planId: string;
  dayOfWeek: number; // 0 = Monday, 6 = Sunday
  eventName: string;
  amount: number;
}

export interface WeeklyPlan {
  id: string;
  weekStart: string; // ISO date string for the Monday of the week
  events: WeeklyPlanEvent[];
}
