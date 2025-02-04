//
//  ConstructorIOAutocompleteTests.swift
//  Constructor.io
//
//  Copyright © Constructor.io. All rights reserved.
//  http://constructor.io/
//

import XCTest
import ConstructorAutocomplete

class ConstructorIOAutocompleteTests: XCTestCase {

    var constructor: ConstructorIO!

    override func setUp() {
        super.setUp()
        self.constructor = TestConstants.testConstructor()
    }

    func testAutocomplete_With200() {
        let term = "a term"
        let query = CIOAutocompleteQuery(query: term)

        let builder = CIOBuilder(expectation: "Calling Autocomplete with 200 should return a response", builder: http(200))
        stub(regex("https://ac.cnstrc.com/autocomplete/a%20term?_dt=\(kRegexTimestamp)&c=\(kRegexVersion)&i=\(kRegexClientID)&key=\(kRegexAutocompleteKey)&s=\(kRegexSession)"), builder.create())

        self.constructor.autocomplete(forQuery: query) { _ in }
        self.wait(for: builder.expectation)
    }

    func testAutocomplete_WithNoConnectivity() {
        let expectation = self.expectation(description: "Calling autocomplete with no connectvity should return noConnectivity CIOError.")
        let term = "a term"
        let query = CIOAutocompleteQuery(query: term)

        stub(regex("https://ac.cnstrc.com/autocomplete/a%20term?_dt=\(kRegexTimestamp)&c=\(kRegexVersion)&i=\(kRegexClientID)&key=\(kRegexAutocompleteKey)&s=\(kRegexSession)"), noConnectivity())

        self.constructor.autocomplete(forQuery: query) { response in
            if let error = response.error as? CIOError {
                XCTAssertEqual(error, CIOError(errorType: .noConnection), "Returned error from network client should be type CIOError.noConnection.")
                expectation.fulfill()
            }
        }
        self.wait(for: expectation)
    }

    func testAutocomplete_With400() {
        let expectation = self.expectation(description: "Calling autocomplete with 400 should return badRequest CIOError.")
        let term = "a term"
        let query = CIOAutocompleteQuery(query: term)

        stub(regex("https://ac.cnstrc.com/autocomplete/a%20term?_dt=\(kRegexTimestamp)&c=\(kRegexVersion)&i=\(kRegexClientID)&key=\(kRegexAutocompleteKey)&s=\(kRegexSession)"), http(400))

        self.constructor.autocomplete(forQuery: query) { response in
            if let error = response.error as? CIOError {
                XCTAssertEqual(error.errorType, .badRequest, "Returned error from network client should be type CIOError.badRequest.")
                expectation.fulfill()
            }
        }
        self.wait(for: expectation)
    }

    func testAutocomplete_With400AndErrorMessage() {
        let expectation = self.expectation(description: "Calling autocomplete with 500 should return internalServerError CIOError.")
        let term = "a term"
        let query = CIOAutocompleteQuery(query: term)
        let errorData = "{\"message\":\"Unknown parameter has been supplied in the request\"}".data(using: .utf8)!

        stub(regex("https://ac.cnstrc.com/autocomplete/a%20term?_dt=\(kRegexTimestamp)&c=\(kRegexVersion)&i=\(kRegexClientID)&key=\(kRegexAutocompleteKey)&s=\(kRegexSession)"), http(400, data: errorData))

        self.constructor.autocomplete(forQuery: query) { response in
            if let error = response.error as? CIOError {
                XCTAssertEqual(error, CIOError(errorType: .badRequest, errorMessage: "Unknown parameter has been supplied in the request"), "Returned error from network client should be type CIOError, badRequest, and contain an error message.")
                expectation.fulfill()
            }
        }
        self.wait(for: expectation)
    }

    func testAutocomplete_With500() {
        let expectation = self.expectation(description: "Calling autocomplete with 500 should return internalServerError CIOError.")
        let term = "a term"
        let query = CIOAutocompleteQuery(query: term)

        stub(regex("https://ac.cnstrc.com/autocomplete/a%20term?_dt=\(kRegexTimestamp)&c=\(kRegexVersion)&i=\(kRegexClientID)&key=\(kRegexAutocompleteKey)&s=\(kRegexSession)"), http(500))

        self.constructor.autocomplete(forQuery: query) { response in
            if let error = response.error as? CIOError {
                XCTAssertEqual(error.errorType, .internalServerError, "Returned error from network client should be type CIOError, internalServerError.")
                expectation.fulfill()
            }
        }
        self.wait(for: expectation)
    }

}
