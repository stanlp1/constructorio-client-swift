//
//  CIOSearchQuery.swift
//  Constructor.io
//
//  Copyright © Constructor.io. All rights reserved.
//  http://constructor.io/
//

import Foundation

/**
 Struct encapsulating the necessary and additional parameters required to execute a search query.
 */
public struct CIOSearchQuery: CIORequestData {
    /**
     The user typed query to return results for
     */
    public let query: String

    /**
     The filters used to refine results
     */
    public let filters: CIOQueryFilters?

    /**
     The page number of the results
     */
    public let page: Int

    /**
     The number of results per page to return
     */
    public let perPage: Int

    /**
     The sort method/order for results
     */
    public let sortOption: CIOSortOption?

    /**
     The section to return results from
     */
    public let section: String
    
    /**
     The list of hidden metadata fields to return
     */
    public let hiddenFields: [String]?

    func url(with baseURL: String) -> String {
        return String(format: Constants.SearchQuery.format, baseURL, query)
    }

    /**
     Create a Search request query object
     
     - Parameters:
        - query: The user typed query to return results for
        - filters: The filters used to refine results
        - page: The page number of the results
        - perPage: The number of results per page to return
        - sortOption: The sort method/order for results
        - section: The section to return results from
        - hiddenFields: The list of hidden metadata fields to return
     
     ### Usge Example: ###
     ```
     let facetFilters = [(key: "Nutrition", value: "Organic"),
                         (key: "Nutrition", value: "Natural"),
                         (key: "Brand", value: "Kraft Foods")]

     let searchQuery = CIOSearchQuery(query: "red", filters: CIOQueryFilters(groupFilter: nil, facetFilters: facetFilters), page: 1, perPage: 30, section: "Products", hiddenFields: ["price_CA", "currency_CA"])
     ```
     */
    public init(query: String, filters: CIOQueryFilters? = nil, sortOption: CIOSortOption? = nil, page: Int = 1, perPage: Int = 30, section: String? = nil, hiddenFields: [String]? = nil) {
        self.query = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        self.filters = filters
        self.page = page
        self.perPage = perPage
        self.section = section != nil ? section! : Constants.SearchQuery.defaultSectionName
        self.sortOption = sortOption
        self.hiddenFields = hiddenFields
    }

    func decorateRequest(requestBuilder: RequestBuilder) {
        requestBuilder.set(page: self.page)
        requestBuilder.set(perPage: self.perPage)
        requestBuilder.set(groupFilter: self.filters?.groupFilter)
        requestBuilder.set(facetFilters: self.filters?.facetFilters)
        requestBuilder.set(searchSection: self.section)
        requestBuilder.set(sortOption: self.sortOption)
        requestBuilder.set(hiddenFields: self.hiddenFields)
    }
}
