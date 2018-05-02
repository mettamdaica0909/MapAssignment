//
//  ViewController.swift
//  Assignment
//
//  Created by Mettamdaica on 4/27/18.
//  Copyright © 2018 Duy Le. All rights reserved.
//

import UIKit
import ArcGIS

class ViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableviewheightContrains: NSLayoutConstraint!
    
    private var locatorTask:AGSLocatorTask!
    private var suggestRequestOperation:AGSCancelable!
    private var suggestResults:[AGSGeocodeResult]!
    private var graphicsOverlay:AGSGraphicsOverlay!

    
    private var isTableViewVisible = true
    private var isTableViewAnimating = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // init mapview
        self.mapView.map = AGSMap(basemap: AGSBasemap.openStreetMap())
        
        // display device location
        self.mapView.locationDisplay.autoPanMode = .recenter
        self.mapView.locationDisplay.start { (error : Error?) -> Void in
            if let error = error {
                self.showAlert(error.localizedDescription, okHandler: nil)
            }
        }
        
        // init locatorTask
        self.locatorTask = AGSLocatorTask(url: URL(string: "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer")!)
        self.animateTableView(expand: false)
        
        //initialize the graphics overlay and add to the map view
        self.graphicsOverlay = AGSGraphicsOverlay()
        self.mapView.graphicsOverlays.add(self.graphicsOverlay)
        
        self.searchBar.placeholder = "Enter place"
    }
    
    
    //MARK : searchbar delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchBar.text ?? "")
        self.getSuggestions(searchString: searchBar.text ?? "")
    }
    
    //MARK : tableview delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = 0
        if let count = self.suggestResults?.count {
            rows = count
        }
        self.animateTableView(expand: rows > 0)
        return rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellID")!
    
        let suggestResult = self.suggestResults[indexPath.row]
        cell.textLabel?.text = suggestResult.label
        cell.imageView?.image = nil
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //create a graphic for the first result and add to the graphics overlay
        let graphic = self.graphicForPoint(self.suggestResults[indexPath.row].displayLocation!, attributes: self.suggestResults[indexPath.row].attributes as [String : AnyObject]?)
        self.graphicsOverlay.graphics.add(graphic)
        //zoom to the extent of the result
        if let extent = self.suggestResults[indexPath.row].extent {
            self.mapView.setViewpointGeometry(extent, completion: nil)
        }
        self.searchBar.text = self.suggestResults[indexPath.row].label
        self.view.endEditing(true)
        self.animateTableView(expand: false)
    }
    
    private func animateTableView(expand:Bool) {
        if (expand != self.isTableViewVisible) && !self.isTableViewAnimating {
            self.isTableViewAnimating = true
            self.tableviewheightContrains.constant = expand ? CGFloat(self.suggestResults.count * 50) : 0
            UIView.animate(withDuration: 0.1, animations: { [weak self] () -> Void in
                self?.view.layoutIfNeeded()
                }, completion: { [weak self] (finished) -> Void in
                    self?.isTableViewAnimating = false
                    self?.isTableViewVisible = expand
            })
        }
    }
    
    private func getSuggestions(searchString : String) {
        if self.suggestRequestOperation != nil {
            self.suggestRequestOperation.cancel()
        }
        
        let suggestParameters = AGSGeocodeParameters()
//        let currentExtent = self.mapView.currentViewpoint(with: AGSViewpointType.boundingGeometry)?.targetGeometry
        suggestParameters.searchArea = self.mapView.
        suggestParameters.countryCode = "Vietnam"
        suggestParameters.maxResults = 10
    
        self.suggestRequestOperation = self.locatorTask.geocode(withSearchText: searchString, parameters: suggestParameters) { (result: [AGSGeocodeResult]?, error: Error?) -> Void in
            if let error = error {
                print(error.localizedDescription)
                self.suggestResults = []
                self.tableView.reloadData()
            }
            else {
                //update the suggest results and reload the table
                self.suggestResults = result
                self.tableView.reloadData()
            }
        }
    }
    
    private func graphicForPoint(_ point: AGSPoint, attributes: [String: AnyObject]?) -> AGSGraphic {
        let markerImage = UIImage(named: "icons8-map-pin-48")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height/2
        symbol.offsetY = markerImage.size.height/2
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: attributes)
        return graphic
    }
    
    
    @IBAction func zoomOut(_ sender: Any) {
        self.zoom(isZoomIn: false)
    }
    @IBAction func zoomIn(_ sender: Any) {
        self.zoom(isZoomIn: true)
    }
    @IBAction func reCenter(_ sender: Any) {
        self.mapView.locationDisplay.autoPanMode = .recenter
        self.mapView.locationDisplay.start { (error : Error?) in
            if let error = error {
                print("location display start failure")
            } else {
                print("success")
            }
        }
    }
    
    private func zoom(isZoomIn : Bool) {
        let currentScale = self.mapView.mapScale
        
        let newScale = isZoomIn ? currentScale / 2 : currentScale * 2
        guard let currentCenter = self.mapView.visibleArea?.extent.center else {
            return
        }
        
        self.mapView.setViewpoint(AGSViewpoint(center: currentCenter, scale: newScale), duration: 1, curve: AGSAnimationCurve.easeInOutSine) { (finishedWithoutInterruption) -> Void in
            // TODO
        }
    }
}

