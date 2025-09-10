//
//  MapLocationPickerView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapLocationPickerView: View {
    @Binding var selectedLocation: LocationCoordinate?
    @Environment(\.dismiss) private var dismiss
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074), // 北京
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var address = ""
    @State private var city = ""
    @State private var country = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var showingSearchResults = false
    
    private let locationManager = CLLocationManager()
    private let searchCompleter = MKLocalSearchCompleter()
    @StateObject private var searchCompleterDelegate = SearchCompleterDelegate()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("location.search.placeholder".localized, text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button("common.cancel".localized) {
                                searchText = ""
                                searchResults = []
                                showingSearchResults = false
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 搜索结果
                    if showingSearchResults && !searchResults.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(searchResults, id: \.self) { item in
                                    Button(action: {
                                        selectSearchResult(item)
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.name ?? "")
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                
                                                Text(item.placemark.title ?? "")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 200)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                    }
                }
                .background(Color(.systemBackground))
                
                // 地图视图
                ZStack {
                    Map(coordinateRegion: $region, annotationItems: selectedCoordinate != nil ? [MapAnnotation(coordinate: selectedCoordinate!)] : []) { annotation in
                        MapPin(coordinate: annotation.coordinate, tint: .red)
                    }
                    .onChange(of: region.center.latitude) { _, _ in
                        updateSelectedLocation()
                    }
                    .onChange(of: region.center.longitude) { _, _ in
                        updateSelectedLocation()
                    }
                    
                    // 中心标记
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                                .background(Color.white)
                                .clipShape(Circle())
                            Spacer()
                        }
                        Spacer()
                    }
                }
                
                // 位置信息显示
                VStack(alignment: .leading, spacing: 12) {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("location.loading".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if !address.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("location.selected".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(address)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            if !city.isEmpty || !country.isEmpty {
                                Text("\(city)\(city.isEmpty ? "" : ", ")\(country)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Text("location.drag.to.select".localized)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("location.select".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.confirm".localized) {
                        confirmSelection()
                    }
                    .disabled(selectedCoordinate == nil)
                }
            }
            .onAppear {
                setupLocationManager()
                setupSearchCompleter()
                if let existingLocation = selectedLocation {
                    region.center = CLLocationCoordinate2D(
                        latitude: existingLocation.latitude,
                        longitude: existingLocation.longitude
                    )
                    selectedCoordinate = region.center
                    address = existingLocation.address ?? ""
                    city = existingLocation.city ?? ""
                    country = existingLocation.country ?? ""
                }
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.count > 2 {
                    performSearch()
                } else {
                    searchResults = []
                    showingSearchResults = false
                }
            }
            .alert("common.error".localized, isPresented: $showingAlert) {
                Button("common.ok".localized) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = searchCompleterDelegate
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }
    
    private func updateSelectedLocation() {
        selectedCoordinate = region.center
        reverseGeocode(coordinate: region.center)
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                
                if let error = error {
                    print("Search error: \(error)")
                    return
                }
                
                searchResults = response?.mapItems ?? []
                showingSearchResults = true
            }
        }
    }
    
    private func selectSearchResult(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        region.center = coordinate
        selectedCoordinate = coordinate
        reverseGeocode(coordinate: coordinate)
        
        searchText = ""
        searchResults = []
        showingSearchResults = false
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        isLoading = true
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("Reverse geocoding error: \(error)")
                    address = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                    city = ""
                    country = ""
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    address = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                    city = ""
                    country = ""
                    return
                }
                
                // 构建地址信息
                var addressComponents: [String] = []
                
                if let name = placemark.name {
                    addressComponents.append(name)
                }
                if let thoroughfare = placemark.thoroughfare {
                    addressComponents.append(thoroughfare)
                }
                if let subThoroughfare = placemark.subThoroughfare {
                    addressComponents.append(subThoroughfare)
                }
                
                address = addressComponents.joined(separator: ", ")
                city = placemark.locality ?? ""
                country = placemark.country ?? ""
            }
        }
    }
    
    private func confirmSelection() {
        guard let coordinate = selectedCoordinate else { return }
        
        let location = LocationCoordinate(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            address: address.isEmpty ? nil : address,
            city: city.isEmpty ? nil : city,
            country: country.isEmpty ? nil : country
        )
        
        selectedLocation = location
        dismiss()
    }
}

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // 这里可以添加自动完成功能
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error)")
    }
}

#Preview {
    MapLocationPickerView(selectedLocation: .constant(nil))
}
