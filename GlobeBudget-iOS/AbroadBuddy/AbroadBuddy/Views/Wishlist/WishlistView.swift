import SwiftUI
import SwiftData

struct WishlistView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WishlistItem.createdAt, order: .reverse) private var items: [WishlistItem]
    
    @State private var showAddItem = false
    @State private var selectedItem: WishlistItem?
    @State private var itemToDelete: WishlistItem?
    @State private var showDeleteConfirmation = false
    
    private var totalCost: Double {
        items.reduce(0) { $0 + $1.estimatedCost }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if items.isEmpty {
                        emptyStateView
                    } else {
                        itemListView
                    }
                }
                
                // Floating Action Button
                if !items.isEmpty {
                    Button {
                        showAddItem = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Add Place")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.pink)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Places to Visit")
            .sheet(isPresented: $showAddItem) {
                WishlistFormView(item: nil)
            }
            .sheet(item: $selectedItem) { item in
                WishlistFormView(item: item)
            }
            .alert("Remove from Wishlist", isPresented: $showDeleteConfirmation, presenting: itemToDelete) { item in
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    deleteItem(item)
                }
            } message: { item in
                Text("Are you sure you want to remove \"\(item.name)\" from your wishlist?")
            }
        }
    }
    
    // MARK: - Empty State
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Your Wishlist is Empty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add places you dream of visiting during your study abroad!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showAddItem = true
            } label: {
                Label("Add Place", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.pink)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
    
    // MARK: - Item List
    @ViewBuilder
    private var itemListView: some View {
        List {
            // Summary section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Wishlist")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("$\(totalCost, specifier: "%.0f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.pink)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(items.count) places")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Image(systemName: "heart.fill")
                            .font(.title2)
                            .foregroundStyle(.pink.opacity(0.3))
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Items
            Section {
                ForEach(items) { item in
                    WishlistRowView(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedItem = item
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                itemToDelete = item
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                selectedItem = item
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.pink)
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func deleteItem(_ item: WishlistItem) {
        modelContext.delete(item)
    }
}

// MARK: - Wishlist Row View
struct WishlistRowView: View {
    let item: WishlistItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.location)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Text("$\(item.estimatedCost, specifier: "%.0f")")
                    .font(.headline)
                    .foregroundStyle(.pink)
            }
            
            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WishlistView()
        .modelContainer(for: WishlistItem.self, inMemory: true)
}

