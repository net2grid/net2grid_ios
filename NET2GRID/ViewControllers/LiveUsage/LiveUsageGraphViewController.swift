//
//  LiveUsageGraphViewController.swift
//  Ynni
//
//  Created by Bart Blok on 16-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit
import Charts

class LiveUsageGraphViewController: UIViewController {

    var titleLabel: UILabel!
    var chartView: ChartViewBase!
    
    var chartContainerView: UIView!
    
    var noDataView: UIView!
    var noDataContentView: UIView!
    var noDataTitleLabel: UILabel!
    var noDataImageView: UIImageView!
    
    var constraintsSetup: Bool = false;
    var started: Bool = false;
    var hadSuccessfullRequest = false
    
    var canStart: Bool = false {
        
        didSet {
            
            if canStart {
                self.startIfPossible()
            }
            else {
                self.stop()
            }
        }
    }
    
    var updateTimer: Timer?
    
    var quantityTitle: String { return "" }
    var scaleTitle: String { return "" }
    var refreshInterval: TimeInterval { return 60.0 }
    var maxLabelCount: Int { return 6 }
    var labelMinDelta: Double { return 0.0 }
    
    var currentRefreshInterval: TimeInterval = 10.0
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 26.0/255.0, green: 45.0/255.0, blue: 59.0/255.0, alpha: 1.0)

        // Title
        titleLabel = UILabel(frame: .zero)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont(name: Fonts.helvetica, size: 21.0)
        
        let titleAttributedText = NSMutableAttributedString()
        titleAttributedText.append(NSAttributedString(string: quantityTitle, attributes: [NSFontAttributeName: UIFont(name: Fonts.helveticaBold, size: 21.0)!]))
        titleAttributedText.append(NSAttributedString(string: " - "))
        titleAttributedText.append(NSAttributedString(string: scaleTitle))
        
        titleLabel.attributedText = titleAttributedText
        
        view.addSubview(titleLabel)
        
        // Chart Container
        chartContainerView = UIView(frame: .zero)
        chartContainerView.translatesAutoresizingMaskIntoConstraints = false
        chartContainerView.backgroundColor = UIColor.clear
        
        view.addSubview(chartContainerView)
        
        // Chart
        chartView = createChart()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        
        setupChart()
        chartContainerView.addSubview(chartView)
        
        // No data
        noDataView = UIView(frame: .zero)
        noDataView.translatesAutoresizingMaskIntoConstraints = false
        noDataView.backgroundColor = UIColor.clear
        noDataView.isHidden = true
        
        noDataContentView = UIView(frame: .zero)
        noDataContentView.translatesAutoresizingMaskIntoConstraints = false
        noDataContentView.backgroundColor = UIColor.clear
        
        noDataImageView = UIImageView(image: UIImage(named: "icon_clock_white"))
        noDataImageView.translatesAutoresizingMaskIntoConstraints = false
        noDataContentView.addSubview(noDataImageView)
        
        noDataTitleLabel = UILabel(frame: .zero)
        noDataTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        noDataTitleLabel.font = UIFont(name: Fonts.helveticaLightOblique, size: 15.0)
        noDataTitleLabel.textColor = UIColor.white
        noDataTitleLabel.textAlignment = .center
        noDataTitleLabel.numberOfLines = 0
        noDataTitleLabel.text = "live-graph-no-data".localized
        noDataContentView.addSubview(noDataTitleLabel)
        
        noDataView.addSubview(noDataContentView)
        chartContainerView.addSubview(noDataView)
        
        view.setNeedsUpdateConstraints()
        
        startIfPossible()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func updateViewConstraints() {
        
        super.updateViewConstraints()
        
        if !constraintsSetup {
            
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[chart]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["chart": chartView]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[chart]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["chart": chartView]))
            
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[noData]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["noData": noDataView]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[noData]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["noData": noDataView]))
            
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[noDataContent]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["noDataContent": noDataContentView]))
            view.addConstraint(NSLayoutConstraint(item: noDataContentView, attribute: .centerY, relatedBy: .equal, toItem: noDataView, attribute: .centerY, multiplier: 1.0, constant: 0.0))
            
            view.addConstraint(NSLayoutConstraint(item: noDataImageView, attribute: .centerX, relatedBy: .equal, toItem: noDataContentView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[noDataTitleLabel]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["noDataTitleLabel": noDataTitleLabel]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[noDataImageView]-8-[noDataTitleLabel]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["noDataImageView": noDataImageView, "noDataTitleLabel": noDataTitleLabel]))
            
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[titleLabel]-20-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["titleLabel": titleLabel]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-2-[chartContainer]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["chartContainer": chartContainerView]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-15-[titleLabel]-0-[chartContainer]-8-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["titleLabel": titleLabel, "chartContainer": chartContainerView]))
            
            constraintsSetup = true
        }
    }
    
    deinit {
        
        stop()
    }
    
    fileprivate func startIfPossible(){
        
        guard viewIfLoaded != nil, canStart, !started else {
            return
        }
        
        started = true
        
        updateTimer = Timer.scheduledTimer(timeInterval: currentRefreshInterval, target: self, selector: #selector(fetchData), userInfo: nil, repeats: true)
        fetchData()
    }
    
    fileprivate func stop(){
        
        started = false
        
        if let timer = updateTimer {
            timer.invalidate()
        }
    }
}

extension LiveUsageGraphViewController {
    
    func setupChart(){
        
        chartView.isUserInteractionEnabled = false
        chartView.legend.enabled = false
        chartView.chartDescription?.enabled = false
        
        chartView.noDataTextColor = UIColor.white
        chartView.noDataText = "general-graph-loading".localized
        
        chartView.xAxis.labelCount = maxLabelCount
    }
}

extension LiveUsageGraphViewController {
    
    func createChart() -> ChartViewBase {
        
        return ChartViewBase()
    }
    
    func updateData(){
        
        if !hadSuccessfullRequest {
            
            log.debug("First successfull request, switching to normal refresh interval")
            
            hadSuccessfullRequest = true
            currentRefreshInterval = refreshInterval
            
            if let timer = updateTimer {
                timer.invalidate()
            }
            
            updateTimer = Timer.scheduledTimer(timeInterval: currentRefreshInterval, target: self, selector: #selector(fetchData), userInfo: nil, repeats: true)
        }
    }
    
    func fetchData(){
        
        
    }
}
