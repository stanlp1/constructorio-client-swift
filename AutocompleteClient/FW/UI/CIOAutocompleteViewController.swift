//
//  CIOAutocompleteViewController.swift
//  Constructor.io
//
//  Copyright © Constructor.io. All rights reserved.
//  http://constructor.io/
//

import UIKit

/**
 Default view controller for displaying Autocomplete results.
 */

public class CIOAutocompleteViewController: UIViewController {
    private static let __bundle = Bundle(for: CIOAutocompleteViewController.self)
    private static var bundle: Bundle{
        get{
            if let bundleURL = __bundle.url(forResource: "ConstructorAutocomplete", withExtension: "bundle"),
               let bundle = Bundle(url: bundleURL) {
                return bundle
            }else{
                return __bundle
            }
        }
    }
    
    /**
     A flag that determines whether the cancel button should show when search bar gains focus.
     */
    public var searchBarShouldShowCancelButton: Bool = false{
        didSet{
            (self.searchController?.searchBar as? CustomSearchBar)?.shouldShowCancelButton = self.searchBarShouldShowCancelButton
        }
    }
    
    /**
     Defines how search bar should be displayed.
     */
    public var searchBarDisplayMode: CIOSearchBarDisplayMode = .TableViewHeader
    
    /**
     Results table view.
     */
    public weak var tableView: UITableView!
    
    public override var preferredStatusBarStyle: UIStatusBarStyle{
        return self.customStatusBarStyle
    }
    
    /**
     Custom status bar style
     */
    public var customStatusBarStyle: UIStatusBarStyle = .default
    
    /**
     Results search controller.
     */
    public var searchController: UISearchController!
    
    fileprivate var errorView: CIOErrorView?
    
    fileprivate var viewModel: AutocompleteViewModel = AutocompleteViewModel()
    
    /**
     Default constructorIO instance.
     */
    private(set) public var constructorIO: ConstructorIO!
    
    /**
     Autocomplete key. Make sure to set this value before showing the view controller.
     */
    public var autocompleteKey: String = ""

    /**
     Default highlighter used for displaying result items.
     */
    public var highlighter: CIOHighlighter = CIOHighlighter(attributesProvider:
        BoldAttributesProvider(fontNormal: Constants.UI.Font.defaultFontNormal,
                               fontBold: Constants.UI.Font.defaultFontBold,
                               colorNormal: Constants.UI.Color.defaultFontColorNormal,
                               colorBold: Constants.UI.Color.defaultFontColorBold)
    )

    // MARK: Query Firing
    fileprivate var timerQueryFire: Timer?

    /**
     The object that acts as the data source of the autocomplete view controller.
     The data source must adopt the CIOAutocompleteDataSource protocol. The data source is not retained.
     */
    public weak var dataSource: CIOAutocompleteDataSource?
    
    /**
     The object that acts as the delegate of the autocomplete view controller.
     The data source must adopt the CIOAutocompleteDelegate protocol. The delegate is not retained.
     */
    public weak var delegate: CIOAutocompleteDelegate?

    /**
     The object to configure options for the autocomplete results.
     */
    public var config: AutocompleteConfig?

    // MARK: Fonts
    private var fontNormal: UIFont = Constants.UI.Font.defaultFontNormal
    private var fontBold: UIFont = Constants.UI.Font.defaultFontBold

    /**
     Default initializer for this controller. Pass in the autocomplete key you got from the constructor.io dashboard.
     */
    public init(autocompleteKey: String) {
        super.init(nibName: nil, bundle: nil)
        self.autocompleteKey = autocompleteKey
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = self.viewModel.screenTitle

        // we retain tableView property weakly, so we define a temp var to make sure it doesn't get released before we assign it
        let tblView = UITableView()
        
        self.tableView = tblView
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.fitViewInsideLayoutGuides(self.tableView)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = UIColor.clear
        
        self.searchController = CustomSearchController(searchResultsController: nil)
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchResultsUpdater = self
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.searchBar.delegate = self
        (self.searchController.searchBar as? CustomSearchBar)?.shouldShowCancelButton = self.searchBarShouldShowCancelButton
        
        self.searchController.searchBar.sizeToFit()
        
        switch(self.searchBarDisplayMode){
            case .TableViewHeader:
                self.tableView.tableHeaderView = self.searchController.searchBar
            case .NavigationBar:
                self.navigationItem.titleView = self.searchController.searchBar
        }
        
        self.searchController.searchBar.placeholder = self.dataSource?.searchBarPlaceholder?(in: self) ?? Constants.UI.defaultSearchBarPlaceholder
        self.dataSource?.customizeSearchController?(searchController: self.searchController, in: self)

        self.definesPresentationContext = true
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = [.top]
        
        var backgroundView: UIView! = nil

        // show background empty screen
        if let backgroundViewClosure = self.dataSource?.backgroundView {
            // function implemented
            if let view = backgroundViewClosure(self) {
                backgroundView = view
            } else {
                // but it returns nil; it means user doesn't want a background view
            }
        } else {
            // dataSource method not implemented; default to framework's empty screen
            backgroundView = UINib(nibName: "EmptyScreenView", bundle: CIOAutocompleteViewController.bundle).instantiate(withOwner: nil, options: nil).first as! UIView
        }

        if backgroundView != nil {
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.autoresizingMask = []
            self.view.addViewToFit(backgroundView)
        }

        self.view.bringSubview(toFront: self.tableView)

        if let fontNormal = self.dataSource?.fontNormal?(in: self) {
            self.fontNormal = fontNormal

            if let boldAttributesProvider = self.highlighter.attributesProvider as? BoldAttributesProvider {
                boldAttributesProvider.fontNormal = self.fontNormal
            }
        }

        if let fontBold = self.dataSource?.fontBold?(in: self) {
            self.fontBold = fontBold
            if let boldAttributesProvider = self.highlighter.attributesProvider as? BoldAttributesProvider {
                boldAttributesProvider.fontBold = self.fontBold
            }
        }

        // ask the delegate for custom cell class or nib
        if let classRef = self.dataSource?.customCellClass?(in: self) {
            self.tableView.register(classRef, forCellReuseIdentifier: Constants.UI.CellIdentifier)
        } else if let nib = self.dataSource?.customCellNib?(in: self) {
            self.tableView.register(nib, forCellReuseIdentifier: Constants.UI.CellIdentifier)
        } else {
            let nib = UINib(nibName: "DefaultSearchItemCell", bundle: CIOAutocompleteViewController.bundle)
            self.tableView.register(nib, forCellReuseIdentifier: Constants.UI.CellIdentifier)
        }

        self.delegate?.autocompleteControllerDidLoad?(controller: self)

        if autocompleteKey == "" {
            self.delegate?.autocompleteController?(controller: self, errorDidOccur: CIOError.missingAutocompleteKey)
        }

        let userID = DependencyContainer.sharedInstance.userIDGenerator().generateUserID()
        
        self.constructorIO = ConstructorIO(autocompleteKey: autocompleteKey, clientID: userID)
        self.constructorIO.parser.delegate = self
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.delegate?.autocompleteControllerWillAppear?(controller: self)
    }
    
    fileprivate func setResultsReceived(from autocompleteResult: AutocompleteResult) {
        // we have data, hide error view if visible
        self.errorView?.asView().fadeOutAndRemove(duration: Constants.UI.fadeOutDuration)

        // before passing the result to view model, ask the dataSource to provide the custom sort function
        if let customSortFunction = self.dataSource?.sectionSort?(in: self){
            self.viewModel.modelSorter = customSortFunction
        }
        
        self.viewModel.set(searchResult: autocompleteResult) { [weak self] in
            self?.tableView.reloadData()
        }
    }

    fileprivate func displayError(error: Error) {
        var errorView: CIOErrorView

        if let errorViewRef = self.errorView {
            // we already have an error view
            errorView = errorViewRef
        } else {
            let customErrorView = self.dataSource?.errorView?(in: self) as? CIOErrorView
            if customErrorView != nil {
                errorView = customErrorView!
            } else {
                let defaultErrorView = UINib(nibName: "SearchErrorView", bundle: CIOAutocompleteViewController.bundle).instantiate(withOwner: nil, options: nil).first as! SearchErrorView
                defaultErrorView.labelText.font = self.fontNormal
                errorView = defaultErrorView
            }
        }

        if errorView.asView().superview == nil {
            errorView.asView().translatesAutoresizingMaskIntoConstraints = false

            // set constraints
            self.view.addSubview(errorView.asView())
            errorView.asView().pinToSuperviewBottom()
            errorView.asView().pinToSuperviewLeft()
            errorView.asView().pinToSuperviewRight()
            errorView.asView().pinToSuperviewTop(self.searchController.searchBar.frame.size.height)

            // fade in
            errorView.asView().fadeIn(duration: Constants.UI.fadeInDuration)
        }

        // set error string
        errorView.setErrorString(errorString: error.localizedDescription)

        self.errorView = errorView
    }
    
    @objc
    fileprivate func timerFire(timer: Timer) {
        guard let searchTerm = timer.userInfo as? String else {
            return
        }
        
        let query = CIOAutocompleteQuery(query: searchTerm, numResults: config?.numResults, numResultsForSection: config?.numResultsForSection)
        
        // initiatedOn timestamp has to be created before the query is sent, otherwise we might get inconsistent UI results
        let initiatedOn: TimeInterval = NSDate().timeIntervalSince1970
        
        self.constructorIO.autocomplete(forQuery: query) { [weak self] response in
            
            guard let selfRef = self else { return }
            
            // Inform delegate of search
            self?.delegate?.autocompleteController?(controller: selfRef, didPerformSearch: searchTerm)
            
            // Check for errors
            if let error = response.error {
                self?.displayError(error: error)
                self?.delegate?.autocompleteController?(controller: selfRef, errorDidOccur: error)
                return
            }
            
            // No errors
            let response = response.data!
            
            // Display the response
            let result = AutocompleteResult(query: query, timestamp: initiatedOn)
            result.response = response
            self?.setResultsReceived(from: result)
        }
    }

}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension CIOAutocompleteViewController:  UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.results.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.results[section].items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.UI.CellIdentifier)!

        if let defaultCell = cell as? DefaultSearchItemCell {
            self.dataSource?.styleResultCell?(cell: defaultCell, indexPath: indexPath, in: self)
            self.dataSource?.styleResultLabel?(label: defaultCell.labelText, indexPath: indexPath, in: self)
        }

        if let searchCell = cell as? CIOAutocompleteCell {
            let item = self.viewModel.results[indexPath.section].items[indexPath.row]
            searchCell.setup(result: item, searchTerm: self.viewModel.searchTerm, highlighter: self.highlighter)
        } else {
            print("Warning: Trying to show results in a cell that doesn't conform to CIOAutocompleteCell protocol.")
        }

        return cell
    }
    

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        let result = self.viewModel.getResult(atIndexPath: indexPath)
        let sectionName = viewModel.getSectionName(atIndex: indexPath.section)
        
        // Run behavioural tracking 'select' on autocomplete result select
        let selectTracker = CIOAutocompleteClickTrackData(searchTerm: viewModel.searchTerm, clickedItemName: result.autocompleteResult.value, sectionName: sectionName, group: result.group)

        // TODO: For now, ignore any errors
        constructorIO.trackAutocompleteClick(for: selectTracker)

        // Track search
        let searchTrackData = CIOSearchTrackData(searchTerm: viewModel.searchTerm, itemName: result.autocompleteResult.value)
        constructorIO.trackSearch(for: searchTrackData)
        
        // Run behavioural tracking 'search' if its an autocomplete suggestion
        if sectionName == "standard" {
            let searchTracker = CIOAutocompleteClickTrackData(searchTerm: viewModel.searchTerm, clickedItemName: result.autocompleteResult.value)
            constructorIO.trackAutocompleteClick(for: searchTracker)
        }

        self.delegate?.autocompleteController?(controller: self, didSelectResult: result)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return self.dataSource?.rowHeight?(in: self) ?? Constants.UI.defaultRowHeight
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sectionName = viewModel.getSectionName(atIndex: section)
     
        if self.dataSource?.shouldShowSectionHeader?(sectionName: sectionName, in: self) ?? true{
            let height = self.dataSource?.sectionHeaderViewHeight?(sectionName: sectionName, in: self) ?? Constants.UI.defaultSectionHeaderHeight
            return height
        }else{
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var sectionName = viewModel.getSectionName(atIndex: section)
        if sectionName.isSearchSuggestionString(){
            sectionName = self.dataSource?.searchSuggestionsSectionName?(in: self) ?? sectionName
        }
        
        if let customViewFunction = self.dataSource?.sectionHeaderView{
            return customViewFunction(sectionName, self)
        }else{
            let headerView = UIView(frame: CGRect.zero)
            headerView.backgroundColor = UIColor.white
            
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(label)
            label.centerInSuperviewVertical()
            label.pinToSuperviewLeft(16)
            label.text = sectionName
            
            return headerView
        }
    }
    
}

extension CIOAutocompleteViewController: UISearchBarDelegate {
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        // Track search
        let searchTrackData = CIOSearchTrackData(searchTerm: viewModel.searchTerm, itemName: viewModel.searchTerm)
        constructorIO.trackSearch(for: searchTrackData)
    }
}

extension CIOAutocompleteViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        
        // invalidate the old timer
        self.timerQueryFire?.invalidate()
        let searchTerm = searchText.trim().lowercased()
        
        // check whether we have a valid search term
        if searchTerm.count == 0 {
            let query = CIOAutocompleteQuery(query: "", numResults: config?.numResults, numResultsForSection: config?.numResultsForSection)
            self.setResultsReceived(from: AutocompleteResult(query: query))
            return
        }
        
        // reschedule the timer
        self.timerQueryFire = Timer.scheduledTimer(timeInterval: Constants.UI.fireQueryDelayInSeconds, target: self, selector: #selector(timerFire), userInfo: searchTerm, repeats: false)

    }
}

extension CIOAutocompleteViewController: ResponseParserDelegate {
    
    public func shouldParseResult(result: CIOAutocompleteResult, inGroup group: CIOGroup?) -> Bool?{
        return self.delegate?.autocompleteController?(controller: self, shouldParseResult: result, inGroup: group)
    }
    
    public func shouldParseResults(inSectionWithName name: String) -> Bool? {
        return self.delegate?.autocompleteController?(controller: self, shouldParseResultsInSection: name) ?? name.isSearchSuggestionString()
    }
    
    public func maximumNumberOfResultsForItem(result: CIOAutocompleteResult, at index: Int) -> Int{
        return self.delegate?.autocompleteController?(controller: self, maximumNumberOfGroupsForItem: result, itemIndex: index) ?? (index == 0 ? 2 : 0)
    }
}
