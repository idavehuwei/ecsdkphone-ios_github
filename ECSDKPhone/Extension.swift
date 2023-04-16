//
//  Extension.swift
//  ECSDKPhone
//
//  Created by DerekHu on 2022/7/30.
//

import SwiftUI

extension UIApplication{
    
    func endEdit() {
        
        UIApplication.shared.sendAction(#selector(UIResponder
            .resignFirstResponder), to: nil, from: nil, for: nil)

    }
    
}
