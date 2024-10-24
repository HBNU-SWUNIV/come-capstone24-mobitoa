//
//  LoggingService.swift
//  NetHawk
//
//  Created by mobicom on 10/8/24.
//

import Foundation

class LoggingService {

    // 싱글톤 인스턴스
    static let shared = LoggingService()

    // 로그를 저장할 키 값 (SerialNumber 기반)
    private var logKey: String {
        if let serialInfo = KeychainManager.shared.load() {
            let serialNumber = serialInfo.serialNumber
            return "mqttLogs_\(serialNumber)"
        } else {
            return "mqttLogs_defaultSerial"
        }
    }

    private init() {}  // 외부에서 초기화하지 못하도록 private init 사용

    // 로그 추가 메서드 (Log 구조체 저장)
    func logMessage(_ message: Log) {
        // UserDefaults에서 저장된 JSON 문자열 배열을 가져옴 (String 배열)
        var logs = UserDefaults.standard.stringArray(forKey: logKey) ?? []

        // Log 구조체를 JSON으로 인코딩한 후 문자열로 변환
        if let logData = try? JSONEncoder().encode(message),
           let logString = String(data: logData, encoding: .utf8) {
            logs.append(logString)  // 문자열로 변환된 로그 추가
            saveLogs(logs)  // 업데이트된 로그 저장
        }
    }

    // 로그 저장 메서드 (UserDefaults에 저장 - JSON 문자열로 저장)
    private func saveLogs(_ logs: [String]) {
        UserDefaults.standard.set(logs, forKey: logKey)
    }

    // 저장된 로그 가져오는 메서드 (Log 구조체로 변환)
    func getLogs() -> [Log] {
        let logStrings = UserDefaults.standard.stringArray(forKey: logKey) ?? []
        let logs = logStrings.compactMap { logString in
            if let logData = logString.data(using: .utf8) {
                return try? JSONDecoder().decode(Log.self, from: logData)
            }
            return nil
        }

        // 최신 로그가 위에 오도록 내림차순 정렬
        return logs.reversed()
    }


    // 로그 삭제 메서드
    func clearLogs() {
        UserDefaults.standard.removeObject(forKey: logKey)
    }
}

