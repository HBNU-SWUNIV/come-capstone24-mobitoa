//
//  MQTTService.swift
//  NetHawk
//
//  Created by mobicom on 6/6/24.
//

import CocoaMQTT
import Foundation
import UIKit

class MQTTService: CocoaMQTTDelegate {

    static let shared = MQTTService() // 싱글톤 인스턴스

    private var mqtt: CocoaMQTT?
    var onConnectionSuccess: (() -> Void)?
    var onConnectionFailure: (() -> Void)?
    var onPingReceived: (() -> Void)?
    var onPongReceived: (() -> Void)?
    var onDisconnected: (() -> Void)?

    // private init을 통해 외부에서 새로운 인스턴스를 생성하지 못하게 막음
    private init() { }

    // MQTT 클라이언트를 설정하는 함수
    func configure(clientID: String, host: String, port: UInt16) {
        mqtt = CocoaMQTT(clientID: clientID, host: host, port: port)
        mqtt?.delegate = self
        mqtt?.autoReconnect = true
        mqtt?.keepAlive = 30
    }

    func connect() {
        mqtt?.connect()
    }

    func disconnect() {
        mqtt?.disconnect()
    }

    func isConnected() -> Bool {
        return mqtt?.connState == .connected
    }

    func subscribe(topic: String, qos: CocoaMQTTQoS = .qos1) {
        mqtt?.subscribe(topic, qos: qos)
    }

    func unsubscribe(topic: String) {
        mqtt?.unsubscribe(topic)
    }

    func publish(topic: String, message: String, qos: CocoaMQTTQoS = .qos1, retained: Bool = false) {
        mqtt?.publish(topic, withString: message, qos: qos, retained: retained)
    }

    // MARK: - CocoaMQTTDelegate

    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .accept {
            onConnectionSuccess?()

            // 로그 초기화하기 (임시)
            // LoggingService.shared.clearLogs()

            // 키체인에서 시리얼 넘버와 별칭 로드 & 토픽 구독
            if let credentials = KeychainManager.shared.load() {
                let serialNumber = credentials.serialNumber
                let alias = credentials.alias
                // 연결된 필터 알림 수신
                subscribe(topic: "\(serialNumber)/alarm")
                // 블랙리스트 & 화이트리스트
                subscribe(topic: "\(serialNumber)")
                subscribe(topic: "\(alias)")
            }

        } else {
            onConnectionFailure?()
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("MQTT message published: \(message.string ?? ""), id: \(id)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("MQTT message published with ACK: \(id)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {

        if let messageString = message.string {
            if let parsedData = parseMQTTMessage(messageString) {
                print("-------[Received Data]-------")
                print("Parsed Data : \n\(parsedData)")
                print("")

                // 블랙리스트, 화이트리스트에 대한 파싱
                if let command = parsedData["command"] as? String {
                    print(command)

                    switch command {
                    case "blacklist_acquire":
                        if let ipList = parsedData["return"] as? [String] {
                            print("blacklist_acquire")
                            handleBlacklistAcquired(ipList: ipList)
                        }
                    case "whitelist_acquire":
                        if let ipList = parsedData["return"] as? [String] {
                            print("whitelist_acquire")
                            handleWhitelistAcquired(ipList: ipList)
                        }
                    case "blacklist_modify":
                        if let parameters = parsedData["parameters"] as? [String: Any],
                           let ipList = parameters["ip_list"] as? [String] {
                            print("blacklist_modify")
                            handleBlacklistAcquired(ipList: ipList)

                        }
                    case "whitelist_modify":
                        if let parameters = parsedData["parameters"] as? [String: Any],
                           let ipList = parameters["ip_list"] as? [String] {
                            print("whitelist_modify")
                            handleWhitelistAcquired(ipList: ipList)
                        }
                    default:
                        print("알 수 없는 명령어: \(command)")
                    }
                }

                // 공격 탐지에 대한 파싱
                if let type = parsedData["type"] as? String, let data = parsedData["data"] as? [String: Any] {
                    switch type {
                    case "Domain phishing":
                        handleDomainSpoof(data: data)
                    case "TCP-Flooding":
                        handleTCPFlooding(data: data)
                    case "UDP-Flooding":
                        handleUDPFlooding(data: data)
                    default:
                        print("알 수 없는 공격 유형: \(type)")
                    }
                }
            }
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        print("Successfully subscribed to topics: \(success)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        print("Successfully unsubscribed from topics: \(topics)")
    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print(" ------Server Checking------")
        print("|           ping            |")
    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        print("|           pong            |")
        print("|          its ok.          |")
        print(" ---------------------------")
        print("")
        onPongReceived?()
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        print("MQTT disconnected: \(err?.localizedDescription ?? "")")
        onDisconnected?()
        onConnectionFailure?()
    }

    // MARK: - Log 파싱

    // 로그 파싱 함수
    func parseMQTTMessage(_ message: String) -> [String: Any]? {
        if let data = message.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                return json
            } catch {
                print("Error parsing MQTT message: \(error)")
            }
        }
        return nil
    }

    func handleDomainSpoof(data: [String: Any]) {
        if let timestamp = data["timestamp"] as? String,
           let invaderAddress = data["invader_address"] as? String?,
           let victimAddress = data["victim_address"] as? String,
           let victimName = data["victim_name"] as? String {

            let logEntry = Log(timestamp: timestamp, type: "Domain phishing", invaderAddress: invaderAddress, victimAddress: victimAddress, victimName: victimName)

            // 로그 저장 및 처리
            LoggingService.shared.logMessage(logEntry)

            // 로컬 알림 전송
            sendLocalNotification(for: logEntry)

            // NotificationCenter로 로그 추가 알림
            NotificationCenter.default.post(name: NSNotification.Name("NewLogReceived"), object: nil, userInfo: ["log": logEntry])

            print("도메인 피싱 공격 탐지:")
            print("Time Stamp: \(timestamp)\nInvader Address: \(String(describing: invaderAddress!))\nVictim Address: \(victimAddress)\nVictim Name: \(victimName)\n-----------------------------\n")
        }
    }

    func handleTCPFlooding(data: [String: Any]) {
        if let timestamp = data["timestamp"] as? String,
           let victimAddress = data["victim_address"] as? String,
           let victimName = data["victim_name"] as? String {

            let logEntry = Log(timestamp: timestamp, type: "TCP-Flooding", invaderAddress: "-", victimAddress: victimAddress, victimName: victimName)

            // 로그 저장 및 처리
            LoggingService.shared.logMessage(logEntry)

            // 로컬 알림 전송
            sendLocalNotification(for: logEntry)

            // NotificationCenter로 로그 추가 알림
            NotificationCenter.default.post(name: NSNotification.Name("NewLogReceived"), object: nil, userInfo: ["log": logEntry])

            print("TCP 플러딩 공격 탐지:")
            print("Time Stamp: \(timestamp)\nVictim Address: \(victimAddress)\nVictim Name: \(victimName)\n-----------------------------\n")
        }
    }

    func handleUDPFlooding(data: [String: Any]) {
        if let timestamp = data["timestamp"] as? String,
           let victimAddress = data["victim_address"] as? String,
           let victimName = data["victim_name"] as? String {

            let logEntry = Log(timestamp: timestamp, type: "UDP-Flooding", invaderAddress: "-", victimAddress: victimAddress, victimName: victimName)

            // 로그 저장 및 처리
            LoggingService.shared.logMessage(logEntry)

            // 로컬 알림 전송
            sendLocalNotification(for: logEntry)

            // NotificationCenter로 로그 추가 알림
            NotificationCenter.default.post(name: NSNotification.Name("NewLogReceived"), object: nil, userInfo: ["log": logEntry])

            print("UDP 플러딩 공격 탐지:")
            print("Time Stamp: \(timestamp)\nVictim Address: \(victimAddress)\nVictim Name: \(victimName)\n-----------------------------\n")
        }
    }

    // 블랙리스트, 화이트리스트 획득 수신 정보 전달
    func handleBlacklistAcquired(ipList: [String]) {
        print("go post")
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateBlacklist"),
            object: nil,
            userInfo: ["blacklist": ipList]
        )
    }

    func handleWhitelistAcquired(ipList: [String]) {
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateWhitelist"),
            object: nil,
            userInfo: ["whitelist": ipList]
        )
    }

    // MARK: - 백그라운드 작업
    // MQTT Ping을 주기적으로 보내는 함수
    func startMQTTPing() {
        guard let mqttClient = mqtt else { return }

        // 백그라운드 작업을 시작
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid

        backgroundTask = UIApplication.shared.beginBackgroundTask {
            // 백그라운드 시간이 만료되면 호출
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }

        // Ping 메시지를 보냄
        if backgroundTask != .invalid {
            mqttClient.ping()  // Ping 전송
            print("MQTT Ping sent.")

            // 작업이 종료되면 다시 백그라운드 작업을 시작해 반복적으로 Ping 전송
            DispatchQueue.global().asyncAfter(deadline: .now() + 60) { [weak self] in
                if backgroundTask != .invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                    backgroundTask = .invalid
                }
                // 백그라운드 작업이 끝나면 다시 시작
                self?.startMQTTPing()
            }
        }
    }



    // 포그라운드 복귀 시 MQTT 연결 상태 확인
    func checkConnection() {
        guard let mqttClient = mqtt else { return }

        if ((onDisconnected?()) != nil) {
            print("-----------------------------")
            print("MQTT 연결이 끊어졌습니다. 재연결 시도 중...")
            mqttClient.connect()  // 연결이 끊겼으면 다시 연결
        } else {
            print("-----------------------------")
            print("MQTT 연결이 유지되고 있습니다.")
        }
    }

    // MARK: - 알림
    func sendLocalNotification(for log: Log) {

        let isNotificationEnabled = UserDefaults.standard.integer(forKey: "notificationEnabled")

        guard isNotificationEnabled == 0 else {
            print("알림이 비활성화 상태이므로 알림을 보내지 않습니다.")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "New Attack Detected."
        content.body = "Type: \(log.type)\nVictim: \(log.victimName)\nAddress: \(log.victimAddress)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
}
