-- SQL Migration for Weekly Budget Planner
-- Run this in your Supabase SQL editor

-- Table to store weekly plans (one per week per user)
CREATE TABLE weekly_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  week_start DATE NOT NULL, -- The Monday of the selected week
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, week_start)
);

-- Table to store individual events within a weekly plan
CREATE TABLE weekly_plan_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID REFERENCES weekly_plans(id) ON DELETE CASCADE NOT NULL,
  day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0 = Monday, 6 = Sunday
  event_name TEXT NOT NULL,
  amount NUMERIC DEFAULT 0 NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE weekly_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_plan_events ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only access their own weekly plans
CREATE POLICY "Users can view their own weekly plans" ON weekly_plans
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own weekly plans" ON weekly_plans
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own weekly plans" ON weekly_plans
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own weekly plans" ON weekly_plans
  FOR DELETE USING (auth.uid() = user_id);

-- RLS Policy: Users can only access events in their own weekly plans
CREATE POLICY "Users can view events in their weekly plans" ON weekly_plan_events
  FOR SELECT USING (
    plan_id IN (SELECT id FROM weekly_plans WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can create events in their weekly plans" ON weekly_plan_events
  FOR INSERT WITH CHECK (
    plan_id IN (SELECT id FROM weekly_plans WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can update events in their weekly plans" ON weekly_plan_events
  FOR UPDATE USING (
    plan_id IN (SELECT id FROM weekly_plans WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can delete events in their weekly plans" ON weekly_plan_events
  FOR DELETE USING (
    plan_id IN (SELECT id FROM weekly_plans WHERE user_id = auth.uid())
  );

-- Index for faster lookups
CREATE INDEX idx_weekly_plans_user_week ON weekly_plans(user_id, week_start);
CREATE INDEX idx_weekly_plan_events_plan ON weekly_plan_events(plan_id);

