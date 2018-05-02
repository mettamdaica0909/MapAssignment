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
    private var suggestResults:[AGSSuggestResult]!
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
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as! LocationCell
        
        if (self.suggestResults.count > 0) {
            let suggestResult = self.suggestResults[indexPath.row]
            cell.contentLabel.text = suggestResult.label
            cell.locationImage.isHidden = false
        } else {
            cell.contentLabel.text = "There is no result"
            cell.locationImage.isHidden = true
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.locatorTask.geocode(with: self.suggestResults[indexPath.row]) { (result, error) in
            if let error = error {
                print("Error : %@",error.localizedDescription)
            } else {
                // create a graphic for the first result and add to the graphics overlay
                let graphic = self.graphicForPoint((result?.first?.displayLocation)!, attributes: result?.first?.attributes as [String : AnyObject]?)
                self.graphicsOverlay.graphics.add(graphic)
                //zoom to the extent of the result
                if let extent = result?.first?.extent {
                    self.mapView.setViewpointGeometry(extent, completion: nil)
                }
                self.searchBar.text = self.suggestResults[indexPath.row].label
                self.view.endEditing(true)
                self.animateTableView(expand: false)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    private func animateTableView(expand:Bool) {
        if (expand != self.isTableViewVisible) && !self.isTableViewAnimating {
            self.isTableViewAnimating = true
            self.tableviewheightContrains.constant = expand ? CGFloat(self.suggestResults.count * 44) : 0
            UIView.animate(withDuration: 0.1, animations: { [weak self] () -> Void in
                self?.view.layoutIfNeeded()
                }, completion: { [weak self] (finished) -> Void in
                    self?.isTableViewAnimating = false
                    self?.isTableViewVisible = expand
            })
        }
    }
    
    private func getSuggestions(searchString : String) {
        //remove all previous graphics
        self.graphicsOverlay.graphics.removeAllObjects()
        
        if self.suggestRequestOperation != nil {
            self.suggestRequestOperation.cancel()
        }
        
        self.suggestRequestOperation = self.locatorTask.suggest(withSearchText: searchString, completion: { (result, error) in
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
        })
    }
    
    private func graphicForPoint(_ point: AGSPoint, attributes: [String: AnyObject]?) -> AGSGraphic {
        let markerImage = UIImage(named: "location-marker")!
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
