//
//  StatisticsService.swift
//  NetHawk
//
//  Created by mobicom on 10/22/24.
//

import Foundation

class StatisticsService {
    static let shared = StatisticsService()

    private init() {}  // Singleton pattern

    // 공격 유형별 발생 횟수 계산
    func getAttackTypeCounts(from logs: [Log]) -> [String: Int] {
        var attackCounts: [String: Int] = [
            "Domain phishing": 0,
            "TCP-Flooding": 0,
            "UDP-Flooding": 0,
            //"Unknown Attack": 0
        ]

        for log in logs {
            attackCounts[log.type, default: 0] += 1
        }
        return attackCounts
    }

    // 시간대별 공격 발생 횟수 계산 (시간대는 시간만 추출하여 그룹화)
    func getHourlyAttackCounts(from logs: [Log]) -> [String: Int] {
        var hourlyCounts: [String: Int] = [:]

        let dateFormatter = DateFormatter()
        // 밀리초와 타임존까지 처리할 수 있는 포맷으로 수정했음!
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"

        for log in logs {
            if let date = dateFormatter.date(from: log.timestamp) {
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: date)
                let hourString = String(format: "%02d:00", hour)

                // 시간대별로 공격 횟수를 집계
                hourlyCounts[hourString, default: 0] += 1
            }
        }

        print(hourlyCounts)
        return hourlyCounts
    }


    // 피해자별 공격 횟수 계산
    func getVictimAttackCounts(from logs: [Log]) -> [String: Int] {
        var victimCounts: [String: Int] = [:]

        for log in logs {
            victimCounts[log.victimName, default: 0] += 1
        }
        return victimCounts
    }

    // 공격자별 발생 빈도 계산 (invaderAddress가 있는 경우)
    func getInvaderAttackCounts(from logs: [Log]) -> [String: Int] {
        var invaderCounts: [String: Int] = [:]

        for log in logs {
            if let invader = log.invaderAddress {
                invaderCounts[invader, default: 0] += 1
            }
        }
        return invaderCounts
    }

    // 특정 공격 유형의 시간에 따른 발생 추세 계산
    func getAttackTrend(for type: String, from logs: [Log]) -> [String: Int] {
        var trendCounts: [String: Int] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        for log in logs {
            if log.type == type, let date = dateFormatter.date(from: log.timestamp) {
                let dateString = dateFormatter.string(from: date)
                trendCounts[dateString, default: 0] += 1
            }
        }
        return trendCounts
    }
}
