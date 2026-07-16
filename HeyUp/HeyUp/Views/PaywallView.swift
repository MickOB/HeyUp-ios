import StoreKit
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var vm: HeyUpViewModel
    @Environment(\.openURL) private var openURL
    @State private var selectedProductID = PurchaseManager.annualID

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Button("‹ Not now") { vm.closePaywall() }
                        .buttonStyle(SecondaryPillStyle())
                    Spacer()
                }

                HeyUpWordmark(size: 42)
                Text("Build strength into the day you already have")
                    .font(.system(size: 29, weight: .heavy))
                    .multilineTextAlignment(.center)
                Text("Choose the plan that fits your routine. Annual Pro includes 7 days free.")
                    .font(.system(size: 16))
                    .foregroundColor(HeyUpColor.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    benefit("Stay consistent without planning long workouts")
                    benefit("Let HeyUp remind you and count every rep")
                    benefit("Mix and combine exercises automatically")
                    benefit("See your progress build over time")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(HeyUpColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(HeyUpColor.border))

                if vm.purchaseManager.isLoading {
                    ProgressView("Loading Apple purchase options…")
                        .tint(HeyUpColor.accent)
                        .foregroundColor(HeyUpColor.textMuted)
                        .padding(.vertical, 30)
                } else {
                    VStack(spacing: 12) {
                        subscriptionCard(
                            product: vm.purchaseManager.annualProduct,
                            id: PurchaseManager.annualID,
                            title: "Annual Pro",
                            price: annualMonthlyPrice,
                            detail: "7 days free · then \(annualFullPrice) per year",
                            badge: "BEST VALUE · SAVE \(annualSavingsPercent)%"
                        )
                        subscriptionCard(
                            product: vm.purchaseManager.monthlyProduct,
                            id: PurchaseManager.monthlyID,
                            title: "Monthly Pro",
                            price: monthlyPrice,
                            detail: "Billed monthly · cancel anytime",
                            badge: nil
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("PREFER TO PAY ONCE?")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(HeyUpColor.textFaint)
                            .tracking(0.7)
                        lifetimeCard
                    }
                    .padding(.top, 8)
                }

                if let error = vm.purchaseManager.purchaseError {
                    Text(error)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(HeyUpColor.warn)
                        .multilineTextAlignment(.center)
                }

                Button("Restore purchases") {
                    Task { await vm.purchaseManager.restorePurchases() }
                }
                .disabled(vm.purchaseManager.isPurchasing)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(HeyUpColor.accent)

                HStack(spacing: 20) {
                    Button("Privacy") {
                        openURL(URL(string: "https://heyup-support.mickbrown562.chatgpt.site/#privacy")!)
                    }
                    Button("Terms") {
                        openURL(URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(HeyUpColor.textMuted)

                Text(legalCopy)
                    .font(.system(size: 11))
                    .foregroundColor(HeyUpColor.textFaint)
                    .multilineTextAlignment(.center)
            }
            .padding(22)
            .padding(.bottom, 88)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 6) {
                purchaseButton
                Text(purchaseDisclosure)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(HeyUpColor.textMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 350)
            }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(HeyUpColor.background.opacity(0.97))
        }
    }

    private var purchaseButton: some View {
        Button {
            guard let product = selectedProduct else {
                vm.purchaseManager.purchaseError = "Apple purchase testing is not connected yet."
                return
            }
            Task {
                if await vm.purchaseManager.purchase(product) {
                    vm.purchaseCompleted()
                }
            }
        } label: {
            Group {
                if vm.purchaseManager.isPurchasing {
                    ProgressView().tint(.black)
                } else {
                    Text(purchaseButtonTitle)
                }
            }
            .font(.system(size: 17, weight: .heavy))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(HeyUpColor.accent)
            .clipShape(Capsule())
        }
        .disabled(vm.purchaseManager.isPurchasing || vm.purchaseManager.isLoading)
    }

    private func benefit(_ text: String) -> some View {
        HStack(spacing: 10) {
            Text("✓")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.black)
                .frame(width: 24, height: 24)
                .background(HeyUpColor.accent)
                .clipShape(Circle())
            Text(text).font(.system(size: 15.5, weight: .semibold))
        }
    }

    private func subscriptionCard(
        product: Product?,
        id: String,
        title: String,
        price: String,
        detail: String,
        badge: String?
    ) -> some View {
        selectionCard(id: id) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.system(size: 18, weight: .heavy))
                        Text(price).font(.system(size: 21, weight: .heavy))
                    }
                    Spacer()
                    selectionIndicator(id: id)
                }
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(0.5)
                        .foregroundColor(.black)
                        .padding(.horizontal, 9)
                        .frame(height: 24)
                        .background(HeyUpColor.accent)
                        .clipShape(Capsule())
                }
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(HeyUpColor.textMuted)
            }
        }
        .accessibilityLabel("\(title), \(product?.displayPrice ?? price), \(detail)")
    }

    private var lifetimeCard: some View {
        selectionCard(id: PurchaseManager.lifetimeID) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Founders Lifetime").font(.system(size: 18, weight: .heavy))
                        Text(lifetimePrice).font(.system(size: 21, weight: .heavy))
                    }
                    Spacer()
                    selectionIndicator(id: PurchaseManager.lifetimeID)
                }
                Text("LIMITED LAUNCH AVAILABILITY")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(0.5)
                    .foregroundColor(HeyUpColor.accent)
                Text("One payment. Keep Pro permanently.")
                    .font(.system(size: 13))
                    .foregroundColor(HeyUpColor.textMuted)
            }
        }
    }

    private func selectionCard<Content: View>(
        id: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let selected = selectedProductID == id
        return Button {
            selectedProductID = id
            vm.purchaseManager.purchaseError = nil
        } label: {
            content()
                .foregroundColor(HeyUpColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(17)
                .background(HeyUpColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selected ? HeyUpColor.accent : HeyUpColor.border, lineWidth: selected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func selectionIndicator(id: String) -> some View {
        Circle()
            .strokeBorder(selectedProductID == id ? HeyUpColor.accent : HeyUpColor.border,
                          lineWidth: selectedProductID == id ? 6 : 2)
            .background(Circle().fill(HeyUpColor.background))
            .frame(width: 22, height: 22)
    }

    private var selectedProduct: Product? {
        switch selectedProductID {
        case PurchaseManager.monthlyID: return vm.purchaseManager.monthlyProduct
        case PurchaseManager.lifetimeID: return vm.purchaseManager.lifetimeProduct
        default: return vm.purchaseManager.annualProduct
        }
    }

    private var purchaseButtonTitle: String {
        switch selectedProductID {
        case PurchaseManager.monthlyID: return "Continue with Monthly Pro"
        case PurchaseManager.lifetimeID: return "Unlock Lifetime Pro"
        default: return "Try 7 days free"
        }
    }

    private var purchaseDisclosure: String {
        switch selectedProductID {
        case PurchaseManager.monthlyID:
            return "You'll be charged \(monthlyPrice) today. Cancel anytime."
        case PurchaseManager.lifetimeID:
            return "You'll be charged \(lifetimePrice). No subscription."
        default:
            return "You won't be charged today. After 7 days, your \(annualFullPrice)-per-year plan begins unless you cancel before the trial ends."
        }
    }

    private var monthlyPrice: String {
        "\(vm.purchaseManager.monthlyProduct?.displayPrice ?? "$8.99") / month"
    }

    private var annualFullPrice: String {
        vm.purchaseManager.annualProduct?.displayPrice ?? "$49.99"
    }

    private var annualMonthlyPrice: String {
        guard let annual = vm.purchaseManager.annualProduct else { return "$4.17 / month" }
        return "\((annual.price / 12).formatted(annual.priceFormatStyle)) / month"
    }

    private var lifetimePrice: String {
        "\(vm.purchaseManager.lifetimeProduct?.displayPrice ?? "$99.99") once"
    }

    private var annualSavingsPercent: Int {
        guard let monthly = vm.purchaseManager.monthlyProduct,
              let annual = vm.purchaseManager.annualProduct else { return 54 }
        let fullMonthlyYear = monthly.price * 12
        guard fullMonthlyYear > 0 else { return 54 }
        let savings = (fullMonthlyYear - annual.price) / fullMonthlyYear * 100
        return NSDecimalNumber(decimal: savings).intValue
    }

    private var legalCopy: String {
        if selectedProductID == PurchaseManager.lifetimeID {
            return "Lifetime Pro is a one-time purchase charged to your Apple Account."
        }
        return "Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Payment is charged to your Apple Account."
    }
}
