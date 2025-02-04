//
//  BrowseResponseParser.swift
//  AutocompleteClient
//
//  Copyright © Constructor.io. All rights reserved.
//  http://constructor.io/
//

import Foundation

class BrowseResponseParser: AbstractBrowseResponseParser {
    func parse(browseResponseData: Data) throws -> CIOBrowseResponse {

        do {
            let json = try JSONSerialization.jsonObject(with: browseResponseData) as? JSONObject

            guard let response = json?["response"] as? JSONObject else {
                throw CIOError(errorType: .invalidResponse)
            }

            let facetsObj: [JSONObject]? = response["facets"] as? [JSONObject]
            let resultsObj: [JSONObject]? = response["results"] as? [JSONObject]
            let sortOptionsObj: [JSONObject]? = response["sort_options"] as? [JSONObject]
            let groupsObj = response["groups"] as? [JSONObject]

            let facets: [CIOFilterFacet] = (facetsObj)?.compactMap { obj in return CIOFilterFacet(json: obj) } ?? []
            let results: [CIOResult] = (resultsObj)?.compactMap { obj in return CIOResult(json: obj) } ?? []
            let sortOptions: [CIOSortOption] = (sortOptionsObj)?.compactMap({ obj  in return CIOSortOption(json: obj) }) ?? []
            let groups: [CIOFilterGroup] = groupsObj?.compactMap({ obj  in return CIOFilterGroup(json: obj) }) ?? []
            let totalNumResults = response["total_num_results"] as? Int ?? 0
            let resultID = json?["result_id"] as? String ?? ""

            return CIOBrowseResponse(
                facets: facets,
                groups: groups,
                results: results,
                sortOptions: sortOptions,
                totalNumResults: totalNumResults,
                resultID: resultID
            )
        } catch {
            throw CIOError(errorType: .invalidResponse)
        }

    }
}
