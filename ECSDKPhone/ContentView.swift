//
//  ContentView.swift
//  ECSDKPhone
//
//  Created by DerekHu on 2022/7/30.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var toast: Toast
    @State private var logText = ECSDKLog.logText
    
    @State var showToast = false
    @State var toastText = ""
    
    @State var extNo = ""
    @State var extPwd = ""
    
    @State var sipHost = ""
    @State var sipPort = 0
    
    
    @State var domain = ""
    @State var makeCall = ""
    @State var dtmf = ""
    
    @State var deptId = "1"
    
    @State var callID = 0
    
    @State var text: String = "Version: 1.0.0\n"
    
    @EnvironmentObject var profile: Profile
    
    //var callSessionDelegate: CallSessionDelegate = CallSessionDelegate()
    
    
    var body: some View {
        ZStack{
            VStack{
                
                Text("请输入必要的信息进行注册拨打:")
                    .font(.subheadline)
                
                Form{
                    
                    TextField("ExtNo", text: $profile.extNo)
                        .customTextField()
                    TextField("ExtPwd", text: $profile.extPwd)
                        .customTextField()
                    TextField("Domain", text: $profile.domain)
                        .customTextField()
                    TextField("Host", text: $profile.sipHost)
                        .customTextField()
                    
                    TextField("Port", value: $profile.sipPort, format: .number)
                        .customTextField()
                    
                    TextField("MakeCall", text: $profile.makeCall)
                        .customTextField()
                    
                    TextField("Dtmf", text: $profile.dtmf)
                        .customTextField()
                }
                
                
                HStack{
                    Button(action: {
                        ECSDKLog.addLog("初始化")
                        
                        //self.toast.showToast(message: "初始化")
                        
                        ECSDKManager.shared.initSDK(extNo: profile.extNo, extPwd: profile.extPwd, domain: profile.domain)
                        
                    }) {
                        Text("初始化")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 80, height: 20)
                            .background(Color.green)
                            .cornerRadius(15.0)
                    }
                    Button(action: {
                        ECSDKLog.addLog("释放")
                        
                        //self.toast.showToast(message: "释放")
                        ECSDKManager.shared.destorySDK()
                        
                    }) {
                        Text("释放")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 80, height: 20)
                            .background(Color.green)
                            .cornerRadius(15.0)
                    }
                    Button(
                        action: {
                            ECSDKLog.addLog("注册成功")
                            
                            //self.toast.showToast(message: "注册成功")
                            
                            ECSDKManager.shared.register(extNo: profile.extNo, extPwd: profile.extPwd, domain: profile.domain, sipHost: profile.sipHost, sipPort: profile.sipPort)
                            
                        }) {
                            Text("注册")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 80, height: 20)
                                .background(Color.green)
                                .cornerRadius(15.0)
                        }
                    
                    Button(
                        action: {
                            ECSDKLog.addLog("取消注册成功")
                            
                            //self.toast.showToast(message: "取消注册成功")
                            
                            ECSDKManager.shared.unRegister()
                        }) {
                            Text("反注册")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 80, height: 20)
                                .background(Color.green)
                                .cornerRadius(15.0)
                        }
                }
                
                HStack{
                    Button(action: {
                        ECSDKLog.addLog("外呼")
                        
                        //self.toast.showToast(message: "外呼")
                        
                        ECSDKManager.shared.makeCall(phoneNumber: profile.makeCall)
                        
                    }) {
                        Text("外呼")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        
                            .padding()
                            .frame(width: 80, height: 20)
                            .background(Color.green)
                            .cornerRadius(15.0)
                    }
                    Button(
                        action: {
                            ECSDKLog.addLog("接听")
                            
                            //self.toast.showToast(message: "接听")
                            
                            ECSDKManager.shared.answer(callID: profile.callID)
                        }) {
                            Text("接听")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 80, height: 20)
                                .background(Color.green)
                                .cornerRadius(15.0)
                        }
                    
                    Button(
                        action: {
                            ECSDKLog.addLog("Dtmf")
                            //self.toast.showToast(message: "Dtmf")
                            
                            
                        }) {
                            Text("Dtmf")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 80, height: 20)
                                .background(Color.green)
                                .cornerRadius(15.0)
                        }
                    
                    Button(
                        action: {
                            ECSDKLog.addLog("挂断")
                            
                            //self.toast.showToast(message: "挂断")
                            
                            ECSDKManager.shared.hangupAll()
                        }) {
                            Text("挂断")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 80, height: 20)
                                .background(Color.green)
                                .cornerRadius(15.0)
                        }
                    
                    
                }
                
                
                HStack{
                    
                    Button(
                        action: {
                            ECSDKLog.addLog("查询部门信息")
                            
                            //self.toast.showToast(message: "查询部门信息")
                            
                            ECSDKManager.shared.queryDeptList(extNo: profile.extNo, extPwd: profile.extPwd, domain: profile.domain)
                            
                        }) {
                            Text("部门")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 80, height: 20)
                                .background(Color.green)
                                .cornerRadius(15.0)
                        }
                    
                    Button(
                        action: {
                            ECSDKLog.addLog("查询通讯录信息")
                            
                            //self.toast.showToast(message: "查询通讯录信息")
                            
                            ECSDKManager.shared.queryContactList(extNo: profile.extNo, extPwd: profile.extPwd, domain: profile.domain, deptId: profile.deptId)
                            
                        }) {
                            Text("通讯录")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding()
                                .frame(width:80, height: 20)
                                .background(Color.green)
                                .cornerRadius(15.0)
                        }
                    Button(
                        action: {
                            ECSDKLog.addLog("清空日志")
                            
                            //                            ECLogHandler.shared.logData.removeAll()
                            
                            ECSDKManager.shared.queryLocation(extNo: profile.extNo, extPwd: profile.extPwd, domain: profile.domain)
                            
                        }) {
                            Text("清空")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding()
                                .frame(width:80, height: 20)
                                .background(Color.green)
                                .cornerRadius(15.0)
                        }
                    
                    Button(
                        action: {
                            ECSDKLog.addLog("保存配置信息")
                            
                            //self.toast.showToast(message: "保存配置信息")
                            
                            saveData()
                            
                        }) {
                            Text("保存")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 80, height: 20)
                                .background(Color.green)
                                .cornerRadius(15.0)
                        }
                }
                
            }
            //.toast(isShowing: $toast.isShowing, message: toast.message)
            
            
        }
        .padding()
        .onAppear(){
        }
        .onDisappear(){
        }
        
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    TextEditor(text: $logText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGreen))
                        .font(.system(size: 12))
                        .multilineTextAlignment(.leading)
                        .disabled(true)
                        .id("logview")
                        .onChange(of: logText) { _ in
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                }
            }
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            self.logText = ECSDKLog.logText
        }
        
        Spacer()
    }
    
    
    
    
    
    func saveData() {
        UserDefaults.standard.set(extNo, forKey: "extNo")
        UserDefaults.standard.set(extPwd, forKey: "extPwd")
        UserDefaults.standard.set(domain, forKey: "domain")
        UserDefaults.standard.set(makeCall, forKey: "makeCall")
        UserDefaults.standard.set(dtmf, forKey: "dtmf")
    }
    
    func loadData() {
        extNo = UserDefaults.standard.string(forKey: "extNo") ?? ""
        extPwd = UserDefaults.standard.string(forKey: "extPwd") ?? ""
        domain = UserDefaults.standard.string(forKey: "domain") ?? ""
        makeCall = UserDefaults.standard.string(forKey: "makeCall") ?? ""
        dtmf = UserDefaults.standard.string(forKey: "dtmf") ?? ""
        
        if(extNo == ""){
            extNo = "5213"
            extPwd = "QXL35UKT"
            domain = "vorsbc.dictccyun.com"
            makeCall = "95566"
            sipHost = "218.78.0.205"
            sipPort = 60000
            dtmf = "*"
        }
        
        //        if(extNo == ""){
        //            extNo = "500017013"
        //            extPwd = "314159"
        //            domain = "106.39.87.89"
        //            makeCall = "500017014"
        //            sipHost = "106.39.87.89"
        //            sipPort = 10210
        //            dtmf = "*"
        //        }
        
    }
    
    func updateLocation(host:String,port:Int){
        sipHost = host
        sipPort = port
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}




