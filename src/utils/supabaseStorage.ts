import { supabase } from '../lib/supabase';
import { Budget, Trip, WishlistItem, Expense, BudgetMode, WeeklyPlan, WeeklyPlanEvent } from '../types';

// Helper to ensure fresh session for write operations
async function ensureFreshSession() {
  // Try to refresh the session to restore connection after tab switch
  try {
    await supabase.auth.refreshSession();
  } catch (e) {
    // Ignore refresh errors, we'll try the operation anyway
  }
  
  const { data: { session } } = await supabase.auth.getSession();
  return session?.user ?? null;
}

export const storage = {
  // Budget
  async getBudget(): Promise<Budget | null> {
    const { data: { session } } = await supabase.auth.getSession();
    const user = session?.user;
    if (!user) return null;

    const { data, error } = await supabase
      .from('budgets')
      .select('*')
      .eq('user_id', user.id)
      .single();

    if (error || !data) return null;

    return {
      budgetMode: (data.budget_mode as BudgetMode) || 'total',
      semesterBudget: parseFloat(data.semester_budget),
      startDate: data.start_date,
      endDate: data.end_date,
      spent: parseFloat(data.spent),
      plannedSpending: parseFloat(data.planned_spending || '0'),
    };
  },

  async saveBudget(budget: Budget): Promise<void> {
    const user = await ensureFreshSession();
    if (!user) throw new Error('User not authenticated');

    const { error } = await supabase
      .from('budgets')
      .upsert({
        user_id: user.id,
        budget_mode: budget.budgetMode,
        semester_budget: budget.semesterBudget,
        start_date: budget.startDate,
        end_date: budget.endDate,
        spent: budget.spent,
        planned_spending: budget.plannedSpending,
        updated_at: new Date().toISOString(),
      }, {
        onConflict: 'user_id'
      });

    if (error) throw error;
  },

  // Trips
  async getTrips(): Promise<Trip[]> {
    const { data: { session } } = await supabase.auth.getSession();
    const user = session?.user;
    if (!user) return [];

    const { data, error } = await supabase
      .from('trips')
      .select('*')
      .eq('user_id', user.id)
      .order('start_date', { ascending: true });

    if (error || !data) return [];

    return data.map(trip => ({
      id: trip.id,
      name: trip.name,
      destination: trip.destination,
      startDate: trip.start_date,
      endDate: trip.end_date,
      // New fields - use them if available, otherwise fallback to legacy fields
      prepaidCost: trip.prepaid_cost !== null ? parseFloat(trip.prepaid_cost) : (trip.actual_cost ? parseFloat(trip.actual_cost) : 0),
      plannedCost: trip.planned_cost !== null ? parseFloat(trip.planned_cost) : parseFloat(trip.estimated_cost),
      // Legacy fields for backward compatibility
      estimatedCost: parseFloat(trip.estimated_cost),
      actualCost: trip.actual_cost ? parseFloat(trip.actual_cost) : undefined,
      notes: trip.notes || undefined,
    }));
  },

  async addTrip(trip: Trip): Promise<void> {
    const user = await ensureFreshSession();
    if (!user) throw new Error('User not authenticated');

    // Calculate legacy fields from new fields for backward compatibility
    const totalCost = trip.prepaidCost + trip.plannedCost;

    const { error } = await supabase
      .from('trips')
      .insert({
        id: trip.id,
        user_id: user.id,
        name: trip.name,
        destination: trip.destination,
        start_date: trip.startDate,
        end_date: trip.endDate,
        prepaid_cost: trip.prepaidCost,
        planned_cost: trip.plannedCost,
        // Legacy fields - keep them in sync
        estimated_cost: totalCost,
        actual_cost: trip.prepaidCost > 0 ? trip.prepaidCost : null,
        notes: trip.notes,
      });

    if (error) throw error;
  },

  async updateTrip(id: string, updates: Partial<Trip>): Promise<void> {
    const user = await ensureFreshSession();
    if (!user) throw new Error('User not authenticated');

    const updateData: any = {};
    if (updates.name) updateData.name = updates.name;
    if (updates.destination) updateData.destination = updates.destination;
    if (updates.startDate) updateData.start_date = updates.startDate;
    if (updates.endDate) updateData.end_date = updates.endDate;
    if (updates.prepaidCost !== undefined) updateData.prepaid_cost = updates.prepaidCost;
    if (updates.plannedCost !== undefined) updateData.planned_cost = updates.plannedCost;
    // Update legacy fields too
    if (updates.prepaidCost !== undefined || updates.plannedCost !== undefined) {
      const prepaid = updates.prepaidCost ?? 0;
      const planned = updates.plannedCost ?? 0;
      updateData.estimated_cost = prepaid + planned;
      updateData.actual_cost = prepaid > 0 ? prepaid : null;
    }
    if (updates.notes !== undefined) updateData.notes = updates.notes;
    updateData.updated_at = new Date().toISOString();

    const { error } = await supabase
      .from('trips')
      .update(updateData)
      .eq('id', id)
      .eq('user_id', user.id);

    if (error) throw error;
  },

  async deleteTrip(id: string): Promise<void> {
    const user = await ensureFreshSession();
    if (!user) throw new Error('User not authenticated');

    const { error } = await supabase
      .from('trips')
      .delete()
      .eq('id', id)
      .eq('user_id', user.id);

    if (error) throw error;
  },

  // Wishlist
  async getWishlist(): Promise<WishlistItem[]> {
    const { data: { session } } = await supabase.auth.getSession();
    const user = session?.user;
    if (!user) return [];

    const { data, error } = await supabase
      .from('wishlist_items')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });

    if (error || !data) return [];

    return data.map(item => ({
      id: item.id,
      name: item.name,
      location: item.location,
      estimatedCost: parseFloat(item.estimated_cost),
      priority: item.priority as 'high' | 'medium' | 'low',
      notes: item.notes || undefined,
    }));
  },

  async addWishlistItem(item: WishlistItem): Promise<void> {
    const user = await ensureFreshSession();
    if (!user) throw new Error('User not authenticated');

    const { error } = await supabase
      .from('wishlist_items')
      .insert({
        id: item.id,
        user_id: user.id,
        name: item.name,
        location: item.location,
        estimated_cost: item.estimatedCost,
        priority: item.priority,
        notes: item.notes,
      });

    if (error) throw error;
  },

  async updateWishlistItem(id: string, updates: Partial<WishlistItem>): Promise<void> {
    const user = await ensureFreshSession();
    if (!user) throw new Error('User not authenticated');

    const updateData: any = {};
    if (updates.name) updateData.name = updates.name;
    if (updates.location) updateData.location = updates.location;
    if (updates.estimatedCost !== undefined) updateData.estimated_cost = updates.estimatedCost;
    if (updates.priority) updateData.priority = updates.priority;
    if (updates.notes !== undefined) updateData.notes = updates.notes;
    updateData.updated_at = new Date().toISOString();

    const { error } = await supabase
      .from('wishlist_items')
      .update(updateData)
      .eq('id', id)
      .eq('user_id', user.id);

    if (error) throw error;
  },

  async deleteWishlistItem(id: string): Promise<void> {
    const user = await ensureFreshSession();
    if (!user) throw new Error('User not authenticated');

    const { error } = await supabase
      .from('wishlist_items')
      .delete()
      .eq('id', id)
      .eq('user_id', user.id);

    if (error) throw error;
  },

  // Expenses
  async getExpenses(): Promise<Expense[]> {
    const { data: { session } } = await supabase.auth.getSession();
    const user = session?.user;
    if (!user) return [];

    const { data, error } = await supabase
      .from('expenses')
      .select('*')
      .eq('user_id', user.id)
      .order('date', { ascending: false });

    if (error || !data) return [];

    return data.map(expense => ({
      id: expense.id,
      description: expense.description,
      amount: parseFloat(expense.amount),
      date: expense.date,
      category: expense.category || undefined,
      notes: expense.notes || undefined,
    }));
  },

  async addExpense(expense: Expense): Promise<void> {
    // Use fresh session for write operations to handle tab switching
    const user = await ensureFreshSession();
    if (!user) throw new Error('User not authenticated');

    const { error } = await supabase
      .from('expenses')
      .insert({
        id: expense.id,
        user_id: user.id,
        description: expense.description,
        amount: expense.amount,
        date: expense.date,
        category: expense.category,
        notes: expense.notes,
      });

    if (error) throw error;
  },

  async updateExpense(id: string, updates: Partial<Expense>): Promise<void> {
    const user = await ensureFreshSession();
    if (!user) throw new Error('User not authenticated');

    const updateData: any = {};
    if (updates.description) updateData.description = updates.description;
    if (updates.amount !== undefined) updateData.amount = updates.amount;
    if (updates.date) updateData.date = updates.date;
    if (updates.category !== undefined) updateData.category = updates.category;
    if (updates.notes !== undefined) updateData.notes = updates.notes;
    updateData.updated_at = new Date().toISOString();

    const { error } = await supabase
      .from('expenses')
      .update(updateData)
      .eq('id', id)
      .eq('user_id', user.id);

    if (error) throw error;
  },

  async deleteExpense(id: string): Promise<void> {
    const user = await ensureFreshSession();
    if (!user) throw new Error('User not authenticated');

    const { error } = await supabase
      .from('expenses')
      .delete()
      .eq('id', id)
      .eq('user_id', user.id);

    if (error) throw error;
  },

  // Calculate total spent (prepaid trip costs + expenses)
  async calculateTotalSpent(): Promise<number> {
    const trips = await this.getTrips();
    const expenses = await this.getExpenses();

    // Sum prepaid costs from trips (money already spent)
    const tripSpent = trips.reduce((sum, trip) => {
      return sum + trip.prepaidCost;
    }, 0);

    const expenseSpent = expenses.reduce((sum, expense) => {
      return sum + expense.amount;
    }, 0);

    return tripSpent + expenseSpent;
  },

  // Calculate total planned spending (planned trip costs)
  async calculateTotalPlanned(): Promise<number> {
    const trips = await this.getTrips();

    // Sum planned costs from trips (money still to be spent)
    const tripPlanned = trips.reduce((sum, trip) => {
      return sum + trip.plannedCost;
    }, 0);

    return tripPlanned;
  },

  // Calculate both spent and planned in one call (more efficient)
  async calculateSpentAndPlanned(): Promise<{ spent: number; planned: number }> {
    const trips = await this.getTrips();
    const expenses = await this.getExpenses();

    const tripSpent = trips.reduce((sum, trip) => sum + trip.prepaidCost, 0);
    const tripPlanned = trips.reduce((sum, trip) => sum + trip.plannedCost, 0);
    const expenseSpent = expenses.reduce((sum, expense) => sum + expense.amount, 0);

    return {
      spent: tripSpent + expenseSpent,
      planned: tripPlanned,
    };
  },

  // Weekly Plans
  async getWeeklyPlan(weekStart: string): Promise<WeeklyPlan | null> {
    const { data: { session } } = await supabase.auth.getSession();
    const user = session?.user;
    if (!user) return null;

    // Get the plan for this week
    const { data: planData, error: planError } = await supabase
      .from('weekly_plans')
      .select('*')
      .eq('user_id', user.id)
      .eq('week_start', weekStart)
      .single();

    if (planError || !planData) return null;

    // Get all events for this plan
    const { data: eventsData, error: eventsError } = await supabase
      .from('weekly_plan_events')
      .select('*')
      .eq('plan_id', planData.id)
      .order('created_at', { ascending: true });

    if (eventsError) return null;

    return {
      id: planData.id,
      weekStart: planData.week_start,
      events: (eventsData || []).map(event => ({
        id: event.id,
        planId: event.plan_id,
        dayOfWeek: event.day_of_week,
        eventName: event.event_name,
        amount: parseFloat(event.amount),
      })),
    };
  },

  async createOrGetWeeklyPlan(weekStart: string): Promise<WeeklyPlan> {
    const user = await ensureFreshSession();
    if (!user) throw new Error('User not authenticated');

    // Try to get existing plan
    const existingPlan = await this.getWeeklyPlan(weekStart);
    if (existingPlan) return existingPlan;

    // Create new plan
    const { data, error } = await supabase
      .from('weekly_plans')
      .insert({
        user_id: user.id,
        week_start: weekStart,
      })
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      weekStart: data.week_start,
      events: [],
    };
  },

  async addWeeklyPlanEvent(planId: string, event: Omit<WeeklyPlanEvent, 'id' | 'planId'>): Promise<WeeklyPlanEvent> {
    const user = await ensureFreshSession();
    if (!user) throw new Error('User not authenticated');

    const { data, error } = await supabase
      .from('weekly_plan_events')
      .insert({
        plan_id: planId,
        day_of_week: event.dayOfWeek,
        event_name: event.eventName,
        amount: event.amount,
      })
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      planId: data.plan_id,
      dayOfWeek: data.day_of_week,
      eventName: data.event_name,
      amount: parseFloat(data.amount),
    };
  },

  async updateWeeklyPlanEvent(eventId: string, updates: Partial<Omit<WeeklyPlanEvent, 'id' | 'planId'>>): Promise<void> {
    const user = await ensureFreshSession();
    if (!user) throw new Error('User not authenticated');

    const updateData: any = {};
    if (updates.dayOfWeek !== undefined) updateData.day_of_week = updates.dayOfWeek;
    if (updates.eventName !== undefined) updateData.event_name = updates.eventName;
    if (updates.amount !== undefined) updateData.amount = updates.amount;

    const { error } = await supabase
      .from('weekly_plan_events')
      .update(updateData)
      .eq('id', eventId);

    if (error) throw error;
  },

  async deleteWeeklyPlanEvent(eventId: string): Promise<void> {
    const user = await ensureFreshSession();
    if (!user) throw new Error('User not authenticated');

    const { error } = await supabase
      .from('weekly_plan_events')
      .delete()
      .eq('id', eventId);

    if (error) throw error;
  },

  async deleteWeeklyPlan(planId: string): Promise<void> {
    const user = await ensureFreshSession();
    if (!user) throw new Error('User not authenticated');

    // Events will be deleted automatically due to CASCADE
    const { error } = await supabase
      .from('weekly_plans')
      .delete()
      .eq('id', planId);

    if (error) throw error;
  },
};