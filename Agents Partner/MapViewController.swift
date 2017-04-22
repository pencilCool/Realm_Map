/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import MapKit
import CoreLocation
import RealmSwift


class MapViewController: UIViewController {
  
  @IBOutlet weak var mapView: MKMapView!
  
  let kDistanceMeters: CLLocationDistance = 500
  
  var locationManager = CLLocationManager()
  var userLocated = false
  var lastAnnotation: MKAnnotation!
    
    
  var specimens = try! Realm().objects(Specimen.self)
  
  //MARK: - Helper Methods
    
    func populateMap() {
        mapView.removeAnnotations(mapView.annotations) // 1 清除所有地图上的标记
        
        specimens = try! Realm().objects(Specimen) // 2
        
        // Create annotations for each one
        for specimen in specimens { // 3
            let coord = CLLocationCoordinate2D(latitude: specimen.latitude, longitude: specimen.longitude);
            let specimenAnnotation = SpecimenAnnotation(coordinate: coord,
                                                        title: specimen.name,
                                                        subtitle: specimen.category.name,
                                                        specimen: specimen)
            mapView.addAnnotation(specimenAnnotation) // 4
        }
    }
    
  
  func centerToUsersLocation() {
    let center = mapView.userLocation.coordinate
    let zoomRegion: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(center, kDistanceMeters, kDistanceMeters)
    mapView.setRegion(zoomRegion, animated: true)
  }
  
  func addNewPin() {
    if lastAnnotation != nil {
      let alertController = UIAlertController(title: "Annotation already dropped", message: "There is an annotation on screen. Try dragging it if you want to change its location!", preferredStyle: .alert)
      let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.destructive) { alert in
        alertController.dismiss(animated: true, completion: nil)
      }
      alertController.addAction(alertAction)
      present(alertController, animated: true, completion: nil)
      
    } else {
      let specimen = SpecimenAnnotation(coordinate: mapView.centerCoordinate, title: "Empty", subtitle: "Uncategorized")
      
      mapView.addAnnotation(specimen)
      lastAnnotation = specimen
    }
  }
  
  //MARK: - View Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    print(Realm.Configuration.defaultConfiguration.description)
    title = "Map"
    
    locationManager.delegate = self
    
    if CLLocationManager.authorizationStatus() == .notDetermined {
      locationManager.requestWhenInUseAuthorization()
    } else {
      locationManager.startUpdatingLocation()
    }
    
    populateMap()
    
  }
  
  //MARK: - Actions & Segues
  
  @IBAction func centerToUserLocationTapped(_ sender: AnyObject) {
    centerToUsersLocation()
  }
  
  @IBAction func addNewEntryTapped(_ sender: AnyObject) {
    addNewPin()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
    if (segue.identifier == "NewEntry") {
      let controller = segue.destination as! AddNewEntryController
      let specimenAnnotation = sender as! SpecimenAnnotation
      controller.selectedAnnotation = specimenAnnotation
    }
  }
  
  @IBAction func unwindFromAddNewEntry(_ segue: UIStoryboardSegue) {
    let addNewEntryController = segue.source as! AddNewEntryController
    let addedSpecimen = addNewEntryController.specimen
    let addedSpecimenCoordinate = CLLocationCoordinate2D(latitude: (addedSpecimen?.latitude)!, longitude: (addedSpecimen?.longitude)!)
    
    if let lastAnnotation = lastAnnotation {
        mapView.removeAnnotation(lastAnnotation)
    } else {
        for annotation in mapView.annotations {
            if let currentAnnotation = annotation as? SpecimenAnnotation {
                if currentAnnotation.coordinate.latitude == addedSpecimenCoordinate.latitude && currentAnnotation.coordinate.longitude == addedSpecimenCoordinate.longitude {
                    mapView.removeAnnotation(currentAnnotation)
                    break
                }
            }
        }
    }
    
    let annotation = SpecimenAnnotation(coordinate: addedSpecimenCoordinate, title: (addedSpecimen?.name)!, subtitle: (addedSpecimen?.category.name)!, specimen: addedSpecimen)
    
    mapView.addAnnotation(annotation)
    lastAnnotation = nil;
  }
  
}

//MARK: - CLLocationManager Delegate
extension MapViewController: CLLocationManagerDelegate {
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    status != .notDetermined ? mapView.showsUserLocation = true : print("Authorization to use location data denied")
  }
}

//MARK: - MKMapview Delegate
extension MapViewController: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

    guard let subtitle = annotation.subtitle! else { return nil }
    
    if (annotation is SpecimenAnnotation) {
      if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: subtitle) {
        return annotationView
      } else {
        
        let currentAnnotation = annotation as! SpecimenAnnotation
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: subtitle)
        
        switch subtitle {
        case "Uncategorized":
          annotationView.image = UIImage(named: "IconUncategorized")
        case "Arachnids":
          annotationView.image = UIImage(named: "IconArachnid")
        case "Birds":
          annotationView.image = UIImage(named: "IconBird")
        case "Mammals":
          annotationView.image = UIImage(named: "IconMammal")
        case "Flora":
          annotationView.image = UIImage(named: "IconFlora")
        case "Reptiles":
          annotationView.image = UIImage(named: "IconReptile")
        default:
          annotationView.image = UIImage(named: "IconUncategorized")
        }
        
        annotationView.isEnabled = true
        annotationView.canShowCallout = true
        let detailDisclosure = UIButton(type: UIButtonType.detailDisclosure)
        annotationView.rightCalloutAccessoryView = detailDisclosure
        
        if currentAnnotation.title == "Empty" {
          annotationView.isDraggable = true
        }
        
        return annotationView
      }
    }
    return nil
    
    
  }
  
  func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
    
    for annotationView in views {
      if (annotationView.annotation is SpecimenAnnotation) {
        annotationView.transform = CGAffineTransform(translationX: 0, y: -500)
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveLinear, animations: {
          annotationView.transform = CGAffineTransform(translationX: 0, y: 0)
          }, completion: nil)
      }
    }
    
  }
  
  func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    if let specimenAnnotation =  annotationView.annotation as? SpecimenAnnotation {
      performSegue(withIdentifier: "NewEntry", sender: specimenAnnotation)
    }
  }
  
  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
    if newState == .ending {
      view.dragState = .none
    }
  }
}
