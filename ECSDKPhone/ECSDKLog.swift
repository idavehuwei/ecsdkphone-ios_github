import Foundation

class ECSDKLog {
    static var logText = ""
    static let logFilePath: String = {
        #if os(macOS)
        return FileManager.default.currentDirectoryPath + "/ecapp.log"
        #else
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        return "\(documentsPath)/ecapp.log"
        #endif
        
    }()

    static func addLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
  
        let logMessage = "\(formatter.string(from: Date())) EC: \(message)\n"
        logText += logMessage
        print(logMessage) // 同时输出到控制台
        
        // 将日志信息写入文件中
        do {
           try logText.write(toFile: logFilePath, atomically: true, encoding: .utf8)
        } catch {
           print("写入日志文件失败: \(error)")
        }
    }
}
