import { useState, useEffect } from 'react';
import { Trip } from '../types';
import { storage } from '../utils/localStorage';
import { Plus, Calendar as CalendarIcon, MapPin, DollarSign, Edit2, Trash2 } from 'lucide-react';
import { format, parseISO } from 'date-fns';

export default function TripCalendar() {
  const [trips, setTrips] = useState<Trip[]>([]);
  const [showModal, setShowModal] = useState(false);
  const [editingTrip, setEditingTrip] = useState<Trip | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    destination: '',
    startDate: '',
    endDate: '',
    estimatedCost: '',
    actualCost: '',
    notes: '',
  });

  useEffect(() => {
    setTrips(storage.getTrips());
  }, []);

  const handleOpenModal = (trip?: Trip) => {
    if (trip) {
      setEditingTrip(trip);
      setFormData({
        name: trip.name,
        destination: trip.destination,
        startDate: trip.startDate,
        endDate: trip.endDate,
        estimatedCost: trip.estimatedCost.toString(),
        actualCost: trip.actualCost?.toString() || '',
        notes: trip.notes || '',
      });
    } else {
      setEditingTrip(null);
      setFormData({
        name: '',
        destination: '',
        startDate: '',
        endDate: '',
        estimatedCost: '',
        actualCost: '',
        notes: '',
      });
    }
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingTrip(null);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const trip: Trip = {
      id: editingTrip?.id || Date.now().toString(),
      name: formData.name,
      destination: formData.destination,
      startDate: formData.startDate,
      endDate: formData.endDate,
      estimatedCost: parseFloat(formData.estimatedCost),
      actualCost: formData.actualCost ? parseFloat(formData.actualCost) : undefined,
      notes: formData.notes || undefined,
    };

    if (editingTrip) {
      storage.updateTrip(editingTrip.id, trip);
    } else {
      storage.addTrip(trip);
    }

    setTrips(storage.getTrips());
    
    // Update budget spent amount
    const budget = storage.getBudget();
    if (budget) {
      const totalSpent = storage.calculateTotalSpent();
      storage.saveBudget({ ...budget, spent: totalSpent });
    }

    handleCloseModal();
  };

  const handleDelete = (id: string) => {
    if (confirm('Are you sure you want to delete this trip?')) {
      storage.deleteTrip(id);
      setTrips(storage.getTrips());
      
      // Update budget spent amount
      const budget = storage.getBudget();
      if (budget) {
        const totalSpent = storage.calculateTotalSpent();
        storage.saveBudget({ ...budget, spent: totalSpent });
      }
    }
  };

  return (
    <div className="bg-slate-800 rounded-lg p-6 shadow-lg">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-white flex items-center gap-2">
          <CalendarIcon className="w-6 h-6 text-primary-400" />
          Planned Trips
        </h2>
        <button
          onClick={() => handleOpenModal()}
          className="px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          Add Trip
        </button>
      </div>

      {trips.length === 0 ? (
        <div className="text-center py-12 text-gray-400">
          <CalendarIcon className="w-16 h-16 mx-auto mb-4 opacity-50" />
          <p>No trips planned yet. Add your first trip to get started!</p>
        </div>
      ) : (
        <div className="space-y-4">
          {trips.map((trip) => (
            <div
              key={trip.id}
              className="bg-slate-700 rounded-lg p-4 hover:bg-slate-650 transition-colors"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <h3 className="text-xl font-semibold text-white mb-2">{trip.name}</h3>
                  <div className="space-y-1 text-sm text-gray-300">
                    <div className="flex items-center gap-2">
                      <MapPin className="w-4 h-4" />
                      <span>{trip.destination}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <CalendarIcon className="w-4 h-4" />
                      <span>
                        {format(parseISO(trip.startDate), 'MMM d')} -{' '}
                        {format(parseISO(trip.endDate), 'MMM d, yyyy')}
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <DollarSign className="w-4 h-4" />
                      <span>
                        Estimated: ${trip.estimatedCost.toLocaleString()}
                        {trip.actualCost && (
                          <span className="ml-2">
                            | Actual: ${trip.actualCost.toLocaleString()}
                          </span>
                        )}
                      </span>
                    </div>
                    {trip.notes && (
                      <p className="text-gray-400 mt-2">{trip.notes}</p>
                    )}
                  </div>
                </div>
                <div className="flex gap-2 ml-4">
                  <button
                    onClick={() => handleOpenModal(trip)}
                    className="p-2 text-primary-400 hover:bg-slate-600 rounded transition-colors"
                  >
                    <Edit2 className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => handleDelete(trip.id)}
                    className="p-2 text-red-400 hover:bg-slate-600 rounded transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-slate-800 rounded-lg p-6 max-w-md w-full max-h-[90vh] overflow-y-auto">
            <h3 className="text-2xl font-bold text-white mb-4">
              {editingTrip ? 'Edit Trip' : 'Add New Trip'}
            </h3>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Trip Name
                </label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Destination
                </label>
                <input
                  type="text"
                  value={formData.destination}
                  onChange={(e) => setFormData({ ...formData, destination: e.target.value })}
                  className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                  required
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">
                    Start Date
                  </label>
                  <input
                    type="date"
                    value={formData.startDate}
                    onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                    className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                    required
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">
                    End Date
                  </label>
                  <input
                    type="date"
                    value={formData.endDate}
                    onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
                    className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                    required
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">
                    Estimated Cost ($)
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    value={formData.estimatedCost}
                    onChange={(e) => setFormData({ ...formData, estimatedCost: e.target.value })}
                    className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                    required
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">
                    Actual Cost ($)
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    value={formData.actualCost}
                    onChange={(e) => setFormData({ ...formData, actualCost: e.target.value })}
                    className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Notes
                </label>
                <textarea
                  value={formData.notes}
                  onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                  className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                  rows={3}
                />
              </div>
              <div className="flex gap-2">
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors"
                >
                  {editingTrip ? 'Update' : 'Add'} Trip
                </button>
                <button
                  type="button"
                  onClick={handleCloseModal}
                  className="flex-1 px-4 py-2 bg-slate-600 hover:bg-slate-700 text-white rounded-lg transition-colors"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
