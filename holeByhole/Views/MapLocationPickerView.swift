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
        span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0) // 增加跨度，便于导航到其他地区
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
    @State private var updateLocationTask: Task<Void, Never>?
    @State private var selectedCountry = "中国"
    @State private var showingCountryPicker = false
    
    private let locationManager = CLLocationManager()
    private let searchCompleter = MKLocalSearchCompleter()
    @StateObject private var searchCompleterDelegate = SearchCompleterDelegate()
    
    // 国家列表和对应的坐标区域
    private let countries = [
        ("中国", CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074), MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)),
        ("美国", CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)),
        ("英国", CLLocationCoordinate2D(latitude: 55.3781, longitude: -3.4360), MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)),
        ("日本", CLLocationCoordinate2D(latitude: 36.2048, longitude: 138.2529), MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)),
        ("澳大利亚", CLLocationCoordinate2D(latitude: -25.2744, longitude: 133.7751), MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)),
        ("加拿大", CLLocationCoordinate2D(latitude: 56.1304, longitude: -106.3468), MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 25)),
        ("德国", CLLocationCoordinate2D(latitude: 51.1657, longitude: 10.4515), MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)),
        ("法国", CLLocationCoordinate2D(latitude: 46.2276, longitude: 2.2137), MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)),
        ("意大利", CLLocationCoordinate2D(latitude: 41.8719, longitude: 12.5674), MKCoordinateSpan(latitudeDelta: 6, longitudeDelta: 6)),
        ("西班牙", CLLocationCoordinate2D(latitude: 40.4637, longitude: -3.7492), MKCoordinateSpan(latitudeDelta: 6, longitudeDelta: 6))
    ]
    
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
                        updateLocationWithDelay()
                    }
                    .onChange(of: region.center.longitude) { _, _ in
                        updateLocationWithDelay()
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
                    
                    // 国家选择器
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                showingCountryPicker = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "globe")
                                        .font(.caption)
                                    Text(selectedCountry)
                                        .font(.caption)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
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
            .sheet(isPresented: $showingCountryPicker) {
                CountryPickerView(selectedCountry: $selectedCountry, countries: countries) { country in
                    selectedCountry = country
                    updateRegionForCountry(country)
                }
            }
        }
    }
    
    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = searchCompleterDelegate
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        // 不设置 region，允许全球搜索建议
    }
    
    private func updateLocationWithDelay() {
        // 取消之前的任务
        updateLocationTask?.cancel()
        
        // 创建新的延迟任务
        updateLocationTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 延迟0.5秒
            
            if !Task.isCancelled {
                await MainActor.run {
                    selectedCoordinate = region.center
                    reverseGeocode(coordinate: region.center)
                }
            }
        }
    }
    
    private func updateSelectedLocation() {
        selectedCoordinate = region.center
        reverseGeocode(coordinate: region.center)
    }
    
    private func updateRegionForCountry(_ country: String) {
        if let countryData = countries.first(where: { $0.0 == country }) {
            region.center = countryData.1
            region.span = countryData.2
            selectedCoordinate = region.center
            reverseGeocode(coordinate: region.center)
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        // 使用当前选择国家的区域进行搜索
        if let countryData = countries.first(where: { $0.0 == selectedCountry }) {
            request.region = MKCoordinateRegion(center: countryData.1, span: countryData.2)
        } else {
            // 默认使用中国区域
            request.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074), span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20))
        }
        
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

// MARK: - Country Picker View
struct CountryPickerView: View {
    @Binding var selectedCountry: String
    let countries: [(String, CLLocationCoordinate2D, MKCoordinateSpan)]
    let onCountrySelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(countries, id: \.0) { country in
                Button(action: {
                    onCountrySelected(country.0)
                    dismiss()
                }) {
                    HStack {
                        Text(country.0)
                            .foregroundColor(.primary)
                        Spacer()
                        if country.0 == selectedCountry {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("选择国家")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MapLocationPickerView(selectedLocation: .constant(nil))
}
