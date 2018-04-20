//
//  BluetoothOnboardingManager.swift
//  Ynni
//
//  Created by Bart Blok on 27-02-18.
//  Copyright © 2018 Wittig. All rights reserved.
//

import Foundation
import CoreBluetooth
import ObjectMapper

class BluetoothOnboardingManager: NSObject {
    
    typealias DiscoverSmartBridgeCallback = (_ device: BluetoothDevice?, _ error: Error?) -> ()
    typealias ExecuteApScanCallback = (_ networks: [WlanNetwork]?, _ error: Error?) -> ()
    typealias ExecuteJoinCallback = (_ error: Error?) -> ()
    
    struct Consts {
        
        static let smartBridgePrefix = "sbwf-"
        static let onboardingServiceUUID = "4E01"
        
        static let apScanCompleteDebounce = 2.0
        static let discoverTimeout = 30.0
        static let joinTimeout = 30.0
        
        struct CharacteristicsUUID {
            
            static let ssid = "4E02"
            static let password = "4E03"
            static let command = "4E04"
            static let joinResult = "4E05"
            static let scanResult = "4E06"
            static let macAddress = "4E07"
        }
    }
    
    var bluetoothManager: CBCentralManager!
    var smartBridgePeripheral: CBPeripheral?
    var onboardingService: CBService?
    var characteristics: [String: CBCharacteristic]?
    var smartBridgeMacAddress: String?
    
    var pendingDiscover = false
    var discoveringSmartBridge = false
    var apScanActive = false
    var joinActive = false
    
    var discoverCallback: DiscoverSmartBridgeCallback?
    var discoverTimeoutTimer: Timer?
    
    var apScanCallback: ExecuteApScanCallback?
    var apScanNetworks: [WlanNetwork] = []
    var apScanCompleteTimer: Timer?
    
    var joinCallback: ExecuteJoinCallback?
    var joinTimeoutTimer: Timer?
    var joinSsid: String?
    var joinPassword: String?
    
    override init() {
        
        super.init()
        
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        
        log.info("CB: Initializing Bluetooth Manager")
    }
    
    func discoverSmartBridge(callback: DiscoverSmartBridgeCallback?){
        
        if discoveringSmartBridge {
            
            if let callback = callback {
                callback(nil, NSError(domain: String(describing: self), code: 0, userInfo: ["description": "Discovery already active"]))
            }
            
            return
        }
        
        discoveringSmartBridge = true
        
        discoverTimeoutTimer = Timer.scheduledTimer(timeInterval: Consts.discoverTimeout, target: self, selector: #selector(discoverSmartBridgeTimeout), userInfo: nil, repeats: false)
        discoverCallback = callback
        
        if bluetoothManager.state == .poweredOn {
            
            log.info("CB: Scanning devices...")
            bluetoothManager.scanForPeripherals(withServices: nil, options: nil)
        }
        else {
            
            pendingDiscover = true
        }
    }
    
    func disconnectSmartBridge(){
        
        guard let peripheral = smartBridgePeripheral else {
            
            log.error("Unable to disconnect, no peripheral")
            return
        }
        
        bluetoothManager.cancelPeripheralConnection(peripheral)
    }
    
    func executeApScan(callback: ExecuteApScanCallback?){
        
        if apScanActive {
        
            if let callback = callback {
                callback(nil, NSError(domain: String(describing: self), code: 0, userInfo: ["description": "Scan already active"]))
            }
            
            return
        }
        
        guard let peripheral = smartBridgePeripheral, let characteristics = characteristics, let scanResultCharacteristic = characteristics[BluetoothOnboardingManager.Consts.CharacteristicsUUID.scanResult] else {
            
            if let callback = callback {
                callback(nil, NSError(domain: String(describing: self), code: 0, userInfo: ["description": "No peripheral available"]))
            }
            
            return
        }
        
        apScanActive = true
        apScanCallback = callback
        
        log.info("CB: Executing AP scan")
        peripheral.setNotifyValue(true, for: scanResultCharacteristic)
    }
    
    func executeJoin(ssid: String, password: String?, callback: ExecuteJoinCallback?){
        
        if joinActive {
            
            if let callback = callback {
                callback(NSError(domain: String(describing: self), code: 0, userInfo: ["description": "Join already active"]))
            }
            
            return
        }
        
        guard let peripheral = smartBridgePeripheral, let characteristics = characteristics, let ssidCharacteristic = characteristics[BluetoothOnboardingManager.Consts.CharacteristicsUUID.ssid] else {
            
            if let callback = callback {
                callback(NSError(domain: String(describing: self), code: 0, userInfo: ["description": "No peripheral available"]))
            }
            
            return
        }
        
        joinTimeoutTimer = Timer.scheduledTimer(timeInterval: Consts.joinTimeout, target: self, selector: #selector(joinTimeout), userInfo: nil, repeats: false)
        
        joinActive = true
        joinCallback = callback
        
        joinSsid = ssid
        joinPassword = password
        
        log.info("CB: Executing Join: setting SSID")
        
        let data = ssid.data(using: .utf8)
        peripheral.writeValue(data!, for: ssidCharacteristic, type: .withResponse)
    }
    
    func reconnectSmartBridge(){
        
        guard let peripheral = smartBridgePeripheral else {
            return
        }
        
        log.info("CB: Reconnecting with SmartBridge")
        
        bluetoothManager.connect(peripheral, options: nil)
    }
    
    @objc fileprivate func discoverSmartBridgeTimeout(){
        
        reportSmartBridgeConnectionFailed(error: NSError(domain: String(describing: self), code: 0, userInfo: ["description": "Discover timeout"]))
    }
    
    fileprivate func reportDiscoverResult(device: BluetoothDevice?, error: Error?){
        
        if let callback = discoverCallback {
            
            callback(device, error)
            discoverCallback = nil
        }
        
        if let timer = discoverTimeoutTimer {
            
            timer.invalidate()
            discoverTimeoutTimer = nil
        }
        
        discoveringSmartBridge = false
    }
    
    fileprivate func reportSmartBridgeConnectionFailed(error: Error?){
        
        if bluetoothManager.isScanning {
            bluetoothManager.stopScan()
        }
        
        smartBridgePeripheral = nil
        characteristics = nil
        onboardingService = nil
        
        reportDiscoverResult(device: nil, error: error)
    }
    
    fileprivate func reportSmartBridgeConnected(_ peripheral: CBPeripheral){
        
        log.info("CB: Connected to SmartBridge, discovering services...")
        
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: BluetoothOnboardingManager.Consts.onboardingServiceUUID)])
        
        bluetoothManager.stopScan()
    }
    
    fileprivate func reportScanNotificationsEnabled(){
        
        guard let peripheral = smartBridgePeripheral, let characteristics = characteristics, let commandCharacteristic = characteristics[BluetoothOnboardingManager.Consts.CharacteristicsUUID.command] else {
            return
        }
        
        log.info("CB: Notifications for scan results enabled, sending scan command...")
        
        let data = Data(fromHexEncodedString: "01")
        
        peripheral.writeValue(data!, for: commandCharacteristic, type: .withResponse)
    }
    
    fileprivate func reportJoinNotificationsEnabled(){
        
        guard let peripheral = smartBridgePeripheral, let characteristics = characteristics, let commandCharacteristic = characteristics[BluetoothOnboardingManager.Consts.CharacteristicsUUID.command] else {
            return
        }
        
        log.info("CB: Notifications for join results enabled, sending join command...")
        
        let data = Data(fromHexEncodedString: "02")
        
        peripheral.writeValue(data!, for: commandCharacteristic, type: .withResponse)
    }
    
    fileprivate func reportSmartBridgePeripheral(_ peripheral: CBPeripheral) {
        
        log.info("CB: Found SmartBridge bluetooth device: \(peripheral.name!), connecting...")
        
        smartBridgePeripheral = peripheral
        
        bluetoothManager.connect(peripheral, options: nil)
    }
    
    fileprivate func reportSmartBridgeDisconnect(error: Error?){
        
        log.error("CB: SmartBridge disconnected")
        
        if discoveringSmartBridge {
            reportSmartBridgeConnectionFailed(error: error)
        }
        else if apScanActive, let callback = apScanCallback {
            callback(nil, NSError(domain: String(describing: self), code: 0, userInfo: ["description": "Disconnected"]))
        }
        else if joinActive {
            reportJoinResult(error: NSError(domain: String(describing: self), code: 0, userInfo: ["description": "Disconnected"]))
        }
        
        if bluetoothManager.isScanning {
            bluetoothManager.stopScan()
        }
        
        smartBridgePeripheral = nil
        characteristics = nil
        onboardingService = nil
    }
    
    fileprivate func reportOnboardingService(_ service: CBService) {
        
        guard let peripheral = smartBridgePeripheral else {
            return
        }
        
        log.info("CB: Found onboarding service")
        
        onboardingService = service
        
        peripheral.discoverCharacteristics(nil, for: service)
    }
    
    fileprivate func reportCharacteristics(_ characteristics: [String: CBCharacteristic]){
        
        log.info("CB: Got characteristics " + characteristics.keys.joined(separator: ", ") + ". Reading mac address")
        
        self.characteristics = characteristics
        
        guard let macCharacteristic = characteristics[BluetoothOnboardingManager.Consts.CharacteristicsUUID.macAddress], let peripheral = smartBridgePeripheral else {
            
            reportSmartBridgeConnectionFailed(error: NSError(domain: String(describing: self), code: 0, userInfo: ["description": "No mac characteristic found"]))
            return
        }
        
        peripheral.readValue(for: macCharacteristic)
    }
    
    fileprivate func reportMacAddress(_ data: Data){
        
        let mac = data.hexEncodedString(separator: ":")

        guard let peripheralName = smartBridgePeripheral?.name else {
            
            reportDiscoverResult(device: nil, error: NSError(domain: String(describing: self), code: 0, userInfo: ["description": "No peripheral name received"]))
            return
        }
        
        log.info("CB: Received MAC address: \(mac)")
        
        let device = BluetoothDevice(name: peripheralName, macAddress: mac)
        
        reportDiscoverResult(device: device, error: nil)
    }
    
    fileprivate func reportApScanResult(_ data: Data){
        
        do {
            
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let network = Mapper<WlanNetwork>().map(JSON: json) else {
                
                log.error("CB: Invalid AP scan result")
                return
            }
            
            let existingSsids = apScanNetworks.map { $0.ssid }
            
            if network.ssid == "" || existingSsids.contains(network.ssid) {
                
                log.info("CB: Empty or duplicate network name detected (\(network.ssid)), skipping")
            }
            else {
            
                log.info("CB: Found network \(network.ssid)")
                
                // Force encryption true, info is not available in response
                network.encryption = true
                
                apScanNetworks.append(network)
            }
        }
        catch {
            log.exception("CB: Error parsing AP scan result", error)
        }
        
        // Set done timer
        if let currentTimer = apScanCompleteTimer {
            currentTimer.invalidate()
        }
        
        apScanCompleteTimer = Timer.scheduledTimer(timeInterval: BluetoothOnboardingManager.Consts.apScanCompleteDebounce, target: self, selector: #selector(reportApScanComplete), userInfo: nil, repeats: false)
    }
    
    @objc fileprivate func reportApScanComplete(){
        
        log.info("CB: AP scan complete")
        
        guard let peripheral = smartBridgePeripheral, let characteristics = characteristics, let scanResultCharacteristic = characteristics[BluetoothOnboardingManager.Consts.CharacteristicsUUID.scanResult] else {
            
            if let callback = apScanCallback {
                callback(nil, NSError(domain: String(describing: self), code: 0, userInfo: ["description": "No peripheral available"]))
            }
            
            return
        }
        
        if let callback = apScanCallback {
            callback(apScanNetworks, nil);
        }
        
        apScanActive = false
        apScanCallback = nil
        apScanCompleteTimer = nil
        apScanNetworks.removeAll()
        
        peripheral.setNotifyValue(false, for: scanResultCharacteristic)
    }
    
    @objc fileprivate func joinTimeout(){
        
        reportJoinResult(error: NSError(domain: String(describing: self), code: 0, userInfo: ["description": "Join timeout"]))
    }
    
    fileprivate func reportJoinResult(error: Error?){
        
        if let callback = joinCallback {
            
            callback(error)
            joinCallback = nil
        }
        
        if let timer = joinTimeoutTimer {

            timer.invalidate()
            joinTimeoutTimer = nil
        }
        
        joinActive = false
        joinSsid = nil
        joinPassword = nil
    }
    
    fileprivate func reportJoinSsidUpdated(error: Error?){
        
        guard let peripheral = smartBridgePeripheral, let characteristics = characteristics, let passwordCharacteristic = characteristics[BluetoothOnboardingManager.Consts.CharacteristicsUUID.password] else {
            
            reportJoinResult(error: error)
            return
        }
        
        if let error = error {
            
            log.exception("CB: Error updating SSID characteristic", error)
            reportJoinResult(error: error)
            return
        }
        
        log.info("CB: Join SSID set, setting password")
        
        let data = (joinPassword ?? "").data(using: .utf8)
        peripheral.writeValue(data!, for: passwordCharacteristic, type: .withResponse)
    }
    
    fileprivate func reportJoinPasswordUpdated(error: Error?){
        
        guard let peripheral = smartBridgePeripheral, let characteristics = characteristics, let joinResultCharacteristic = characteristics[BluetoothOnboardingManager.Consts.CharacteristicsUUID.joinResult] else {
            
            reportJoinResult(error: error)
            return
        }
        
        if let error = error {
            
            log.exception("CB: Error updating password characteristic", error)
            reportJoinResult(error: error)
            return
        }
        
        log.info("CB: Join password set, subscribing for join result notification")
        
        peripheral.setNotifyValue(true, for: joinResultCharacteristic)
    }
    
    fileprivate func reportJoinResponse(_ data: Data){
        
        let statusCode: Int = data.withUnsafeBytes { $0.pointee }
        
        log.info("CB: Got join response: \(statusCode)")
        
        if statusCode == 1 {
            return
        }
        
        if statusCode == 0 {
            
            reportJoinResult(error: nil)
        }
        else {
            
            reportJoinResult(error: JoinError.errorResponse)
        }
    }
}

extension BluetoothOnboardingManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn {
            
            log.info("CB: Bluetooth Manager initialized")
            
            if pendingDiscover {
                
                bluetoothManager.scanForPeripherals(withServices: nil, options: nil)
                pendingDiscover = false
            }
        }
        else {
            
            log.info("CB: Bluetooth Manager state: " + String(central.state.rawValue))
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        log.info("CB Device " + (peripheral.name ?? ""))
        
        if let name = peripheral.name, name.hasPrefix(BluetoothOnboardingManager.Consts.smartBridgePrefix) {
            reportSmartBridgePeripheral(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        reportSmartBridgeConnected(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        log.exception("CB: Failed to connect to SmartBridge", error)
        reportSmartBridgeConnectionFailed(error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        log.exception("CB: SmartBridge disconnected", error)
        reportSmartBridgeDisconnect(error: error)
    }
}

extension BluetoothOnboardingManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if let error = error {
            
            log.exception("CB: Error discovering services", error)
            reconnectSmartBridge()
            return
        }
        
        guard let services = peripheral.services else {
            
            log.error("CB: No services discovered")
            return
        }
        
        log.info("CB: Successfully discovered services")
        
        for service in services {
            
            log.info("CB: Service: \(service.uuid.uuidString)")
            
            if service.uuid.uuidString == BluetoothOnboardingManager.Consts.onboardingServiceUUID {
                reportOnboardingService(service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let error = error {
            
            log.exception("CB: Error discovering characteristics", error)
            reconnectSmartBridge()
            return
        }
        
        guard let characteristics = service.characteristics else {
            
            log.error("CB: No characteristics discovered")
            return
        }
        
        var characteristicsMap: [String: CBCharacteristic] = [:]
        
        for characteristic in characteristics {
            characteristicsMap[characteristic.uuid.uuidString] = characteristic;
        }
        
        reportCharacteristics(characteristicsMap)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        if let error = error {
            
            log.exception("CB: Error updating notification state for " + characteristic.uuid.uuidString, error)
            return
        }
        
        let uuid = characteristic.uuid.uuidString
        
        if uuid == BluetoothOnboardingManager.Consts.CharacteristicsUUID.scanResult, characteristic.isNotifying {
            reportScanNotificationsEnabled()
        }
        else if uuid == BluetoothOnboardingManager.Consts.CharacteristicsUUID.joinResult, characteristic.isNotifying {
            reportJoinNotificationsEnabled()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let error = error {
            
            log.exception("CB: Error reading characteristic \(characteristic.uuid.uuidString) value", error)
            return
        }
        
        guard let value = characteristic.value else {
            
            log.info("CB: Unable to read characteristic \(characteristic.uuid.uuidString) value")
            return
        }
        
        if characteristic.uuid.uuidString == BluetoothOnboardingManager.Consts.CharacteristicsUUID.scanResult {
            reportApScanResult(value)
        }
        else if characteristic.uuid.uuidString == BluetoothOnboardingManager.Consts.CharacteristicsUUID.joinResult {
            reportJoinResponse(value)
        }
        else if characteristic.uuid.uuidString == BluetoothOnboardingManager.Consts.CharacteristicsUUID.macAddress {
            reportMacAddress(value)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid.uuidString == BluetoothOnboardingManager.Consts.CharacteristicsUUID.ssid {
            reportJoinSsidUpdated(error: error)
        }
        else if characteristic.uuid.uuidString == BluetoothOnboardingManager.Consts.CharacteristicsUUID.password {
            reportJoinPasswordUpdated(error: error)
        }
    }
    
    enum JoinError: Error {
        case unknownError
        case connectionError
        case errorResponse
    }
}

class BluetoothDevice {
    
    let name: String
    let macAddress: String
    
    init(name: String, macAddress: String) {
        
        self.name = name
        self.macAddress = macAddress
    }
}
