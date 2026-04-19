import SwiftUI
import StoreKit

// MARK: - Subscription Product IDs
enum SubscriptionProduct: String, CaseIterable, Identifiable {
    case weekly = "com.textcraft.premium.weekly"
    case monthly = "com.textcraft.premium.monthly"
    case yearly = "com.textcraft.premium.yearly"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .weekly: return "周付"
        case .monthly: return "月付"
        case .yearly: return "年付"
        }
    }
    
    var priceDescription: String {
        switch self {
        case .weekly: return "¥6/周"
        case .monthly: return "¥18/月"
        case .yearly: return "¥128/年 (省50%)"
        }
    }
    
    var badge: String? {
        switch self {
        case .weekly: return nil
        case .monthly: return "热门"
        case .yearly: return "最划算"
        }
    }
}

// MARK: - Subscription Manager
@MainActor
class SubscriptionManager: ObservableObject {
    @Published var isSubscribed = false
    @Published var products: [Product] = []
    @Published var purchaseState: PurchaseState = .idle
    
    enum PurchaseState {
        case idle
        case loading
        case success
        case failed(String)
    }
    
    private var updateListenerTask: Task<Void, Error>?
    private var transactionListener: Transaction.Updates?
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: SubscriptionProduct.allCases.map(\.rawValue))
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async {
        purchaseState = .loading
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateSubscriptionStatus()
                purchaseState = .success
                
            case .userCancelled, .pending:
                purchaseState = .idle
                
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            print("Failed to restore: \(error)")
        }
    }
    
    private func updateSubscriptionStatus() async {
        var subscribed = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productType == .autoRenewable {
                    subscribed = true
                }
            } catch {
                // Skip unverified transactions
            }
        }
        
        isSubscribed = subscribed
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    // Skip unverified
                }
            }
        }
    }
}

// MARK: - Paywall View
struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("解锁 TextCraft 高级版")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("去除水印 · 解锁全部模板 · 持续更新")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Features
                VStack(spacing: 16) {
                    featureRow(icon: "drop.triangle", title: "去除水印")
                    featureRow(icon: "paintpalette", title: "解锁全部 10 款模板")
                    featureRow(icon: "sparkles", title: "未来新模板优先体验")
                    featureRow(icon: "arrow.triangle.2.circlepath", title: "取消随时可退")
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Products
                if subscriptionManager.products.isEmpty {
                    ProgressView("加载中...")
                } else {
                    VStack(spacing: 12) {
                        ForEach(subscriptionManager.products, id: \.id) { product in
                            productRow(product)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Purchase Button
                Button(action: purchaseSelected) {
                    Group {
                        if subscriptionManager.purchaseState == .loading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(subscribeButtonText)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedProduct != nil ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(selectedProduct == nil || subscriptionManager.purchaseState == .loading)
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Restore
                Button(action: { Task { await subscriptionManager.restorePurchases() } }) {
                    Text("恢复已购买")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .onChange(of: subscriptionManager.purchaseState) { _, newState in
                if newState == .success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func featureRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 24)
            Text(title)
                .font(.body)
            Spacer()
        }
    }
    
    private func productRow(_ product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id
        let subscription = SubscriptionProduct.allCases.first { $0.rawValue == product.id }
        
        return Button(action: { selectedProduct = product }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription?.displayName ?? product.displayName)
                        .fontWeight(isSelected ? .semibold : .regular)
                    Text(subscription?.priceDescription ?? product.displayPrice)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let badge = subscription?.badge {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .gray)
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var subscribeButtonText: String {
        if let product = selectedProduct {
            return "订阅 \(product.displayPrice)"
        }
        return "选择订阅方案"
    }
    
    private func purchaseSelected() {
        guard let product = selectedProduct else { return }
        Task {
            await subscriptionManager.purchase(product)
        }
    }
}
