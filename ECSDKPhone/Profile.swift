//
//  ModelObject.swift
//  ECSDKPhone
//
//  Created by DerekHu on 2022/8/5.
//

import SwiftUI
 
class Profile: ObservableObject {

    @Published var toastIsShowing = false

    @Published var extNo: String = ""
    @Published var extPwd: String = ""
    
    @Published var sipHost: String = ""
    @Published var sipPort: Int = 0
    
    
    @Published var domain : String = ""
    @Published var makeCall: String = ""
    @Published var dtmf: String = ""
    
    @Published var deptId : String = ""
    
    @Published var callID: Int = 0
    
    
    // default constructor
    internal init(extNo: String = "", extPwd: String = "", sipHost: String = "", sipPort: Int = 0, domain: String = "", makeCall: String = "", dtmf: String = "", deptId: String = "", callID: Int = 0) {
        self.extNo = extNo
        self.extPwd = extPwd
        self.sipHost = sipHost
        self.sipPort = sipPort
        self.domain = domain
        self.makeCall = makeCall
        self.dtmf = dtmf
        self.deptId = deptId
        self.callID = callID
    }
    
}
