import SwiftUI

class Toast: ObservableObject {
    @Published var isShowing: Bool = false
    @Published var message: String = ""

    init(message: String = "", isShowing: Bool = false) {
        self.message = message
        self.isShowing = isShowing
    }

    func showToast(message: String, duration: TimeInterval = 2.0) {
        self.message = message
        self.isShowing = true

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.isShowing = false
        }
    }
}

struct ToastView<Content>: View where Content: View {
    @Binding var isShowing: Bool
    let message: String
    let content: () -> Content

    var body: some View {
        ZStack(alignment: .center) {
            Group {
                content()
            }
            .disabled(isShowing)
            .blur(radius: isShowing ? 10 : 0)

            VStack {
                Text(message)
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black)
                    .cornerRadius(50)
                    .shadow(radius: 20)

            }
            .opacity(isShowing ? 1 : 0)
            .offset(x: 0, y: isShowing ? 100 : UIScreen.main.bounds.size.height)
            .animation(.spring(response: 0.5, dampingFraction: 0.5))
            .background(Color.clear) // 添加一个透明的背景视图
        }
    }
}


extension View {
    func toast(isShowing: Binding<Bool>, message: String) -> some View {
        ToastView(isShowing: isShowing, message: message, content: { self })
    }
}
