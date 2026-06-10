import StoreKit
import SwiftUI

/// StoreKit 2 wrapper for the one-time "Pro" unlock (non-consumable).
/// Pro gates: chain series (2x–6x), activity grid + points/levels,
/// iCloud sync, and voice cues. The core pomodoro timer stays free.
@MainActor
final class ProStore: ObservableObject {
    static let productID = "com.activetomato.app.pro"

    @Published private(set) var isPro: Bool
    @Published private(set) var product: Product?
    @Published private(set) var purchasing = false
    @Published var showPaywall = false

    /// Fires once when Pro unlocks so the app can kick off an iCloud sync.
    var onUnlock: (() -> Void)?

    private let cacheKey = "proUnlocked"
    private var updatesTask: Task<Void, Never>?

    init() {
        // Cached so the UI doesn't flash locked while StoreKit wakes up;
        // refreshEntitlement() below re-derives the truth from the receipt.
        isPro = UserDefaults.standard.bool(forKey: cacheKey)
        updatesTask = Task { [weak self] in
            for await update in StoreKit.Transaction.updates {
                guard let tx = try? update.payloadValue else { continue }
                self?.apply(tx)
                await tx.finish()
            }
        }
        Task {
            await refreshEntitlement()
            await loadProduct()
        }
    }

    private func loadProduct() async {
        product = try? await Product.products(for: [Self.productID]).first
    }

    /// Re-derive isPro from the App Store's current entitlements.
    func refreshEntitlement() async {
        var entitled = false
        for await result in StoreKit.Transaction.currentEntitlements {
            guard let tx = try? result.payloadValue else { continue }
            if tx.productID == Self.productID, tx.revocationDate == nil { entitled = true }
        }
        setPro(entitled)
    }

    func purchase() async {
        if product == nil { await loadProduct() }
        guard let product, !purchasing else { return }
        purchasing = true
        defer { purchasing = false }
        guard let result = try? await product.purchase() else { return }
        if case .success(let verification) = result, let tx = try? verification.payloadValue {
            apply(tx)
            await tx.finish()
        }
    }

    func restore() async {
        guard !purchasing else { return }
        purchasing = true
        defer { purchasing = false }
        try? await AppStore.sync()
        await refreshEntitlement()
    }

    private func apply(_ tx: StoreKit.Transaction) {
        guard tx.productID == Self.productID else { return }
        setPro(tx.revocationDate == nil)
    }

    private func setPro(_ value: Bool) {
        let wasUnlocked = isPro
        isPro = value
        UserDefaults.standard.set(value, forKey: cacheKey)
        if value {
            showPaywall = false
            if !wasUnlocked { onUnlock?() }
        }
    }
}
