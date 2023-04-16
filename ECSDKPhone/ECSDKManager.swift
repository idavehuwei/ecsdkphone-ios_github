//
//  ECSDKManager.swift
//  ECSDKPhone
//
//  Created by DerekHu on 2022/7/28.
//

import Foundation

@objc protocol ECSDKMessageProtocol: NSObjectProtocol {
    func callStateChangedHandler(callState: String, number: String, callId: Int, callType: Int, userData: [AnyHashable: Any], startTime: Date, endTime: Date, durationTime: Int)

    @objc optional
    func callErrorHandler(errorCode: Int, errorMessage: String)

    @objc optional
    func callNetworkChangeHandler(networkType: String)
    
    @objc optional
    func accountRegisterEventHandler(accountID: Int, registrationStateCode: Int)
    
    @objc optional
    func callComingEventHandler(accountID: Int,callID: Int,displayName: String)

    @objc optional
    func callConfirmedEventHandler(callID: Int)

    @objc optional
    func callDisconnectedEventHandler(accountID: Int,callID: Int,callStateCode: Int,callStatusCode: Int,connectTimestamp: Int,isLocalHold: Int,isLocalMute: Int)
 
    @objc optional
    func callEarlyEventHandler(callID: Int)
 
    @objc optional
    func callOutEventHandler(callID: Int)

    @objc optional
    func stackStatusEventHandler(started: Int)
    

    @objc optional
    func locationEventHandler(locationList: NSMutableArray)
    
    @objc optional
    func deptEventHandler(deptList: NSMutableArray)
    
    @objc optional
    func contactEventHandler(contactList: NSMutableArray)
   
}

class ECSDKManager: NSObject {
    static let shared = ECSDKManager()

    private var observers = NSHashTable<ECSDKMessageProtocol>(options: NSPointerFunctions.Options.weakMemory)
    private let lock = NSLock()

    private var ecsdk = EcSipLib.getInstance()

    override init() {
        super.init()
        ecsdk.externalAppObserver = self
    }

    // 注册观察者
    public func registerObserver(_ observer: ECSDKMessageProtocol) {
        lock.lock()
        defer {
            lock.unlock()
        }
        if !observers.contains(observer) {
            observers.add(observer)
        }
    }

    // 通过HashTable的weak修饰，可以不调用该remove方法
    public func removeObserver(_ observer: ECSDKMessageProtocol) {
        lock.lock()
        defer {
            lock.unlock()
        }
        if observers.contains(observer) {
            observers.remove(observer)
        }
    }
}

// MARK: SDK接口方法
extension ECSDKManager {
    /// 初始化SDK
    func initSDK(extNo: String, extPwd: String, domain: String) {
        ecsdk.initSDK(extNo, extPwd: extPwd, domain: domain)
    }

    /// 销毁SDK
    func destorySDK() {
        ecsdk.destory()
    }
    
    
    func register(extNo: String, extPwd: String, domain: String,sipHost: String,sipPort: Int) {
        ecsdk.register(extNo, extPwd: extPwd, domain: domain,sipHost: sipHost,sipPort: Int32(sipPort))
    }
    
    func unRegister() {
        ecsdk.unRegister()
    }

    /// 打电话
    ///
    /// - Parameters:
    ///   - phoneNumber: 拨打的电话号码
    func makeCall(phoneNumber: String) {
        ecsdk.makeCall(phoneNumber)
    }
    
    func answer(callID: Int) {
        ecsdk.answerCall(Int32(callID))
    }
    
    func answer() {
        ecsdk.answerCall()
    }
    
    func reject(callID: Int) {
        ecsdk.rejectCall(Int32(callID))
    }

    /// 挂断
    func hangup(callID: Int) {
        ecsdk.hangup(Int32(callID))
    }
    
    func hangupAll() {
        ecsdk.hangupAll()
    }
    
    
    func sendDtmf(callID: Int,digits: String) {
        ecsdk.sendDTMF(Int32(callID),digits: digits)
    }

    /// 免提开关
    ///
    /// - Parameter isOn: true -> 免提  false -> 听筒
    func changeVoiceWithLoudSpeaker(_ isOn: Bool) {
        ecsdk.changeVoice(withLoudSpeaker: isOn)
    }
    
    
    func queryLocation(extNo: String,extPwd: String,domain: String) {
        ecsdk.queryLocation(extNo, extPwd: extPwd, domain: domain)
    }
    
    func queryDeptList(extNo: String,extPwd: String,domain: String) {
        ecsdk.queryDeptList(extNo, extPwd: extPwd, domain: domain)
    }
    
    func queryContactList(extNo: String,extPwd: String,domain: String,deptId: String) {
        ecsdk.queryContactList(extNo, extPwd: extPwd, domain: domain,deptId: deptId)
    }
    
    
}

/**
 ECSDKManager对ESSIPLibDelegate实现的扩展
 */
extension ECSDKManager: ESSIPLibDelegate {

    func onCallStateChangedHandler(_ callState: String, number: String, callId: Int32, callType: Int32, userData: [AnyHashable: Any], startTime: Date, endTime: Date, durationTime: Int) {
        observers.allObjects.forEach({ observer in
            print("ECSDKManager -> onCallStateChangedHandler, observer = %@", observer);
            observer.callStateChangedHandler(callState: callState, number: number, callId: Int(callId), callType: Int(callType), userData: userData, startTime: startTime, endTime: endTime, durationTime: durationTime)
        })
    }

    func onErrorHandler(_ errorCode: Int32, errorMessage: String) {
        observers.allObjects.forEach({ observer in
            if (observer.responds(to: #selector(ECSDKMessageProtocol.callErrorHandler(errorCode:errorMessage:)))) {
                observer.callErrorHandler?(errorCode: Int(errorCode), errorMessage: errorMessage)
            } else {
                let className = String(describing: type(of: self))
                let methodName = String(describing: type(of: #selector(ECSDKMessageProtocol.callErrorHandler(errorCode:errorMessage:))))
                print("%@ not implement %@", className, methodName)
                
            }
        })
    }

    func onNetworkChangeHandler(_ networkType: String) {
        observers.allObjects.forEach({ observer in
            if (observer.responds(to: #selector(ECSDKMessageProtocol.callNetworkChangeHandler(networkType:)))) {
                observer.callNetworkChangeHandler?(networkType: networkType)
            } else {
                let className = String(describing: type(of: self))
                let methodName = String(describing: type(of: #selector(ECSDKMessageProtocol.callNetworkChangeHandler(networkType:))))
                print("%@ not implement %@", className, methodName)
            }
        })
    }
     
    func accountRegisterEventHandler(_ accountID: Int32,registrationStateCode: Int32){
        observers.allObjects.forEach({ observer in
            if (observer.responds(to: #selector(ECSDKMessageProtocol.accountRegisterEventHandler(accountID:registrationStateCode:)))) {
                observer.accountRegisterEventHandler?(accountID: Int(accountID), registrationStateCode: Int(registrationStateCode))
            } else {
                let className = String(describing: type(of: self))
                let methodName = String(describing: type(of: #selector(ECSDKMessageProtocol.accountRegisterEventHandler(accountID:registrationStateCode:))))
                print("%@ not implement %@", className, methodName)
            }
        })
    }
     
    func callComingEventHandler(_ accountID: Int32,callID: Int32,displayName: String){
        observers.allObjects.forEach({ observer in
            if (observer.responds(to: #selector(ECSDKMessageProtocol.callComingEventHandler(accountID:callID:displayName:)))) {
                observer.callComingEventHandler?(accountID: Int(accountID),callID: Int(callID),displayName: displayName)
            } else {
                let className = String(describing: type(of: self))
                let methodName = String(describing: type(of: #selector(ECSDKMessageProtocol.callComingEventHandler(accountID:callID:displayName:))))
                print("%@ not implement %@", className, methodName)
            }
        })
    }
 
    func callConfirmedEventHandler(_ callID: Int32){
        observers.allObjects.forEach({ observer in
            if (observer.responds(to: #selector(ECSDKMessageProtocol.callConfirmedEventHandler(callID:)))) {
                observer.callConfirmedEventHandler?(callID: Int(callID))
            } else {
                let className = String(describing: type(of: self))
                let methodName = String(describing: type(of: #selector(ECSDKMessageProtocol.callConfirmedEventHandler(callID:))))
                print("%@ not implement %@", className, methodName)
            }
        })
    }

    func callDisconnectedEventHandler(_ accountID: Int32,callID: Int32,callStateCode: Int32,callStatusCode: Int32,connectTimestamp: Int32,isLocalHold: Int32,isLocalMute: Int32){
        observers.allObjects.forEach({ observer in
            if (observer.responds(to: #selector(ECSDKMessageProtocol.callDisconnectedEventHandler(accountID:callID:callStateCode:callStatusCode:connectTimestamp:isLocalHold:isLocalMute:)))) {
                observer.callDisconnectedEventHandler?(accountID: Int(accountID),callID: Int(callID),callStateCode: Int(callStateCode),callStatusCode: Int(callStatusCode),connectTimestamp: Int(connectTimestamp),isLocalHold: Int(isLocalHold),isLocalMute: Int(isLocalMute))
            } else {
                let className = String(describing: type(of: self))
                let methodName = String(describing: type(of: #selector(ECSDKMessageProtocol.callDisconnectedEventHandler(accountID:callID:callStateCode:callStatusCode:connectTimestamp:isLocalHold:isLocalMute:))))
                print("%@ not implement %@", className, methodName)
            }
        })
    }
//
    func callEarlyEventHandler(_ callID: Int32){
        observers.allObjects.forEach({ observer in
            if (observer.responds(to: #selector(ECSDKMessageProtocol.callEarlyEventHandler(callID:)))) {
                observer.callEarlyEventHandler?(callID: Int(callID))
            } else {
                let className = String(describing: type(of: self))
                let methodName = String(describing: type(of: #selector(ECSDKMessageProtocol.callEarlyEventHandler(callID:))))
                print("%@ not implement %@", className, methodName)
            }
        })
    }

    func callOutEventHandler(_ callID: Int32){
        observers.allObjects.forEach({ observer in
            if (observer.responds(to: #selector(ECSDKMessageProtocol.callOutEventHandler(callID:)))) {
                observer.callOutEventHandler?(callID: Int(callID))
            } else {
                let className = String(describing: type(of: self))
                let methodName = String(describing: type(of: #selector(ECSDKMessageProtocol.callOutEventHandler(callID:))))
                print("%@ not implement %@", className, methodName)
            }
        })
    }

    func stackStatusEventHandler(_ started: Int32) {
        observers.allObjects.forEach({ observer in
            if (observer.responds(to: #selector(ECSDKMessageProtocol.stackStatusEventHandler(started:)))) {
                observer.stackStatusEventHandler?(started: Int(started))
            } else {
                let className = String(describing: type(of: self))
                let methodName = String(describing: type(of: #selector(ECSDKMessageProtocol.stackStatusEventHandler(started:))))
                print("%@ not implement %@", className, methodName)
            }
        })
    }
    
    
    func locationEventHandler(_ locationList: NSMutableArray){
        observers.allObjects.forEach({ observer in
            if (observer.responds(to: #selector(ECSDKMessageProtocol.locationEventHandler(locationList:)))) {
                observer.locationEventHandler?(locationList: locationList)
            } else {
                let className = String(describing: type(of: self))
                let methodName = String(describing: type(of: #selector(ECSDKMessageProtocol.locationEventHandler(locationList:))))
                print("%@ not implement %@", className, methodName)
            }
        })
    }
    
    func deptEventHandler(_ deptList: NSMutableArray){
        observers.allObjects.forEach({ observer in
            if (observer.responds(to: #selector(ECSDKMessageProtocol.deptEventHandler(deptList:)))) {
                observer.deptEventHandler?(deptList: deptList)
            } else {
                let className = String(describing: type(of: self))
                let methodName = String(describing: type(of: #selector(ECSDKMessageProtocol.deptEventHandler(deptList:))))
                print("%@ not implement %@", className, methodName)
            }
        })
    }
    
    func contactEventHandler(_ contactList: NSMutableArray){
        observers.allObjects.forEach({ observer in
            if (observer.responds(to: #selector(ECSDKMessageProtocol.contactEventHandler(contactList:)))) {
                observer.contactEventHandler?(contactList: contactList)
            } else {
                let className = String(describing: type(of: self))
                let methodName = String(describing: type(of: #selector(ECSDKMessageProtocol.contactEventHandler(contactList:))))
                print("%@ not implement %@", className, methodName)
            }
        })
    }
    
}
