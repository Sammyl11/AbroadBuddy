import SwiftUI
import SwiftData

struct TripsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    
    @State private var showAddTrip = false
    @State private var selectedTrip: Trip?
    @State private var tripToDelete: Trip?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if trips.isEmpty {
                        emptyStateView
                    } else {
                        tripListView
                    }
                }
                
                // Floating Action Button
                if !trips.isEmpty {
                    Button {
                        showAddTrip = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Add Trip")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.cyan)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Planned Trips")
            .sheet(isPresented: $showAddTrip) {
                TripFormView(trip: nil)
            }
            .sheet(item: $selectedTrip) { trip in
                TripFormView(trip: trip)
            }
            .alert("Delete Trip", isPresented: $showDeleteConfirmation, presenting: tripToDelete) { trip in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteTrip(trip)
                }
            } message: { trip in
                Text("Are you sure you want to delete \"\(trip.name)\"?")
            }
        }
    }
    
    // MARK: - Empty State
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "airplane")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Trips Planned")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first trip to start planning your study abroad adventure!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showAddTrip = true
            } label: {
                Label("Add Trip", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.cyan)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
    
    // MARK: - Trip List
    @ViewBuilder
    private var tripListView: some View {
        List {
            ForEach(trips) { trip in
                TripRowView(trip: trip)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTrip = trip
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            tripToDelete = trip
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            selectedTrip = trip
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.cyan)
                    }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func deleteTrip(_ trip: Trip) {
        modelContext.delete(trip)
    }
}

// MARK: - Trip Row View
struct TripRowView: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.name)
                        .font(.headline)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(trip.destination)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(trip.totalCost, specifier: "%.0f")")
                        .font(.headline)
                        .foregroundStyle(.cyan)
                    
                    statusBadge
                }
            }
            
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(trip.startDate.formatted(date: .abbreviated, time: .omitted)) - \(trip.endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Cost breakdown
            HStack(spacing: 12) {
                if trip.prepaidCost > 0 {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Prepaid: $\(trip.prepaidCost, specifier: "%.0f")")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                if trip.plannedCost > 0 {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.yellow)
                            .frame(width: 8, height: 8)
                        Text("Planned: $\(trip.plannedCost, specifier: "%.0f")")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
            }
            
            if let notes = trip.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        if trip.isOngoing {
            Text("Ongoing")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.orange.opacity(0.2))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        } else if trip.isPast {
            Text("Past")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.secondary.opacity(0.2))
                .foregroundStyle(.secondary)
                .clipShape(Capsule())
        } else {
            Text("Upcoming")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.cyan.opacity(0.2))
                .foregroundStyle(.cyan)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    TripsView()
        .modelContainer(for: Trip.self, inMemory: true)
}

