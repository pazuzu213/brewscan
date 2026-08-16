import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var store = StoreKitService.shared
    @State private var selectedPlanId: String = StoreKitService.yearlyId
    @State private var isRestoring = false
    @State private var showError = false

    private let features: [(String, String)] = [
        ("camera.viewfinder",    "Unlimited pod scans"),
        ("bookmark.fill",        "Save scans & recipes"),
        ("heart.fill",           "Favourite pods"),
        ("chart.bar.fill",       "Full brew history"),
        ("person.fill",          "Personalised recommendations"),
        ("star.fill",            "Early access to new features"),
    ]

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        header
                        featuresSection
                        planSelector
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 56)
                    .padding(.bottom, 20)
                }

                ctaSection
            }
        }
        .preferredColorScheme(.dark)
        .alert("Purchase failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.purchaseError ?? "Something went wrong. Please try again.")
        }
        .onChange(of: store.purchaseError) { err in
            if err != nil { showError = true }
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            Color(hex: "#0D0805").ignoresSafeArea()
            LinearGradient(
                colors: [Color(hex: "#C8860A").opacity(0.12), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            Text("☕")
                .font(.system(size: 64))

            Text("BrewScan Pro")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)

            if appState.isTrialExpired {
                Label("Your free trial has ended", systemImage: "clock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#C8860A"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#C8860A").opacity(0.15))
                    .cornerRadius(20)
            } else {
                Text("Start your 7-day free trial")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#B0A090"))
            }
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(features, id: \.0) { icon, text in
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#C8860A"))
                        .frame(width: 22)

                    Text(text)
                        .font(.system(size: 15))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#C8860A"))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 13)
                .background(Color(hex: "#2D1F15"))
                .cornerRadius(14)
            }
        }
    }

    // MARK: - Plan Selector

    private var planSelector: some View {
        VStack(spacing: 10) {
            if store.products.isEmpty {
                planPlaceholder(id: StoreKitService.yearlyId,  title: "Annual",  price: "$19.99/year",  badge: "Best Value", isSelected: selectedPlanId == StoreKitService.yearlyId)
                planPlaceholder(id: StoreKitService.monthlyId, title: "Monthly", price: "$2.99/month", badge: nil,          isSelected: selectedPlanId == StoreKitService.monthlyId)
            } else {
                if let yearly = store.yearlyProduct {
                    planCard(product: yearly, title: "Annual", badge: "Best Value", saving: yearlySaving)
                }
                if let monthly = store.monthlyProduct {
                    planCard(product: monthly, title: "Monthly", badge: nil, saving: nil)
                }
            }
        }
    }

    private func planCard(product: Product, title: String, badge: String?, saving: String?) -> some View {
        let isSelected = selectedPlanId == product.id
        return Button { selectedPlanId = product.id } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isSelected ? .white : Color(hex: "#B0A090"))
                        if let badge {
                            Text(badge)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "#1A0F0A"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: "#C8860A"))
                                .cornerRadius(8)
                        }
                    }
                    if let saving {
                        Text(saving)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#C8860A"))
                    }
                }

                Spacer()

                Text(product.displayPrice + (title == "Annual" ? "/yr" : "/mo"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? .white : Color(hex: "#B0A090"))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(isSelected ? Color(hex: "#3D2A1A") : Color(hex: "#2D1F15"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: "#C8860A") : Color.clear, lineWidth: 1.5)
            )
        }
    }

    private func planPlaceholder(id: String, title: String, price: String, badge: String?, isSelected: Bool) -> some View {
        Button { selectedPlanId = id } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isSelected ? .white : Color(hex: "#B0A090"))
                        if let badge {
                            Text(badge)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "#1A0F0A"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: "#C8860A"))
                                .cornerRadius(8)
                        }
                    }
                }
                Spacer()
                Text(price)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? .white : Color(hex: "#B0A090"))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(isSelected ? Color(hex: "#3D2A1A") : Color(hex: "#2D1F15"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: "#C8860A") : Color.clear, lineWidth: 1.5)
            )
        }
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            // Main CTA
            Button(action: purchaseSelected) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(hex: "#C8860A"))
                    if store.isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(appState.isTrialExpired ? "Subscribe Now" : "Start Free Trial")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "#1A0F0A"))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
            }
            .disabled(store.isPurchasing || isRestoring)

            // Restore
            Button {
                Task {
                    isRestoring = true
                    await store.restorePurchases()
                    isRestoring = false
                }
            } label: {
                Text(isRestoring ? "Restoring…" : "Restore Purchases")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#B0A090"))
            }
            .disabled(store.isPurchasing || isRestoring)

            // Legal
            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://brewscan.app/privacy")!)
                Text("•").foregroundColor(Color(hex: "#B0A090").opacity(0.4))
                Link("Terms of Use", destination: URL(string: "https://brewscan.app/terms")!)
            }
            .font(.system(size: 11))
            .foregroundColor(Color(hex: "#B0A090").opacity(0.5))
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 32)
        .background(
            Color(hex: "#0D0805")
                .shadow(color: .black.opacity(0.4), radius: 12, y: -4)
        )
    }

    // MARK: - Helpers

    private func purchaseSelected() {
        Task {
            let product = store.products.first { $0.id == selectedPlanId }
            guard let product else {
                if !appState.isTrialExpired {
                    appState.startTrial()
                }
                return
            }
            _ = await store.purchase(product)
        }
    }

    private var yearlySaving: String? {
        guard let monthly = store.monthlyProduct,
              let yearly  = store.yearlyProduct else { return "Save ~44% vs monthly" }
        let monthlyAnnual = monthly.price * 12
        guard monthlyAnnual > 0 else { return nil }
        let saving = ((monthlyAnnual - yearly.price) / monthlyAnnual * 100)
        return String(format: "Save %.0f%% vs monthly", NSDecimalNumber(decimal: saving).doubleValue)
    }
}
