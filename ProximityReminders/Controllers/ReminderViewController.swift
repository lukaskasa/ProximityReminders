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

class ReminderViewController: UIViewController {
    
    // MARK: -  Outlets
    @IBOutlet weak var reminderTextView: UITextView!
    @IBOutlet weak var arriveLeaveSegmentControl: UISegmentedControl!
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var perimeterSegmentControl: UISegmentedControl!
    @IBOutlet weak var setLocationButton: UIButton!
    @IBOutlet weak var locationActivityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    let map = MKMapView()
    var locationSearchController: LocationSearchController?
    var selectedLocation: MKPlacemark?
    var managedObjectContext: NSManagedObjectContext!
    var reminder: Reminder?
    var perimeter: Perimeter = .whenIArrive
    var regionBoundry: MKCircle?
    
    // Enum to represent the options when a notification should be trigerred
    enum Perimeter {
        case whenIArrive, whenILeave
    }
    
    lazy var locationManager: LocationManager = {
        return LocationManager(delegate: self, viewController: self)
    }()
    
    lazy var notificationManager: NotificationManager = {
        return NotificationManager(viewController: nil)
    }()
    
    lazy var resultSearchController: UISearchController = {
        return UISearchController(searchResultsController: locationSearchController)
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup
        map.delegate = self
        reminderTextView.delegate = self
        locationActivityIndicator.startAnimating()
        locationSearchController = (storyboard!.instantiateViewController(withIdentifier: String(describing: LocationSearchController.self)) as! LocationSearchController)
        locationSearchController?.handleMapSearchDelegate = self
        setupSearchBar()
        addDoneButtonOnKeyboard()
        configureSaveButton()
        configureReminder()
    }
    
    // MARK: - Actions
    
    /// Segmentcontrol action to select when the region notification should be triggered
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
    
    /// Setup searchbar when user wants to search for a location
    @IBAction func searchLocation(_ sender: Any) {
        resultSearchController.isActive = true
        resultSearchController.searchBar.becomeFirstResponder()
    }
    
    // MARK: - Helper Methods
    
    /// Configure the save button for the navigation bar
    func configureSaveButton() {
        let saveButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveReminder))
        navigationItem.rightBarButtonItem = saveButton
    }
    
    /// Save a new or existing reminder to the database
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
    
    /// Get the address using the geographical coordinates and save it for the reminder
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
                    self.showSettingsAlert(with: "Error", and: "Please check your settings! Wi-Fi and Location services are required!")
                }
                
            }
            
        }
    }
    
    /// Configure an existing reminder
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
                    if error == nil {
                        self.selectedLocation = MKPlacemark(placemark: place)
                        self.configureMap(with: location)
                    } else {
                        self.showAlert(with: "Error", and: error!.localizedDescription)
                    }
                }

            }
        }
        
    }
    
    /// Configures the map view using the provided location
    func configureMap(with location: CLLocation) {
        map.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(map)
        let span = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        addMapAnnonation(for: selectedLocation)
        addMapOverlay(for: selectedLocation)
        map.setRegion(region, animated: true)
        map.showsUserLocation = true
        map.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 0).isActive = true
        map.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: 0).isActive = true
        map.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 0).isActive = true
        map.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 0).isActive = true
    }
    
    /// Configures the searchbar to be able to search for locations
    func setupSearchBar() {
        definesPresentationContext = true
        locationSearchController?.mapView = map
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = resultSearchController
        resultSearchController.searchBar.barStyle = .default
        resultSearchController.searchBar.tintColor = .white
        resultSearchController.searchBar.setTextColor(color: .black)
        resultSearchController.hidesNavigationBarDuringPresentation = false
        resultSearchController.obscuresBackgroundDuringPresentation = true
        resultSearchController.searchResultsUpdater = locationSearchController
        resultSearchController.searchBar.delegate = locationSearchController
        
        if #available(iOS 13.0, *) {
            resultSearchController.showsSearchResultsController = true
        } else {
            resultSearchController.searchBar.text = " "
        }
    }
    
    /// Adds a 'Done' button to the keyboard tool bar to be able to dismiss the keyboard
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
    
    /// Resigns the text view as first responder
    @objc func editDone() {
        reminderTextView.resignFirstResponder()
    }
    
}

/// UITextViewDelegate
/// Apple documentation: https://developer.apple.com/documentation/uikit/uitextviewdelegate
extension ReminderViewController: UITextViewDelegate {
    
    /// Tells the delegate that editing of the specified text view has begun.
    /// Apple documentation: https://developer.apple.com/documentation/uikit/uitextviewdelegate/1618610-textviewdidbeginediting
    func textViewDidBeginEditing(_ textView: UITextView) {
        if reminder == nil {
            textView.text = ""
        }
    }
    
}

/// Protocol to handle the map search result returned from the LocationSearchController
protocol HandleMapSearch: class {
    func dropInZoom(placemark: MKPlacemark)
}

// MARK: - HandleMapSearch
extension ReminderViewController: HandleMapSearch {
    
    // MARK: - Delegate Methods
    /// Navigates to the location on the map once a location is selected by the user
    func dropInZoom(placemark: MKPlacemark) {
        selectedLocation = placemark
        
        addMapAnnonation(for: selectedLocation)
        addMapOverlay(for: selectedLocation)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        
        map.setRegion(region, animated: true)
    }
    
    // MARK: - Helper
    
    /// Adds annotation onto the map for the provided placemark
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
    
    /// Adds overlay onto the map for the provided placemark
    func addMapOverlay(for place: MKPlacemark?) {
        map.removeOverlays(map.overlays)
        guard let place = place else { return }
        let circle = MKCircle(center: place.coordinate, radius: 50.0)
        map.addOverlay(circle)
    }
    
}

// MARK: - MKMapViewDelegate
/// Apple documentation: https://developer.apple.com/documentation/mapkit/mkmapviewdelegate
extension ReminderViewController: MKMapViewDelegate {
    
    /// Asks the delegate for a renderer object to use when drawing the specified overlay.
    /// Apple documentation: https://developer.apple.com/documentation/mapkit/mkmapviewdelegate/1452203-mapview
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        /// Define the brand color
        let brandColor = UIColor(red: 126/255, green: 158/255, blue: 255/255, alpha: 0.3)
        
        /// If the overlay is a MKCircle and dependent which perimeter is selected
        /// the correct Renderer is used to draw the overlay on the map
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
        
        return MKOverlayRenderer(overlay: overlay)
    }
    
}
// MARK: - InvertCircleRenderer: Renderer to color the outside of the circle
class InvertCircleRenderer: MKOverlayRenderer {
    
    /// Properties
    var circle: MKCircle
    var fillColor = UIColor(red: 126/255, green: 158/255, blue: 255/255, alpha: 0.3)
    
    /// Rendered intialization
    init(circle: MKCircle) {
        self.circle = circle
        super.init(overlay: circle)
    }
    
    /// Override draw method to draw a circle where everything outside is colored
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

// MARK: - LocationManagerDelegate
extension ReminderViewController: LocationManagerDelegate {
    
    /// Called when the coordinated to the user location are received
    func obtainedCoordinates(_ coordinate: Coordinate) {
        locationActivityIndicator.stopAnimating()
        setLocationButton.isEnabled = true
        configureMap(with: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
    
    /// Called when an error occurs during the location request
    func failedWithError(_ error: LocationError) {
        
        if error == .disallowedByUser {
            showAlert(with: "Error", and: "Dissallowed by user!")
        } else if error == .locationServicesUnavailable {
            showAlert(with: "Error", and: "Location services unavailable!")
        } else {
            showAlert(with: "Error", and: "Please check your settings! Wi-Fi and Location services are required!")
        }
        
    }
    
    // MARK: - Helper
    
    func locationServicesAvailable() -> Bool {
        if !locationManager.isAuthorized {
            do {
                try locationManager.requestLocationAuthorization()
            } catch LocationError.disallowedByUser {
                showSettingsAlert(with: "No Access", and: "Please allow location services in the settings to proceed.")
            }
            catch LocationError.locationServicesUnavailable {
                showSettingsAlert(with: "Location services unavailable", and: "Please enable location services to use region monitoring.")
            } catch {
                fatalError()
            }
        } else {
            return true
        }
        
        return false
    }
    
    /// Request the current location
    func getLocation() {
        if locationServicesAvailable() {
            locationManager.requestLocation()
        }
    }

}
