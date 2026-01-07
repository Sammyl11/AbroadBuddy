import { useState } from 'react';
import { WishlistItem } from '../types';
import { storage } from '../utils/supabaseStorage';
import { useData } from '../contexts/DataContext';
import { Heart, Plus, MapPin, DollarSign, Edit2, Trash2, X } from 'lucide-react';

export default function Wishlist() {
  const { wishlist: items, loading, refreshData } = useData();
  const [showModal, setShowModal] = useState(false);
  const [editingItem, setEditingItem] = useState<WishlistItem | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    location: '',
    estimatedCost: '',
    notes: '',
  });

  const handleOpenModal = (item?: WishlistItem) => {
    if (item) {
      setEditingItem(item);
      setFormData({
        name: item.name,
        location: item.location,
        estimatedCost: item.estimatedCost.toString(),
        notes: item.notes || '',
      });
    } else {
      setEditingItem(null);
      setFormData({
        name: '',
        location: '',
        estimatedCost: '',
        notes: '',
      });
    }
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingItem(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      const item: WishlistItem = {
        id: editingItem?.id || crypto.randomUUID(),
        name: formData.name,
        location: formData.location,
        estimatedCost: parseFloat(formData.estimatedCost),
        priority: editingItem?.priority || 'medium', // Keep existing or default to medium
        notes: formData.notes || undefined,
      };

      if (editingItem) {
        await storage.updateWishlistItem(editingItem.id, item);
      } else {
        await storage.addWishlistItem(item);
      }

      await refreshData();
      handleCloseModal();
    } catch (error: any) {
      alert('Error saving wishlist item: ' + (error.message || 'Unknown error'));
    }
  };

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure you want to remove this from your wishlist?')) {
      try {
        await storage.deleteWishlistItem(id);
        await refreshData();
      } catch (error: any) {
        alert('Error deleting wishlist item: ' + (error.message || 'Unknown error'));
      }
    }
  };


  if (loading) {
    return (
      <div className="bg-slate-800 rounded-lg p-6 shadow-lg text-center">
        <p className="text-gray-400">Loading wishlist...</p>
      </div>
    );
  }

  return (
    <div className="bg-slate-800 rounded-lg p-6 shadow-lg">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6">
        <h2 className="text-xl sm:text-2xl font-bold text-white flex items-center gap-2">
          <Heart className="w-5 h-5 sm:w-6 sm:h-6 text-primary-400" />
          Places to Visit
        </h2>
        <button
          onClick={() => handleOpenModal()}
          className="px-3 py-1.5 sm:px-4 sm:py-2 text-sm sm:text-base bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors flex items-center gap-1.5 sm:gap-2 self-start sm:self-auto"
        >
          <Plus className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
          Add Place
        </button>
      </div>

      {items.length === 0 ? (
        <div className="text-center py-12 text-gray-400">
          <Heart className="w-16 h-16 mx-auto mb-4 opacity-50" />
          <p>Your wishlist is empty. Add places you want to visit!</p>
        </div>
      ) : (
        <div className="space-y-4">
          {items.map((item) => (
            <div
              key={item.id}
              className="bg-slate-700 rounded-lg p-4 hover:bg-slate-650 transition-colors"
            >
              <div className="flex items-start justify-between gap-3">
                <div className="flex-1 min-w-0">
                  <h3 className="text-lg sm:text-xl font-semibold text-white mb-2">{item.name}</h3>
                  <div className="space-y-1 text-sm text-gray-300">
                    <div className="flex items-center gap-2">
                      <MapPin className="w-4 h-4 flex-shrink-0" />
                      <span className="truncate">{item.location}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <DollarSign className="w-4 h-4 flex-shrink-0" />
                      <span>${item.estimatedCost.toLocaleString()}</span>
                    </div>
                    {item.notes && (
                      <p className="text-gray-400 mt-2">{item.notes}</p>
                    )}
                  </div>
                </div>
                <div className="flex flex-col sm:flex-row gap-1 sm:gap-2 flex-shrink-0">
                  <button
                    onClick={() => handleOpenModal(item)}
                    className="p-2 text-primary-400 hover:bg-slate-600 rounded transition-colors"
                    title="Edit"
                  >
                    <Edit2 className="w-5 h-5" />
                  </button>
                  <button
                    onClick={() => handleDelete(item.id)}
                    className="p-2 text-red-400 hover:bg-slate-600 rounded transition-colors"
                    title="Delete"
                  >
                    <Trash2 className="w-5 h-5" />
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
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-2xl font-bold text-white">
                {editingItem ? 'Edit Wishlist Item' : 'Add to Wishlist'}
              </h3>
              <button
                onClick={handleCloseModal}
                className="p-2 text-gray-400 hover:text-white hover:bg-slate-700 rounded transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Place Name
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
                  Location
                </label>
                <input
                  type="text"
                  value={formData.location}
                  onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                  className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                  required
                />
              </div>
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
                  {editingItem ? 'Update' : 'Add'} Item
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
