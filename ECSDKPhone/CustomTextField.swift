//
//  CustomTextField.swift
//  ECSDKPhone
//
//  Created by DerekHu on 2022/8/5.
//

import SwiftUI

let lightGreyColor = Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0)
let textColor = Color(red: 30.0/255.0, green: 30.0/255.0, blue: 30.0/255.0, opacity: 1.0)


struct CustomTextField: ViewModifier{
    func body(content: Content) -> some View {
        content
            .font(.system(size: 12))
            .frame(height: 0)
            .padding()
            .padding(.bottom, 1)
            .background(lightGreyColor)
            .foregroundColor(textColor)
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke()
                .fill(.black.opacity(0.1))
            )
    }
}
 
extension View{
    func customTextField() -> some View {
        modifier(CustomTextField())
    }
}
