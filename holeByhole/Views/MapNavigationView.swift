//
//  MapNavigationView.swift
//  holeByhole
//
//  Created by 向钧升 on 2025/9/8.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapNavigationView: View {
    let location: LocationCoordinate
    @Environment(\.dismiss) private var dismiss
    
    @State private var region: MKCoordinateRegion
    @State private var showingDirections = false
    @State private var directions: [MKRoute] = []
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(location: LocationCoordinate) {
        self.location = location
        self._region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 地图视图
                Map(coordinateRegion: $region, annotationItems: [MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))]) { annotation in
                    MapPin(coordinate: annotation.coordinate, tint: .red)
                }
                .overlay(alignment: .bottomTrailing) {
                    Button(action: {
                        getCurrentLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue)
                            .cornerRadius(22)
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                
                // 位置信息
                VStack(alignment: .leading, spacing: 8) {
                    Text(location.displayAddress)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let city = location.city, let country = location.country {
                        Text("\(city), \(country)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.red)
                        Text(String(format: "%.4f, %.4f", location.latitude, location.longitude))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 导航按钮
                VStack(spacing: 12) {
                    Button(action: {
                        openInMaps()
                    }) {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("location.open.in.maps".localized)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        getDirections()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            }
                            Text("location.get.directions".localized)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("location.navigation".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
            .alert("common.error".localized, isPresented: $showingAlert) {
                Button("common.ok".localized) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func getCurrentLocation() {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        
        if let currentLocation = locationManager.location {
            let currentCoordinate = currentLocation.coordinate
            region.center = currentCoordinate
            region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        }
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = location.displayAddress
        
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsMapTypeKey: MKMapType.standard.rawValue,
            MKLaunchOptionsShowsTrafficKey: true
        ])
    }
    
    private func getDirections() {
        isLoading = true
        
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = location.displayAddress
        
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = mapItem
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    alertMessage = String(format: "location.directions.error".localized, error.localizedDescription)
                    showingAlert = true
                    return
                }
                
                guard let response = response, !response.routes.isEmpty else {
                    alertMessage = "location.no.routes".localized
                    showingAlert = true
                    return
                }
                
                // 打开系统地图应用显示路线
                mapItem.openInMaps(launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                ])
            }
        }
    }
}

#Preview {
    MapNavigationView(location: LocationCoordinate(
        latitude: 39.9042,
        longitude: 116.4074,
        address: "天安门广场",
        city: "北京",
        country: "中国"
    ))
}
