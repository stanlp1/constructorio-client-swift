//
//  TrackConversionRequestBuilder.swift
//  Constructor.io
//
//  Copyright © Constructor.io. All rights reserved.
//  http://constructor.io/
//

import Foundation

class TrackConversionRequestBuilder: RequestBuilder {

    private var searchTerm = ""

    init(tracker: CIOConversionTrackData, autocompleteKey: String) {
        super.init(autocompleteKey: autocompleteKey)
        set(searchTerm: tracker.searchTerm)
        set(itemName: tracker.itemName)
        set(itemID: tracker.itemID)
        set(autocompleteSection: tracker.sectionName)
        set(revenue: tracker.revenue)
    }

    func set(searchTerm: String) {
        self.searchTerm = searchTerm
    }

    func set(itemID: String?) {
        guard let itemID = itemID else { return }
        queryItems.add(URLQueryItem(name: Constants.TrackConversion.itemId, value: itemID))
    }
    
    func set(itemName: String?) {
        guard let itemName = itemName else { return }
        queryItems.add(URLQueryItem(name: Constants.TrackConversion.item, value: itemName))
    }

    func set(autocompleteSection: String?) {
        guard let sectionName = autocompleteSection else { return }
        queryItems.add(URLQueryItem(name: Constants.TrackAutocomplete.autocompleteSection, value: sectionName))
    }

    func set(revenue: Int?) {
        guard let revenue = revenue else { return }
        queryItems.add(URLQueryItem(name: Constants.TrackConversion.revenue, value: String(revenue)))
    }

    override func getURLString() -> String {
        return String(format: Constants.Track.trackStringFormat, Constants.Track.baseURLString, Constants.TrackAutocomplete.pathString, searchTerm.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!, Constants.TrackConversion.type)
    }

}
