//
//  PremiumStatus.swift
//  BoxFanNoise
//

import Combine
import Foundation
import SuperwallKit

@MainActor
final class PremiumStatus: ObservableObject {
    static let shared = PremiumStatus()

    @Published private(set) var isPremium: Bool = false

    private var cancellable: AnyCancellable?

    private init() {
        cancellable = Superwall.shared.$subscriptionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if case .active = status {
                    self?.isPremium = true
                } else {
                    self?.isPremium = false
                }
            }
    }
}
