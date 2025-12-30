export interface Trip {
  id: string;
  name: string;
  destination: string;
  startDate: string;
  endDate: string;
  estimatedCost: number;
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
  semesterBudget: number;
  startDate: string;
  endDate: string;
  spent: number;
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
