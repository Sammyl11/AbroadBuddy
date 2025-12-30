import { useState, useEffect } from 'react';
import { WishlistItem } from '../types';
import { storage } from '../utils/localStorage';
import { Heart, Plus, MapPin, DollarSign, Star, Edit2, Trash2 } from 'lucide-react';

export default function Wishlist() {
  const [items, setItems] = useState<WishlistItem[]>([]);
  const [showModal, setShowModal] = useState(false);
  const [editingItem, setEditingItem] = useState<WishlistItem | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    location: '',
    estimatedCost: '',
    priority: 'medium' as 'high' | 'medium' | 'low',
    notes: '',
  });

  useEffect(() => {
    setItems(storage.getWishlist());
  }, []);

  const handleOpenModal = (item?: WishlistItem) => {
    if (item) {
      setEditingItem(item);
      setFormData({
        name: item.name,
        location: item.location,
        estimatedCost: item.estimatedCost.toString(),
        priority: item.priority,
        notes: item.notes || '',
      });
    } else {
      setEditingItem(null);
      setFormData({
        name: '',
        location: '',
        estimatedCost: '',
        priority: 'medium',
        notes: '',
      });
    }
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingItem(null);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const item: WishlistItem = {
      id: editingItem?.id || Date.now().toString(),
      name: formData.name,
      location: formData.location,
      estimatedCost: parseFloat(formData.estimatedCost),
      priority: formData.priority,
      notes: formData.notes || undefined,
    };

    if (editingItem) {
      storage.updateWishlistItem(editingItem.id, item);
    } else {
      storage.addWishlistItem(item);
    }

    setItems(storage.getWishlist());
    handleCloseModal();
  };

  const handleDelete = (id: string) => {
    if (confirm('Are you sure you want to remove this from your wishlist?')) {
      storage.deleteWishlistItem(id);
      setItems(storage.getWishlist());
    }
  };

  const getPriorityColor = (priority: 'high' | 'medium' | 'low') => {
    switch (priority) {
      case 'high':
        return 'text-red-400';
      case 'medium':
        return 'text-yellow-400';
      case 'low':
        return 'text-green-400';
    }
  };

  const sortedItems = [...items].sort((a, b) => {
    const priorityOrder = { high: 3, medium: 2, low: 1 };
    return priorityOrder[b.priority] - priorityOrder[a.priority];
  });

  return (
    <div className="bg-slate-800 rounded-lg p-6 shadow-lg">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-white flex items-center gap-2">
          <Heart className="w-6 h-6 text-primary-400" />
          Places to Visit
        </h2>
        <button
          onClick={() => handleOpenModal()}
          className="px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
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
          {sortedItems.map((item) => (
            <div
              key={item.id}
              className="bg-slate-700 rounded-lg p-4 hover:bg-slate-650 transition-colors"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-2">
                    <h3 className="text-xl font-semibold text-white">{item.name}</h3>
                    <Star className={`w-4 h-4 ${getPriorityColor(item.priority)}`} />
                    <span className={`text-xs px-2 py-1 rounded ${getPriorityColor(item.priority)} bg-opacity-20`}>
                      {item.priority.toUpperCase()}
                    </span>
                  </div>
                  <div className="space-y-1 text-sm text-gray-300">
                    <div className="flex items-center gap-2">
                      <MapPin className="w-4 h-4" />
                      <span>{item.location}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <DollarSign className="w-4 h-4" />
                      <span>Estimated: ${item.estimatedCost.toLocaleString()}</span>
                    </div>
                    {item.notes && (
                      <p className="text-gray-400 mt-2">{item.notes}</p>
                    )}
                  </div>
                </div>
                <div className="flex gap-2 ml-4">
                  <button
                    onClick={() => handleOpenModal(item)}
                    className="p-2 text-primary-400 hover:bg-slate-600 rounded transition-colors"
                  >
                    <Edit2 className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => handleDelete(item.id)}
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
              {editingItem ? 'Edit Wishlist Item' : 'Add to Wishlist'}
            </h3>
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
                    Priority
                  </label>
                  <select
                    value={formData.priority}
                    onChange={(e) => setFormData({ ...formData, priority: e.target.value as 'high' | 'medium' | 'low' })}
                    className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg border border-slate-600 focus:border-primary-500 focus:outline-none"
                  >
                    <option value="high">High</option>
                    <option value="medium">Medium</option>
                    <option value="low">Low</option>
                  </select>
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
