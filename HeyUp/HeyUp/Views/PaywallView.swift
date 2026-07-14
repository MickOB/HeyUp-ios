import StoreKit
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var vm: HeyUpViewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Button("‹ Not now") { vm.closePaywall() }
                        .buttonStyle(SecondaryPillStyle())
                    Spacer()
                }

                HeyUpWordmark(size: 42)
                Text("Keep your momentum going")
                    .font(.system(size: 30, weight: .heavy))
                    .multilineTextAlignment(.center)
                Text("Try every Pro feature free for 7 days. Cancel anytime in your Apple Account settings.")
                    .font(.system(size: 16))
                    .foregroundColor(HeyUpColor.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    benefit("Unlimited movement breaks")
                    benefit("Mix exercises automatically")
                    benefit("Combine push-ups and squats")
                    benefit("Full progress history and future Pro programs")
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
                        purchaseCard(
                            product: vm.purchaseManager.annualProduct,
                            title: "Annual Pro",
                            fallbackPrice: "$49.99 / year",
                            badge: "BEST VALUE",
                            detail: "7 days free, then annual billing"
                        )
                        purchaseCard(
                            product: vm.purchaseManager.monthlyProduct,
                            title: "Monthly Pro",
                            fallbackPrice: "$8.99 / month",
                            badge: nil,
                            detail: "7 days free, then monthly billing"
                        )
                        purchaseCard(
                            product: vm.purchaseManager.lifetimeProduct,
                            title: "Founders Lifetime",
                            fallbackPrice: "$99.99 once",
                            badge: "LIMITED LAUNCH OFFER",
                            detail: "Pay once. Keep Pro permanently."
                        )
                    }
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

                Text("Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Payment is charged to your Apple Account.")
                    .font(.system(size: 11))
                    .foregroundColor(HeyUpColor.textFaint)
                    .multilineTextAlignment(.center)
            }
            .padding(22)
        }
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

    private func purchaseCard(
        product: Product?,
        title: String,
        fallbackPrice: String,
        badge: String?,
        detail: String
    ) -> some View {
        Button {
            guard let product else {
                vm.purchaseManager.purchaseError = "Apple purchase testing is not connected yet."
                return
            }
            Task {
                if await vm.purchaseManager.purchase(product) {
                    vm.purchaseCompleted()
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title).font(.system(size: 18, weight: .heavy))
                    Spacer()
                    Text(product?.displayPrice ?? fallbackPrice)
                        .font(.system(size: 16, weight: .bold))
                }
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(0.6)
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
            .foregroundColor(HeyUpColor.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(17)
            .background(HeyUpColor.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(title == "Annual Pro" ? HeyUpColor.accent : HeyUpColor.border, lineWidth: title == "Annual Pro" ? 2 : 1))
        }
        .disabled(vm.purchaseManager.isPurchasing)
    }
}
