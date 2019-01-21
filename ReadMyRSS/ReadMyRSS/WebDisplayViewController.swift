//
//  WebDisplayViewController.swift
//  ReadMyRSS
//
//  Created by Dav Nelson on 1/19/19.
//  Copyright © 2019 DavNel. All rights reserved.
//D

import UIKit
import WebKit

class WebDisplayViewController: UIViewController, WKNavigationDelegate {
    
    fileprivate var webView: WKWebView!
    fileprivate var contentView: UIView!
    
    var rssSourceUrl: URL!
    var rssTitle: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    private func initView(){
        self.title = rssTitle
        
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.backgroundColor = UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1.0)
        
        self.view.addSubview(webView)
        
        activateLayout(webView)
        
        loadWebsite()
    }
    
    private func loadWebsite(){
        webView.load(URLRequest(url: rssSourceUrl))
        webView.allowsBackForwardNavigationGestures = true
    }
}

extension UIViewController {
    
    func activateLayout(_ subView: UIView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        
        let leftLayout = subView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let rightLayout = subView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        let topLayout = subView.topAnchor.constraint(equalTo: self.view.topAnchor)
        let bottomLayout = subView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        
        NSLayoutConstraint.activate([
            leftLayout,
            rightLayout,
            topLayout,
            bottomLayout
        ])
    }
    
}
