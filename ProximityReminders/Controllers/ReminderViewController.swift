//
//  ReminderViewController.swift
//  ProximityReminders
//
//  Created by Lukas Kasakaitis on 02.08.19.
//  Copyright © 2019 Lukas Kasakaitis. All rights reserved.
//

import UIKit
import CoreData
import MapKit

enum Perimeter {
    case whenIArrive, whenILeave
}

class ReminderViewController: UIViewController {
    
    // Outlets
    @IBOutlet weak var reminderTextView: UITextView!
    @IBOutlet weak var arriveLeaveSegmentControl: UISegmentedControl!
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var perimeterSegmentControl: UISegmentedControl!
    @IBOutlet weak var setLocationButton: UIButton!
    @IBOutlet weak var locationActivityIndicator: UIActivityIndicatorView!
    
    let map = MKMapView()
    var resultSearchController: UISearchController?
    var locationSearchController: LocationSearchController?
    var selectedLocation: MKPlacemark?
    var managedObjectContext: NSManagedObjectContext!
    var reminder: Reminder?
    var perimeter: Perimeter = .whenIArrive
    var regionBoundry: MKCircle?
    
    lazy var locationManager: LocationManager = {
        return LocationManager(delegate: self, viewController: self)
    }()
    
    lazy var notificationManager: LocationNotificationManager = {
        return LocationNotificationManager(viewController: nil)
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup
        map.delegate = self
        locationActivityIndicator.startAnimating()
        locationSearchController = (storyboard!.instantiateViewController(withIdentifier: String(describing: LocationSearchController.self)) as! LocationSearchController)
        locationSearchController?.handleMapSearchDelegate = self
        addDoneButtonOnKeyboard()
        configureSaveButton()
        configureReminder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        view.setNeedsLayout()
    }
    
    // MARK: - Actions
    
    @IBAction func switchPerimeter(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            perimeter = .whenIArrive
            addMapOverlay(for: selectedLocation)
        case 1:
            perimeter = .whenILeave
            addMapOverlay(for: selectedLocation)
        default:
            return
        }
        
    }
    
    @IBAction func searchLocation(_ sender: Any) {
        setupSearchBar()
    }
    
    
    // MARK: - Helper Methods
    
    func configureSaveButton() {
        let saveButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveReminder))
        navigationItem.rightBarButtonItem = saveButton
    }
    
    @objc func saveReminder() {

        if reminder == nil {
            // Create new reminder
            let newReminder = Reminder(context: self.managedObjectContext)
            // Configure Reminder properties
            newReminder.createDate = NSDate()
            newReminder.dateIdentifier = newReminder.createDate.description
            newReminder.isCompleted = false
            newReminder.reminderDescription = reminderTextView.text
            newReminder.latitude = selectedLocation?.coordinate.latitude as NSNumber?
            newReminder.longitude = selectedLocation?.coordinate.longitude as NSNumber?
            newReminder.entrance = perimeter == .whenIArrive ? true : false
            getAddress(reminder: newReminder)
            if let boundry = regionBoundry {
                locationManager.monitorRegionAtLocation(regionBoundry: boundry, identifier: newReminder.dateIdentifier, entry: newReminder.entrance)
            }
        } else {
            reminder?.reminderDescription = reminderTextView.text
            reminder?.latitude = selectedLocation?.coordinate.latitude as NSNumber?
            reminder?.longitude = selectedLocation?.coordinate.longitude as NSNumber?
            reminder?.entrance = perimeter == .whenIArrive ? true : false
            getAddress(reminder: reminder)
            if let boundry = regionBoundry {
                guard let dateIdentifier = reminder?.dateIdentifier else { return }
                locationManager.monitorRegionAtLocation(regionBoundry: boundry, identifier: dateIdentifier, entry: reminder!.entrance)
            }
        }
        
        managedObjectContext.saveChanges()
    
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helper
    
    func getAddress(reminder: Reminder?) {
        guard let reminder = reminder else { return }
        if let latitude = reminder.latitude as! Double?, let longitude = reminder.longitude as! Double? {
            
            self.locationManager.getAddress(latitude: latitude, longitude: longitude) { place, error in
                
                if let placeMark = place {
                    let addressPlace = MKPlacemark(placemark: placeMark)
                    reminder.address = addressPlace.parseAddress()
                    self.managedObjectContext.saveChanges()
                }
                
                if error != nil {
                    self.showAlert(with: "Error", and: error!.localizedDescription)
                }
                
            }
            
        }
    }
    
    func configureReminder() {
        guard let reminder = reminder else {
            getLocation()
            self.title = "New Reminder"
            return
        }
        
        self.title = reminder.reminderDescription
        
        if reminder.longitude == nil || reminder.longitude == nil {
            getLocation()
        }
        reminderTextView.text = reminder.reminderDescription
        perimeter = reminder.entrance ? .whenIArrive : .whenILeave
        
        if !reminder.entrance {
            perimeterSegmentControl.selectedSegmentIndex = 1
        }
        
        
        if let latitude = reminder.latitude as! Double?, let longitude = reminder.longitude as! Double? {
            
            let location = CLLocation(latitude: latitude, longitude: longitude)
            
            locationManager.getAddress(latitude: latitude, longitude: longitude) { place, error in
                
                if let place = place {
                    self.selectedLocation = MKPlacemark(placemark: place)
                    self.configureMap(with: location)
                }
                
                if error != nil {
                    self.showAlert(with: "Error", and: error!.localizedDescription)
                }
            }
            
        }
        
    }
    
    func configureMap(with location: CLLocation) {
        
        map.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(map)
        let span = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        
        addMapAnnonation(for: selectedLocation)
        addMapOverlay(for: selectedLocation)
        
        map.setRegion(region, animated: true)
        map.showsUserLocation = true
        
        //map.isZoomEnabled = false
        //map.isScrollEnabled = false
        map.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 0).isActive = true
        map.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: 0).isActive = true
        map.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 0).isActive = true
        map.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 0).isActive = true
    }
    
    func setupSearchBar() {
        definesPresentationContext = true
        
        locationSearchController?.mapView = map
        resultSearchController = UISearchController(searchResultsController: locationSearchController)
        
        if let searchController = resultSearchController {
            navigationItem.searchController = searchController
            searchController.searchBar.barStyle = .default
            searchController.searchBar.tintColor = .white
            searchController.searchBar.setTextColor(color: .black)
            searchController.searchBar.becomeFirstResponder()
            searchController.searchBar.text = " "
            //searchController.searchBar.sizeToFit()
            searchController.hidesNavigationBarDuringPresentation = true
            searchController.dimsBackgroundDuringPresentation = false
            searchController.searchResultsUpdater = locationSearchController
            searchController.searchBar.delegate = locationSearchController
        }

    }
    
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle = UIBarStyle.default
        doneToolbar.tintColor = UIColor(red: 126/255, green: 158/255, blue: 255/255, alpha: 1)
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(editDone))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        reminderTextView.inputAccessoryView = doneToolbar
        
    }
    
    @objc func editDone() {
        reminderTextView.resignFirstResponder()
    }
    
}

protocol HandleMapSearch: class {
    func dropInZoom(placemark: MKPlacemark)
}

extension ReminderViewController: HandleMapSearch {
    
    // MARK: - Delegate Methods
    
    func dropInZoom(placemark: MKPlacemark) {
        selectedLocation = placemark
        
        addMapAnnonation(for: selectedLocation)
        addMapOverlay(for: selectedLocation)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        
        map.setRegion(region, animated: true)
    }
    
    // MARK: - Helper
    
    func addMapAnnonation(for place: MKPlacemark?) {
        map.removeAnnotations(map.annotations)
        guard let place = place else { return }
        let annotation = MKPointAnnotation()
        annotation.coordinate = place.coordinate
        annotation.title = place.name
        
        if let city = place.locality,
            let state = place.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        
        map.addAnnotation(annotation)
    }
    
    func addMapOverlay(for place: MKPlacemark?) {
        map.removeOverlays(map.overlays)
        guard let place = place else { return }
        let circle = MKCircle(center: place.coordinate, radius: 50.0)
        map.addOverlay(circle)
    }
    
}

extension ReminderViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let brandColor = UIColor(red: 126/255, green: 158/255, blue: 255/255, alpha: 0.3)
        
        if overlay.isKind(of: MKCircle.self){
            regionBoundry = overlay as? MKCircle
            if perimeter == .whenIArrive {
                let renderer = MKCircleRenderer(overlay: overlay)
                renderer.fillColor = brandColor
                renderer.strokeColor = UIColor.black
                renderer.lineWidth = 2.0
                return renderer
            } else if perimeter == .whenILeave {
                let renderer = InvertCircleRenderer(circle: overlay as! MKCircle)
                return renderer
            }
            
        }
        
        if overlay.isKind(of: MKPolygon.self) {
            let polygonRenderer = MKPolygonRenderer(overlay: overlay)
            polygonRenderer.fillColor = brandColor
            return polygonRenderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    
    }
    
}

class InvertCircleRenderer: MKOverlayRenderer {
    
    var circle: MKCircle
    var fillColor = UIColor(red: 126/255, green: 158/255, blue: 255/255, alpha: 0.3)
    
    init(circle: MKCircle) {
        self.circle = circle
        super.init(overlay: circle)
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        
        let path = UIBezierPath(rect: rect(for: MKMapRect.world))
        let roundedRect = CGRect(x: mapRect.size.width / 2 - mapRect.size.height / 2, y: 0.0, width: circle.boundingMapRect.size.width, height: circle.boundingMapRect.size.height)
        let newCircle = UIBezierPath(ovalIn: roundedRect)
        
        path.append(newCircle)
        
        context.addPath(path.cgPath)
        context.setFillColor(fillColor.cgColor)
        context.fillPath(using: .evenOdd)
        context.addPath(newCircle.cgPath)
        context.setLineWidth(4 / zoomScale)
        context.setStrokeColor(UIColor.black.cgColor)
        context.strokePath()
        
    }

}

extension ReminderViewController: LocationManagerDelegate {
    
    func obtainedCoordinates(_ coordinate: Coordinate) {
        locationActivityIndicator.stopAnimating()
        setLocationButton.isEnabled = true
        configureMap(with: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
    
    func failedWithError(_ error: LocationError) {
        print("Error")
        showAlert(with: "Error", and: error.localizedDescription)
    }
    
    // MARK: - Helper
    
    func getLocation() {
        
        if !locationManager.isAuthorized {
            do {
                try locationManager.requestLocationAuthorization()
            } catch LocationError.disallowedByUser {
                showSettingsAlert(with: "No Access", and: "Please allow location services in the settings to proceed.")
            } catch {
                fatalError()
            }
        } else {
            locationManager.requestLocation()
        }
        
    }

}
