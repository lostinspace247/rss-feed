//
//  ViewController.swift
//  ReadMyRSS
//
//  Created by Dav Nelson on 1/19/19.
//  Copyright © 2019 DavNel. All rights reserved.
//

import UIKit

class ViewController: UIViewController, XMLParserDelegate {
    
    fileprivate var parser: XMLParser!
    fileprivate var currElement: String = ""
    fileprivate var knownTypes: String = ""
    fileprivate var rssFeed: [String:String] = [String: String]()
    fileprivate var rssItems: [[String:String]] = [[String:String]]()
    fileprivate var isHeader: Bool = true
    fileprivate var rssFeedPager: Int = 0
    
    fileprivate var rssFeedCV: UICollectionView!
    fileprivate let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    
    fileprivate var reloadBttn: UIButton!
    fileprivate var loadingContentIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        createView()
        retrieveRSSFeed()
    }
    
    private func createView(){
        createReloadButton()
        createCollectionView()
        createActivityIndicator()
    }
    
    private func createActivityIndicator(){
        loadingContentIndicator = UIActivityIndicatorView(frame: CGRect(x: self.view.center.x, y: self.view.center.y, width: 25, height: 25))
        loadingContentIndicator.style = .gray
        loadingContentIndicator.hidesWhenStopped = true
        
        self.view.addSubview(loadingContentIndicator)
        
        loadingContentIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        loadingContentIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
    }
    
    private func createReloadButton(){
        self.title = "Research & Insights"
        
        reloadBttn = UIButton()
        reloadBttn.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
        reloadBttn.setBackgroundImage(UIImage(named: "reload"), for: .normal)
        reloadBttn.titleLabel?.text = ""
        reloadBttn.adjustsImageWhenHighlighted = false
        reloadBttn.addTarget(self, action: #selector(updateRSSFeed), for: .touchUpInside)
        reloadBttn.translatesAutoresizingMaskIntoConstraints = false
        
        self.navigationItem.setRightBarButton(UIBarButtonItem(customView: reloadBttn), animated: false)
    }
    
    private func createCollectionView(){
        let fl = UICollectionViewFlowLayout()
        fl.sectionInset = sectionInsets
        fl.minimumInteritemSpacing = 5
        fl.minimumLineSpacing = 10
        
        rssFeedCV = UICollectionView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height), collectionViewLayout: fl)
        rssFeedCV.dataSource = self
        rssFeedCV.delegate = self
        rssFeedCV.backgroundColor = .white
        rssFeedCV.register(RSSFeedViewerCollectionViewCell.self, forCellWithReuseIdentifier: "rssEntryCell")
        
        self.view.addSubview(rssFeedCV)
        
        rssFeedCV.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rssFeedCV.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            rssFeedCV.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            rssFeedCV.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            rssFeedCV.topAnchor.constraint(equalTo: self.view.topAnchor)
        ])
    }
    
    private func retrieveRSSFeed(){
        let linkToRSS = "https://www.personalcapital.com/blog/feed/?cat=3,891,890,68,284"
        let url = URL(string: linkToRSS)!
        
        startParsing(rssUrl: url) { didComplete in
            self.loadingContentIndicator.stopAnimating()
            self.rssFeedPager = 15
            
            if didComplete {
                // Loads the last entry since
                self.rssItems.append(self.rssFeed)
            }
            
            self.rssFeedCV.reloadData()
            
            print("did complete: \(didComplete)")
            print("rssItems Count: \(self.rssItems.count)")
        }
    }
    
    private func refreshRSSFeed(){
        self.rssItems = [[String:String]]()
        self.currElement = ""
        self.knownTypes = ""
        self.rssFeed = [String: String]()
        self.rssItems = [[String:String]]()
        self.isHeader = true
        self.retrieveRSSFeed()
    }
    
    @objc private func updateRSSFeed(){
        UIView.animate(withDuration: 0.4, animations: {
            self.reloadBttn.transform = self.reloadBttn.transform.rotated(by: CGFloat.pi)
        }, completion: { isFinished in
            if isFinished {
                self.refreshRSSFeed()
            }
        })
    }
    
    private func loadMoreRSSFeed(){
        if rssFeedPager + 15 > rssItems.count {
            self.rssFeedPager += (rssItems.count - rssFeedPager)
        } else {
            self.rssFeedPager += 15
        }
        
        self.rssFeedCV.reloadData()
    }
    
    fileprivate func startParsing(rssUrl: URL, with completed: @escaping (Bool) -> ()){
        
        parser = XMLParser(contentsOf: rssUrl)
        parser.delegate = self
        
        let didParse = parser.parse()
        
        self.loadingContentIndicator.startAnimating()
        
        completed(didParse)
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        currElement = elementName
        
        if currElement == "item" {
            if !isHeader {
                rssItems.append(rssFeed)
            }
            
            isHeader = false
        }
        
        if !isHeader {
            if currElement == "media:group" || currElement == "media:content" {
                knownTypes += attributeDict["url"]!
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if !isHeader {
            if currElement == "title" || currElement == "link"
                || currElement == "description" || currElement == "content" || currElement == "pubDate"
                || currElement == "dc:creator" || currElement == "content:encoded" {
                
                knownTypes += string
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if !knownTypes.isEmpty {
            knownTypes = knownTypes.trimmingCharacters(in: .whitespacesAndNewlines)
            rssFeed[currElement] = knownTypes
            knownTypes = ""
        }
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return rssFeedPager
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        var rssImageLink: String? = nil
        let lastItem = rssFeedPager - 1
        let item = indexPath.item
        let sec = indexPath.section
        
        guard let cell = cell as? RSSFeedViewerCollectionViewCell else { return }
        
        if sec == 0 {
            rssImageLink = (self.rssItems[0].filter { $0.key == "media:content" })["media:content"] // O(n) -> time complexity
            let description = (self.rssItems[0].filter { $0.key == "description" })["description"]
            
            cell.feedTitleLabel.text = cell.decodeString((self.rssItems[0].filter { $0.key == "title" })["title"], type: "title") // O(n) -> time complexity
            cell.feedSummaryLabel.text = description != nil ? description! : "No summary found"
            cell.feedImageView.image = UIImage(named: "no-image")
            
            cell.loadImage(url: rssImageLink, with: { _image in
                // Stops animating the indicator and displays image
                DispatchQueue.main.async {
                    cell.loadingIndicator.stopAnimating()
                    
                    cell.feedImageView.image = _image
                }
            }, error: {
                DispatchQueue.main.async {
                    cell.feedImageView.image = UIImage(named: "no-image")
                }
            })
        } else {
            if item == lastItem {
                self.loadMoreRSSFeed()
            } else {
                let rssItem: [String:String]
                if item + 1 != rssItems.count {
                    rssItem = rssItems[item + 1]
                } else {
                    rssItem = rssItems[item]
                }
                
                rssImageLink = (rssItem.filter { $0.key == "media:content" })["media:content"] // O(n) -> time complexity
                
                cell.feedTitleLabel.text = cell.decodeString((rssItem.filter { $0.key == "title" })["title"], type: "title") // O(n) -> time complexity
                cell.feedImageView.image = UIImage(named: "no-image")
                
                cell.loadImage(url: rssImageLink, with: { _image in
                    // Stops animating the indicator and displays image
                    DispatchQueue.main.async {
                        cell.loadingIndicator.stopAnimating()
                        
                        cell.feedImageView.image = _image
                    }
                }, error: {
                    DispatchQueue.main.async {
                        cell.feedImageView.image = UIImage(named: "no-image")
                    }
                })
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "rssEntryCell", for: indexPath)
        
        self.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sec = indexPath.section
        let item = indexPath.item
        var rssItem: [String:String] = [String:String]()
        var webDisplayVC: WebDisplayViewController = WebDisplayViewController()
        
        if sec == 0 {
            rssItem = self.rssItems[0]
        } else {
            if item + 1 != rssItems.count {
                rssItem = rssItems[item + 1]
            } else {
                rssItem = rssItems[item]
            }
        }
        
        guard let rssLinkVal = (rssItem.filter { $0.key == "link" })["link"] else { // O(n) -> time complexity
            return
        }
        
        // As requested, we set the displayMobileNavigation flag to 0
        guard let rssLink = URL(string: "\(rssLinkVal)?displayMobileNavigation=0") else {
            return
        }
        
        let rssTitle: String
        if let title = (rssItem.filter { $0.key == "title" })["title"] { // O(n) -> time complexity
            rssTitle = title
        } else {
            rssTitle = "No title found"
        }
        
        webDisplayVC.rssSourceUrl = rssLink
        webDisplayVC.rssTitle = rssTitle
        
        self.navigationController?.pushViewController(webDisplayVC, animated: true)
    }
    
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let section = indexPath.section
        
        if section == 0 {
            return CGSize(width: UIScreen.main.bounds.width, height: 335)
        } else {
            let paddingSpace = sectionInsets.left * (3)
            let availableWidth = rssFeedCV.frame.size.width - paddingSpace
            let widthPerItem: CGFloat
            
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                widthPerItem = availableWidth / 3
            } else {
                widthPerItem = availableWidth / 2
            }
            
            view.layoutSubviews()
            
            return CGSize(width: widthPerItem, height: 250)
            
            
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

class RSSFeedViewerCollectionViewCell: UICollectionViewCell {
    
    var feedImageView: UIImageView!
    var feedTitleLabel: UILabel!
    var feedSummaryLabel: UILabel!
    
    private var _backgroundHandler: DispatchGroup = DispatchGroup()
    
    fileprivate var loadingIndicator: UIActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initCell()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        feedImageView.image = UIImage(named: "no-image")
        feedTitleLabel.text = ""
        feedSummaryLabel.text = ""
        loadingIndicator.stopAnimating()
    }
    
    func decodeString(_ encodedString: String?, type: String) -> String {
        if let title = encodedString {
            if let titleData = title.data(using: .utf8),
                let rssTitleAttr = try? NSAttributedString(data: titleData,
                                                           options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
                                                           documentAttributes: nil) {
                
                return rssTitleAttr.string
            } else {
                return "No \(type) found"
            }
        } else {
            return "No \(type) found"
        }
    }
    
    func loadImage(url: String?, with completed: @escaping (UIImage) -> (), error: @escaping () -> ()){
        self.loadingIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInteractive).async {
            let session = URLSession(configuration: .default)
            
            guard let link = url else {
                error()
                return
            }
            
            if let rssFeedImageLink = URL(string: link) {
                let rssDownloadPicTask = session.dataTask(with: rssFeedImageLink) { (data, res, err) in
                    if err != nil {
                        // Sends error
                        error()
                        
                        print("Error while downloading image: \(err)")
                    } else {
                        if let urlRes = res as? HTTPURLResponse {
                            // Dispatch group enters while the image is loaded
                            self._backgroundHandler.enter()
                            print("Downloading image...")
                            print("Picture response: \(urlRes.statusCode)")
                            if let _image = data {
                                // Leaves dispatch group and stops animating the indicator
                                self._backgroundHandler.leave()
                                
                                // Completed is called with image
                                completed(UIImage(data: _image)!)
                                
                                print("Image download compelete")
                            } else {
                                // Image is nil so we leave the DispatchGroup and stops animating the indicator
                                self._backgroundHandler.leave()
                                
                                // Sends error
                                error()
                            }
                        } else {
                            // No response found. Loading default image
                            error()
                        }
                    }
                }
                
                // Starts the download task
                rssDownloadPicTask.resume()
                
            } else {
                
                error()
            }
        }
    }
    
    fileprivate func initCell(){
        feedImageView = UIImageView()
        feedImageView.contentMode = .scaleToFill
        feedImageView.clipsToBounds = true
        feedImageView.isUserInteractionEnabled = false
        
        let helvNeBold = UIFont(name: "Helvetica-Bold", size: 14.0)!
        let helvRg = UIFont(name: "Helvetica", size: 12.0)!
        
        feedTitleLabel = UILabel()
        feedTitleLabel.text = ""
        feedTitleLabel.textColor = .black
        feedTitleLabel.font = helvNeBold
        feedTitleLabel.numberOfLines = 2
        feedTitleLabel.clipsToBounds = true
        feedTitleLabel.textAlignment = .left

        feedSummaryLabel = UILabel()
        feedSummaryLabel.text = ""
        feedSummaryLabel.textColor = .black
        feedSummaryLabel.font = helvRg
        feedSummaryLabel.numberOfLines = 2
        feedSummaryLabel.clipsToBounds = true
        feedSummaryLabel.textAlignment = .left
        
        loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: contentView.center.x, y: contentView.center.y, width: 25, height: 25))
        loadingIndicator.style = .gray
        loadingIndicator.hidesWhenStopped = true
        
        contentView.addSubview(feedImageView)
        contentView.addSubview(feedTitleLabel)
        contentView.addSubview(feedSummaryLabel)
        contentView.addSubview(loadingIndicator)
        
        activateLayout()
    }
    
    fileprivate func activateLayout(){
        feedImageView.translatesAutoresizingMaskIntoConstraints = false
        feedTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        feedSummaryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let feedImageViewLeftLayout = NSLayoutConstraint(item: feedImageView, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leadingMargin, multiplier: 1.0, constant: 1.0)
        let feedImageViewRightLayout = NSLayoutConstraint(item: feedImageView, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailingMargin, multiplier: 1.0, constant: 1.0)
        let feedImageViewTopLayout = NSLayoutConstraint(item: feedImageView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .topMargin, multiplier: 1.0, constant: 1.0)
        
        NSLayoutConstraint.activate([
            feedImageViewLeftLayout,
            feedImageViewRightLayout,
            feedImageViewTopLayout
        ])
        
        let feedTitleLabelHeightLayout = feedTitleLabel.heightAnchor.constraint(equalToConstant: 65)
        let feedTitleLeftLayout = NSLayoutConstraint(item: feedTitleLabel, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leadingMargin, multiplier: 1.0, constant: 19.0)
        let feedTitleRightLayout = NSLayoutConstraint(item: feedTitleLabel, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailingMargin, multiplier: 1.0, constant: -19.0)
        let feedTitleBottomLayout = NSLayoutConstraint(item: feedTitleLabel, attribute: .top, relatedBy: .equal, toItem: feedImageView, attribute: .bottom, multiplier: 1.0, constant: 8.0)
        
        NSLayoutConstraint.activate([
            feedTitleLeftLayout,
            feedTitleRightLayout,
            feedTitleBottomLayout,
            feedTitleLabelHeightLayout
        ])
        
        let feedSummaryLabelHeightLayout = feedSummaryLabel.heightAnchor.constraint(equalToConstant: 65)
        let feedSummaryLabelLeftLayout = NSLayoutConstraint(item: feedSummaryLabel, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leadingMargin, multiplier: 1.0, constant: 19.0)
        let feedSummaryLabelRightLayout = NSLayoutConstraint(item: feedSummaryLabel, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailingMargin, multiplier: 1.0, constant: -19.0)
        let feedSummaryLabelTopLayout = NSLayoutConstraint(item: feedSummaryLabel, attribute: .top, relatedBy: .equal, toItem: feedTitleLabel, attribute: .bottom, multiplier: 1.0, constant: -15.0)
        let feedSummaryLabelBottomLayout = NSLayoutConstraint(item: feedSummaryLabel, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottomMargin, multiplier: 1.0, constant: 1.0)
        
        NSLayoutConstraint.activate([
            feedSummaryLabelLeftLayout,
            feedSummaryLabelRightLayout,
            feedSummaryLabelTopLayout,
            feedSummaryLabelBottomLayout,
            feedSummaryLabelHeightLayout
        ])
        
        loadingIndicator.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor)
        loadingIndicator.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: -10.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
