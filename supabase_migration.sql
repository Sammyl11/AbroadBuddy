-- Migration script to update GlobeBudget schema for multiple budget modes
-- Run this in your Supabase SQL editor

-- =====================================================
-- STEP 1: Update budgets table
-- =====================================================

-- Add new columns to budgets table
ALTER TABLE budgets 
ADD COLUMN IF NOT EXISTS budget_mode TEXT DEFAULT 'total' CHECK (budget_mode IN ('total', 'remaining', 'tracking')),
ADD COLUMN IF NOT EXISTS planned_spending DECIMAL(10,2) DEFAULT 0;

-- Update existing rows to have the default mode
UPDATE budgets SET budget_mode = 'total' WHERE budget_mode IS NULL;
UPDATE budgets SET planned_spending = 0 WHERE planned_spending IS NULL;

-- =====================================================
-- STEP 2: Update trips table
-- =====================================================

-- Add new columns for prepaid and planned costs
ALTER TABLE trips 
ADD COLUMN IF NOT EXISTS prepaid_cost DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS planned_cost DECIMAL(10,2) DEFAULT 0;

-- Migrate existing data: 
-- - actual_cost becomes prepaid_cost (already spent)
-- - estimated_cost - actual_cost becomes planned_cost (remaining to spend)
-- - If no actual_cost, estimated_cost becomes planned_cost (nothing spent yet)
UPDATE trips 
SET 
  prepaid_cost = COALESCE(actual_cost, 0),
  planned_cost = CASE 
    WHEN actual_cost IS NOT NULL THEN GREATEST(estimated_cost - actual_cost, 0)
    ELSE estimated_cost 
  END
WHERE prepaid_cost = 0 AND planned_cost = 0;

-- =====================================================
-- NOTES:
-- =====================================================
-- 
-- Budget Modes:
-- - 'total': Traditional mode - user sets total budget, tracks spending against it
-- - 'remaining': User enters current remaining amount, can add prepaid expenses
-- - 'tracking': No budget limit, just track spending with planned amounts
--
-- Trip Costs:
-- - prepaid_cost: Money already spent/paid for this trip
-- - planned_cost: Money still planning to spend on this trip
-- - Total trip cost = prepaid_cost + planned_cost
--
-- The old columns (estimated_cost, actual_cost) are kept for backward compatibility
-- but new code will use prepaid_cost and planned_cost

