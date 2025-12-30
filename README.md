# 🌍 GlobeBudget

A comprehensive budget planning application designed specifically for students studying abroad. Track your semester budget, plan trips, maintain a wishlist of places to visit, and get intelligent spending recommendations.

## Features

- **Budget Management**: Set your semester budget and track spending in real-time
- **Trip Planning**: Add planned trips to your calendar with dates and estimated costs
- **Wishlist**: Keep track of places you want to visit with priority levels
- **Weekly Budget Tracking**: See how much you can spend each week based on your budget
- **Smart Recommendations**: Get personalized recommendations on how to manage your budget and trips
- **Local Storage**: All data is stored locally in your browser (ready for Supabase integration later)

## Getting Started

### Prerequisites

- Node.js (v18 or higher)
- npm or yarn

### Installation

1. Install dependencies:
```bash
npm install
```

2. Start the development server:
```bash
npm run dev
```

3. Open your browser and navigate to `http://localhost:5173`

### Building for Production

```bash
npm run build
```

The built files will be in the `dist` directory.

## Usage

1. **Set Your Budget**: Go to the Budget tab and enter your total semester budget, start date, and end date.

2. **Add Trips**: Navigate to the Trips tab and add your planned trips with:
   - Trip name and destination
   - Start and end dates
   - Estimated and actual costs
   - Optional notes

3. **Build Your Wishlist**: Add places you want to visit with priority levels (high, medium, low) and estimated costs.

4. **View Dashboard**: Check the Dashboard for:
   - Your current week's budget
   - Spending recommendations
   - Upcoming trips

## Technology Stack

- **React 18** - UI framework
- **TypeScript** - Type safety
- **Vite** - Build tool and dev server
- **Tailwind CSS** - Styling
- **date-fns** - Date manipulation
- **lucide-react** - Icons
- **LocalStorage** - Data persistence (temporary, ready for Supabase)

## Future Enhancements

- Supabase integration for cloud storage and multi-device sync
- User authentication
- Export budget reports
- Currency conversion
- Trip cost breakdowns
- Photo attachments for trips and wishlist items

## License

MIT
