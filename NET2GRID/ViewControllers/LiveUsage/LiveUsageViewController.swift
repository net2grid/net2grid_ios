//
//  LiveUsageViewController.swift
//  Ynni
//
//  Created by Bart Blok on 01-02-17.
//  Copyright © 2017 Wittig. All rights reserved.
//

import UIKit
import Charts

class LiveUsageViewController: UIViewController {

    static let storyboardIdentifier = "LiveUsageViewController"
    
    struct Consts {
        
        static let liveUpdateInterval = 10.0 as TimeInterval
        static let checkSSIDInterval = 10.0 as TimeInterval
        
        static let rootTwoPi = sqrt(2.0 * M_PI);
        
        static let liveBarCount = 14
        static let liveSigma = 1.3;
        static let liveMultiplier = 9.0
        static let liveBase = 5.0
    }
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    
    @IBOutlet weak var currentTitleLabel: UILabel!
    @IBOutlet weak var currentValueLabel: UILabel!
    @IBOutlet weak var currentGraphContainerView: UIView!
    
    @IBOutlet weak var currentUpdatedLabel: UILabel!
    @IBOutlet weak var currentStartLabel: UILabel!
    @IBOutlet weak var currentEndLabel: UILabel!
    
    @IBOutlet weak var graphContainerView: UIView!
    
    var pageViewController: UIPageViewController!
    var graphViewControllers: [LiveUsageGraphViewController]!
    
    var liveChart: BarChartView!
    var lastLiveUpdate: Date?
    
    var updateLastLiveUpdateTimer: Timer?
    var updateLiveTimer: Timer?
    var checkSSIDTimer: Timer?
    
    var networkAvailable: Bool?
    var started: Bool = false
    var didInitAnimation: Bool = false
    
    var constrainsSetup: Bool = false
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        containerView.backgroundColor = UIColor(red: 33.0/255.0, green: 59.0/255.0, blue: 76.0/255.0, alpha: 1.0)
        graphContainerView.backgroundColor = UIColor(red: 26.0/255.0, green: 45.0/255.0, blue: 59.0/255.0, alpha: 1.0)
        
        currentTitleLabel.font = UIFont(name: Fonts.helvetica, size: 21.0)
        
        let titleAttributedText = NSMutableAttributedString()
        titleAttributedText.append(NSAttributedString(string: "live-current-title-1".localized + " "))
        titleAttributedText.append(NSAttributedString(string: "live-current-title-2".localized, attributes: [NSFontAttributeName: UIFont(name: Fonts.helveticaBold, size: 21.0)!]))
        titleAttributedText.append(NSAttributedString(string: " " + "live-current-title-3".localized))
        
        currentTitleLabel.attributedText = titleAttributedText
        
        currentValueLabel.font = UIFont(name: Fonts.helveticaBold, size: 55.0)
        currentStartLabel.font = UIFont(name: Fonts.helveticaLight, size: 18.0);
        currentEndLabel.font = UIFont(name: Fonts.helveticaLight, size: 18.0);
        currentUpdatedLabel.font = UIFont(name: Fonts.helveticaLightOblique, size: 14.0);

        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        addChildViewController(pageViewController)
        graphContainerView.addSubview(pageViewController.view)
        pageViewController.didMove(toParentViewController: self)
        
        self.view.setNeedsUpdateConstraints()
        
        loadGraphViewControllers()
        setupLiveChart()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func updateViewConstraints() {
        
        super.updateViewConstraints()
        
        if !constrainsSetup {
            
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[chartView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["chartView": liveChart]))
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[chartView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["chartView": liveChart]))
            
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[pageView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["pageView": pageViewController.view]))
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[pageView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["pageView": pageViewController.view]))
            
            constrainsSetup = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        checkNetworkSSID()
        checkSSIDTimer = Timer.scheduledTimer(timeInterval: Consts.checkSSIDInterval, target: self, selector: #selector(checkNetworkSSID), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        if let timer = checkSSIDTimer {
            timer.invalidate()
        }
        
        stop()
    }
    
    func start(){
        
        if started {
            return
        }
        
        log.info("Starting")
        started = true
        
        fetchLiveData()
        updateLiveTimer = Timer.scheduledTimer(timeInterval: Consts.liveUpdateInterval, target: self, selector: #selector(fetchLiveData), userInfo: nil, repeats: true)
        
        updateLastLiveUpdateText()
        updateLastLiveUpdateTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateLastLiveUpdateText), userInfo: nil, repeats: true)
        
        for graphVc in graphViewControllers {
            graphVc.canStart = true
        }
    }
    
    func stop(){
        
        log.info("Stopping")
        started = false
        
        if let timer = updateLastLiveUpdateTimer {
            timer.invalidate()
        }
        
        if let timer = updateLiveTimer {
            timer.invalidate()
        }
        
        for graphVc in graphViewControllers {
            graphVc.canStart = false
        }
    }
    
    @IBAction func settingsTap() {
        
        
    }
}

extension LiveUsageViewController {
    
    func checkNetworkSSID(){
        
        let currentNetworkAvailable = networkAvailable
        networkAvailable = WiFiHelper.isOnSmartBridgeNetwork()
        
        log.info("Network SSID valid: \(networkAvailable)")
        
        if currentNetworkAvailable == nil || networkAvailable! != currentNetworkAvailable! {
            
            if !networkAvailable! {
                
                stop()
                showSwitchNetworkViewController()
            }
            else if !started {
                start()
            }
        }
    }
    
    func showSwitchNetworkViewController(){
        
        let switchViewController = storyboard?.instantiateViewController(withIdentifier: SwitchNetworkViewController.storyboardIdentifier)
        present(switchViewController!, animated: true, completion: nil)
    }
    
    func fetchLiveData(){
        
        LANApiManager.sharedManger.now { (results, error) in
            
            guard error == nil else {
                
                log.error("Error requesting live data: " + (error?.description ?? ""))
                return
            }
            
            if let elec = results?["elec"] as? NSDictionary, let power = elec["power"] as? NSDictionary {
                
                let now = (power["now"] as? NSDictionary)?["value"] as? Int
                let min = (power["min"] as? NSDictionary)?["value"] as? Int
                var max = (power["max"] as? NSDictionary)?["value"] as? Int
                let unit = (power["now"] as? NSDictionary)?["unit"] as? String ?? ""
                
                if now != nil, min != nil, max != nil {
                    
                    if(max! < now! || max! < min!){
                        max = now
                    }
                    
                    if(max! != min!){
                        self.updateLiveData(now: now!, min: min!, max: max!, unit: unit)
                    }
                }
            }
        }
    }
    
    func updateLiveData(now: Int, min: Int, max: Int, unit: String){
        
        currentValueLabel.text = String(now) + unit
        
        currentStartLabel.text = String(min)
        currentEndLabel.text = String(max)
        
        lastLiveUpdate = Date()
        
        let perc: Double = Swift.max(Double(now - min) / Double(max - min), 0)
        let activeBars = Int(round(Double(Consts.liveBarCount) * perc))
        
        // Active
        var activeData = [BarChartDataEntry]()
        
        for i in (0..<activeBars) {
            
            let step = Double(i - activeBars + 1)
            
            activeData.append(BarChartDataEntry(x: Double(i), y: translateLiveValue(step: step)))
        }
        
        let activeSet = BarChartDataSet(values: activeData, label: "active")
        activeSet.drawValuesEnabled = false
        activeSet.setColor(UIColor(red: 55.0/255.0, green: 209.0/255.0, blue: 187.0/255.0, alpha: 1.0))
        
        // Inactive
        var inactiveData = [BarChartDataEntry]()
        
        for i in (activeBars..<Consts.liveBarCount) {
            
            let step = Double(i - activeBars + 1)
            
            inactiveData.append(BarChartDataEntry(x: Double(i), y: translateLiveValue(step: step)))
        }
        
        let inactiveSet = BarChartDataSet(values: inactiveData, label: "inactive")
        inactiveSet.drawValuesEnabled = false
        inactiveSet.setColor(UIColor(red: 26.0/255.0, green: 45.0/255.0, blue: 59.0/255.0, alpha: 1.0))
    
        let chartData = BarChartData(dataSets: [activeSet, inactiveSet])
        chartData.barWidth = 0.5
        
        liveChart.data = chartData
        
        if !didInitAnimation {
            
            liveChart.animate(yAxisDuration: 0.6)
            didInitAnimation = true
        }
    }
    
    func translateLiveValue(step: Double) -> Double {
        
        return ((1.0 / (Consts.liveSigma * Consts.rootTwoPi)) * exp(-0.5 * pow(step / Consts.liveSigma, 2.0)) * Consts.liveMultiplier) + Consts.liveBase
    }
    
    func updateLastLiveUpdateText(){
        
        if let date = lastLiveUpdate {
            
            let seconds = Int(max(round(Consts.liveUpdateInterval - Date().timeIntervalSince(date)), 0))
            let secondsText = seconds == 1 ? "general-second".localized : "general-seconds".localized
            
            currentUpdatedLabel.text = "live-update-next".localized.replacingOccurrences(of: "[value]", with: String(seconds)).replacingOccurrences(of: "[seconds]", with: secondsText)
        }
    }
    
    func loadGraphViewControllers(){
        
        let powerHour = LiveUsageGraphPowerHourViewController()
        let powerDay = LiveUsageGraphPowerDayViewController()
        
        let energyDay = LiveUsageGraphEnergyDayViewController()
        let energyMonth = LiveUsageGraphEnergyMonthViewController()
        let energyYear = LiveUsageGraphEnergyYearViewController()
        
        let gasDay = LiveUsageGraphGasDayViewController()
        let gasMonth = LiveUsageGraphGasMonthViewController()
        let gasYear = LiveUsageGraphGasYearViewController()

        graphViewControllers = [powerHour, powerDay, energyDay, energyMonth, energyYear, gasDay, gasMonth, gasYear]
        pageViewController.setViewControllers([graphViewControllers.first!], direction: .forward, animated: false, completion: nil)
    }
    
    func setupLiveChart(){
        
        liveChart = BarChartView()
        liveChart.translatesAutoresizingMaskIntoConstraints = false
        liveChart.isUserInteractionEnabled = false
        
        // xAxis
        liveChart.xAxis.drawLabelsEnabled = false
        liveChart.xAxis.drawGridLinesEnabled = false
        liveChart.xAxis.drawAxisLineEnabled = false
        
        // Left Axis
        liveChart.leftAxis.drawGridLinesEnabled = false
        liveChart.leftAxis.drawLabelsEnabled = false
        liveChart.leftAxis.drawAxisLineEnabled = false
        liveChart.leftAxis.axisMinimum = 0
        liveChart.leftAxis.axisMaximum = 8
        
    
        // Right Axis
        
        liveChart.rightAxis.drawGridLinesEnabled = false
        liveChart.rightAxis.drawAxisLineEnabled = false
        liveChart.rightAxis.drawLabelsEnabled = false
        
        liveChart.legend.enabled = false
        
        liveChart.chartDescription?.enabled = false
        liveChart.noDataTextColor = UIColor.white
        liveChart.noDataText = "general-graph-loading".localized
        
        currentGraphContainerView.addSubview(liveChart)
    }
}

extension LiveUsageViewController: UIPageViewControllerDelegate {
    
    
}

extension LiveUsageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        let index = graphViewControllers.index(of: (viewController as! LiveUsageGraphViewController))
        
        if let index = index {
            
            var newIndex = index - 1
            if newIndex < 0 {
                newIndex = graphViewControllers.count - 1
            }
            
            return graphViewControllers[newIndex]
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        let index = graphViewControllers.index(of: (viewController as! LiveUsageGraphViewController))
        
        if let index = index {
            
            var newIndex = index + 1
            if newIndex >= graphViewControllers.count {
                newIndex = 0
            }
            
            return graphViewControllers[newIndex]
        }
        
        return nil
    }
}
