// ECSDKPhoneApp.swift
// ECSDKPhone
//
// Created by DerekHu on 2022/7/27.
//

import UIKit
import SwiftUI

@main
struct ECSDKPhoneApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.profile)
                .onAppear(){
                    loadData()
                }
        }
    }
    
    func loadData() {
        appDelegate.profile.extNo = UserDefaults.standard.string(forKey: "extNo") ?? ""
        appDelegate.profile.extPwd = UserDefaults.standard.string(forKey: "extPwd") ?? ""
        appDelegate.profile.domain = UserDefaults.standard.string(forKey: "domain") ?? ""
        appDelegate.profile.makeCall = UserDefaults.standard.string(forKey: "makeCall") ?? ""
        appDelegate.profile.dtmf = UserDefaults.standard.string(forKey: "dtmf") ?? ""
        
        if(appDelegate.profile.extNo == "1"){
            appDelegate.profile.extNo = "5213"
            appDelegate.profile.extPwd = "QXL35UKT"
            appDelegate.profile.domain = "vorsbc.dictccyun.com"
            appDelegate.profile.makeCall = "95566"
            appDelegate.profile.sipHost = "228.78.0.205"
            appDelegate.profile.sipPort = 62000
            appDelegate.profile.dtmf = "*"
        }
        
        if(appDelegate.profile.extNo == ""){
            appDelegate.profile.extNo = "500017013"
            appDelegate.profile.extPwd = "314159"
            appDelegate.profile.domain = "106.39.87.89"
            appDelegate.profile.makeCall = "500017014"
            appDelegate.profile.sipHost = "106.39.87.89"
            appDelegate.profile.sipPort = 10210
            appDelegate.profile.dtmf = "*"
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var profile = Profile()
    
    var window: UIWindow?
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ECSDKManager.shared.registerObserver(self)
        ECSDKLog.addLog("AppDelegate started")
        return true
    }
    
    
    func applicationWillTerminate(_ notification: Notification) {
        //TODO save profile
        ECSDKLog.addLog("AppDelegate WillTerminate")
    }
    
}



extension AppDelegate: ECSDKMessageProtocol {
    
    func callStateChangedHandler(callState: String, number: String, callId: Int, callType: Int, userData: [AnyHashable : Any], startTime: Date, endTime: Date, durationTime: Int) {
        
        ECSDKLog.addLog("callStateChangedHandler")
    }
    
    func callErrorHandler(errorCode: Int, errorMessage: String) {
        ECSDKLog.addLog("@@异常事件")
        
    }
    
    func callNetworkChangeHandler(networkType: String) {
        ECSDKLog.addLog("@@网络事件")
        
    }
    
    func accountRegisterEventHandler(accountID: Int, registrationStateCode: Int) {
        ECSDKLog.addLog("@@注册事件 accID: " + String(accountID) + " code: " + String(registrationStateCode))
        
    }
    
    func callComingEventHandler(accountID: Int,callID: Int,displayName: String){
        ECSDKLog.addLog("@@呼入事件 accID" + String(accountID) + " callID:" + String(callID))
    }
    
    func callConfirmedEventHandler(callID: Int){
        ECSDKLog.addLog("@@应答事件 callID:" + String(callID))
    }
    
    func callDisconnectedEventHandler(accountID: Int,callID: Int,callStateCode: Int,callStatusCode: Int,connectTimestamp: Int,isLocalHold: Int,isLocalMute: Int){
        ECSDKLog.addLog("@@断开事件 accID" + String(accountID) + " callID:" + String(callID) + " state:" + String(callStateCode) + " status:" + String(callStatusCode))
        
        
        
    }
    
    func callEarlyEventHandler(callID: Int){
        ECSDKLog.addLog("@@彩铃事件 callID:" + String(callID))
        
        
        
    }
    
    func callOutEventHandler(callID: Int){
        ECSDKLog.addLog("@@外呼事件 callID:" + String(callID))
        
        
    }
    
    func stackStatusEventHandler(started: Int){
        ECSDKLog.addLog("@@SDK事件  " + String(started))
        
        
    }
    
    func locationEventHandler(locationList: NSMutableArray){
        
        
        if(locationList.count == 1) {
            ECSDKLog.addLog("@@位置事件 locationList: 访问异常" )
            
        } else{
            
            let host = locationList.value(forKey: "SIPIP") as? String ?? ""
            let port = locationList.value(forKey: "SIPPort") as? String ?? ""
            
            profile.sipHost = host
            profile.sipPort = Int(port)!
            
            ECSDKLog.addLog("@@位置信息事件 location: \(host) port: \(port)" )
            
        }
        
    }
    
    func deptEventHandler(deptList: NSMutableArray){
        ECSDKLog.addLog("@@部门信息事件 deptList: \(deptList.count)" )
        
        for item in deptList {
            print(item)
        }
        
        
    }
    
    func contactEventHandler(contactList: NSMutableArray){
        ECSDKLog.addLog("@@通讯录信息事件 contactList: \(contactList.count)" )
        
        for item in contactList {
            print(item)
        }
        
    }
    
    
}


