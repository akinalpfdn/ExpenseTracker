//
//  SettingsView.swift
//  ExpenseTracker
//
//  App settings and category management screen with comprehensive configuration options
//

import SwiftUI
import Foundation

struct SettingsView: View {
    // MARK: - Environment Objects

    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var categoryRepository: CategoryRepository

    // MARK: - State

    @Environment(\.dismiss) var dismiss
    @State private var selectedSettingsSection: SettingsSection = .general
    @State private var showingCategoryManagement = false
    @State private var showingAbout = false
    @State private var showingExportOptions = false
    @State private var showingResetConfirmation = false

    // Temporary state for settings
    @State private var tempCurrency: String = ""
    @State private var tempDailyLimit: Double = 0
    @State private var tempMonthlyLimit: Double = 0
    @State private var tempNotificationsEnabled: Bool = false
    @State private var tempHapticFeedbackEnabled: Bool = false
    @State private var tempTheme: ThemeMode = .system

    // Animation state
    @State private var isLoaded = false

    enum SettingsSection: String, CaseIterable {
        case general = "general"
        case categories = "categories"
        case notifications = "notifications"
        case privacy = "privacy"
        case about = "about"

        var title: String {
            switch self {
            case .general:
                return L("general_settings")
            case .categories:
                return L("categories")
            case .notifications:
                return L("notifications")
            case .privacy:
                return L("privacy_security")
            case .about:
                return L("about_app")
            }
        }

        var iconName: String {
            switch self {
            case .general:
                return "gear"
            case .categories:
                return "folder.fill"
            case .notifications:
                return "bell.fill"
            case .privacy:
                return "lock.shield.fill"
            case .about:
                return "info.circle.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.themedBackground(appTheme.colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Header Section
                    headerSection

                    // MARK: - Settings Content
                    settingsContentSection
                }
            }
            .navigationBarHidden(true)
            .themedBackground()
            .onAppear {
                loadCurrentSettings()
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    isLoaded = true
                }
            }
            .sheet(isPresented: $showingCategoryManagement) {
                CategoryManagementView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportDataView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .alert(L("reset_confirmation"), isPresented: $showingResetConfirmation) {
                Button(L("cancel"), role: .cancel) { }
                Button(L("reset"), role: .destructive) {
                    resetAllSettings()
                }
            } message: {
                Text(L("reset_confirmation_message"))
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Top header with title and close button
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .themedTextColor()
                }

                Spacer()

                Text(L("settings"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .themedTextColor()

                Spacer()

                Button(action: { saveSettings() }) {
                    Text(L("save"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }

            // Settings section tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(SettingsSection.allCases, id: \.rawValue) { section in
                        SettingSectionTab(
                            section: section,
                            isSelected: selectedSettingsSection == section
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedSettingsSection = section
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Settings Content Section

    private var settingsContentSection: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch selectedSettingsSection {
                case .general:
                    generalSettingsSection
                case .categories:
                    categoriesSettingsSection
                case .notifications:
                    notificationsSettingsSection
                case .privacy:
                    privacySettingsSection
                case .about:
                    aboutSettingsSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 20)
        .animation(.easeOut(duration: 0.6), value: isLoaded)
    }

    // MARK: - General Settings Section

    private var generalSettingsSection: some View {
        VStack(spacing: 20) {
            // Currency settings
            SettingsGroup(title: L("currency_preferences")) {
                VStack(spacing: 16) {
                    SettingsRow(
                        title: L("default_currency"),
                        subtitle: L("currency_used_for_new_expenses"),
                        icon: "banknote"
                    ) {
                        Menu {
                            ForEach(settingsManager.getAvailableCurrencies(), id: \.self) { currency in
                                Button(currency) {
                                    tempCurrency = currency
                                }
                            }
                        } label: {
                            HStack {
                                Text(tempCurrency)
                                    .themedTextColor()
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .themedSecondaryTextColor()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .themedCardBackground()
                            .cornerRadius(12)
                        }
                    }
                }
            }

            // Budget settings
            SettingsGroup(title: L("budget_limits")) {
                VStack(spacing: 16) {
                    SettingsNumberRow(
                        title: L("daily_limit"),
                        subtitle: L("maximum_daily_spending"),
                        icon: "calendar.badge.clock",
                        value: $tempDailyLimit,
                        currency: tempCurrency
                    )

                    SettingsNumberRow(
                        title: L("monthly_limit"),
                        subtitle: L("maximum_monthly_spending"),
                        icon: "calendar",
                        value: $tempMonthlyLimit,
                        currency: tempCurrency
                    )
                }
            }

            // Appearance settings
            SettingsGroup(title: L("appearance")) {
                VStack(spacing: 16) {
                    SettingsRow(
                        title: L("theme"),
                        subtitle: L("app_appearance_mode"),
                        icon: "paintbrush.fill"
                    ) {
                        Picker(L("theme"), selection: $tempTheme) {
                            Text(L("system")).tag(ThemeMode.system)
                            Text(L("light")).tag(ThemeMode.light)
                            Text(L("dark")).tag(ThemeMode.dark)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                }
            }
        }
    }

    // MARK: - Categories Settings Section

    private var categoriesSettingsSection: some View {
        VStack(spacing: 20) {
            // Category management
            SettingsGroup(title: L("category_management")) {
                VStack(spacing: 16) {
                    SettingsActionRow(
                        title: L("manage_categories"),
                        subtitle: L("add_edit_delete_categories"),
                        icon: "folder.fill",
                        actionText: L("manage")
                    ) {
                        showingCategoryManagement = true
                    }

                    CategorySummaryWidget()
                }
            }
        }
    }

    // MARK: - Notifications Settings Section

    private var notificationsSettingsSection: some View {
        VStack(spacing: 20) {
            // Notification preferences
            SettingsGroup(title: L("notification_preferences")) {
                VStack(spacing: 16) {
                    SettingsToggleRow(
                        title: L("enable_notifications"),
                        subtitle: L("receive_expense_reminders"),
                        icon: "bell.fill",
                        isOn: $tempNotificationsEnabled
                    )

                    if tempNotificationsEnabled {
                        NotificationSettingsDetails()
                    }
                }
            }

            // Feedback settings
            SettingsGroup(title: L("feedback")) {
                VStack(spacing: 16) {
                    SettingsToggleRow(
                        title: L("haptic_feedback"),
                        subtitle: L("vibrate_on_interactions"),
                        icon: "iphone.radiowaves.left.and.right",
                        isOn: $tempHapticFeedbackEnabled
                    )
                }
            }
        }
    }

    // MARK: - Privacy Settings Section

    private var privacySettingsSection: some View {
        VStack(spacing: 20) {
            // Data management
            SettingsGroup(title: L("data_management")) {
                VStack(spacing: 16) {
                    SettingsActionRow(
                        title: L("export_data"),
                        subtitle: L("backup_your_expenses"),
                        icon: "square.and.arrow.up",
                        actionText: L("export")
                    ) {
                        showingExportOptions = true
                    }

                    SettingsActionRow(
                        title: L("reset_all_data"),
                        subtitle: L("permanently_delete_all_data"),
                        icon: "trash.fill",
                        actionText: L("reset"),
                        isDestructive: true
                    ) {
                        showingResetConfirmation = true
                    }
                }
            }
        }
    }

    // MARK: - About Settings Section

    private var aboutSettingsSection: some View {
        VStack(spacing: 20) {
            // App information
            SettingsGroup(title: L("app_information")) {
                VStack(spacing: 16) {
                    SettingsActionRow(
                        title: L("about_app"),
                        subtitle: L("version_and_credits"),
                        icon: "info.circle.fill",
                        actionText: L("view")
                    ) {
                        showingAbout = true
                    }

                    AppVersionWidget()
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func loadCurrentSettings() {
        tempCurrency = settingsManager.currency
        tempDailyLimit = settingsManager.dailyLimit
        tempMonthlyLimit = settingsManager.monthlyLimit
        tempNotificationsEnabled = settingsManager.notificationsEnabled
        tempHapticFeedbackEnabled = settingsManager.hapticFeedbackEnabled
        tempTheme = settingsManager.theme
    }

    private func saveSettings() {
        settingsManager.currency = tempCurrency
        settingsManager.dailyLimit = tempDailyLimit
        settingsManager.monthlyLimit = tempMonthlyLimit
        settingsManager.notificationsEnabled = tempNotificationsEnabled
        settingsManager.hapticFeedbackEnabled = tempHapticFeedbackEnabled
        settingsManager.theme = tempTheme

        settingsManager.saveSettings()
        settingsManager.triggerHapticFeedback(.success)
        dismiss()
    }

    private func resetAllSettings() {
        Task {
            await settingsManager.resetAllData()
            await expenseViewModel.loadExpenses()
            dismiss()
        }
    }
}

// MARK: - Supporting Views

struct SettingSectionTab: View {
    let section: SettingsView.SettingsSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: section.iconName)
                    .font(.title3)
                    .foregroundColor(isSelected ? .orange : .gray)

                Text(section.title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .orange : .gray)
            }
            .frame(width: 80, height: 60)
            .background(isSelected ? .orange.opacity(0.1) : .clear)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .themedTextColor()

            VStack(spacing: 1) {
                content()
            }
            .themedCardBackground()
            .cornerRadius(12)
        }
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let content: () -> Content

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .themedTextColor()

                Text(subtitle)
                    .font(.caption)
                    .themedSecondaryTextColor()
            }

            Spacer()

            content()
        }
        .padding(16)
    }
}

struct SettingsActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let actionText: String
    let isDestructive: Bool
    let action: () -> Void

    init(title: String, subtitle: String, icon: String, actionText: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.actionText = actionText
        self.isDestructive = isDestructive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDestructive ? .red : .orange)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .themedTextColor()

                    Text(subtitle)
                        .font(.caption)
                        .themedSecondaryTextColor()
                }

                Spacer()

                Text(actionText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isDestructive ? .red : .orange)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .themedSecondaryTextColor()
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .themedTextColor()

                Text(subtitle)
                    .font(.caption)
                    .themedSecondaryTextColor()
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .orange))
        }
        .padding(16)
    }
}

struct SettingsNumberRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var value: Double
    let currency: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .themedTextColor()

                Text(subtitle)
                    .font(.caption)
                    .themedSecondaryTextColor()
            }

            Spacer()

            HStack(spacing: 8) {
                TextField("0.00", value: $value, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)

                Text(currency)
                    .font(.subheadline)
                    .themedSecondaryTextColor()
            }
        }
        .padding(16)
    }
}

struct CategorySummaryWidget: View {
    @EnvironmentObject var expenseViewModel: ExpenseViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L("category_overview"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .themedTextColor()

                Spacer()

                Text("\(expenseViewModel.availableCategories.count) " + L("categories"))
                    .font(.caption)
                    .themedSecondaryTextColor()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(expenseViewModel.availableCategories.prefix(5)) { category in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(.orange)
                                .frame(width: 24, height: 24)

                            Text(category.name)
                                .font(.caption2)
                                .themedTextColor()
                                .lineLimit(1)
                        }
                        .frame(width: 50)
                    }

                    if expenseViewModel.availableCategories.count > 5 {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(.gray.opacity(0.3))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text("+\(expenseViewModel.availableCategories.count - 5)")
                                        .font(.caption2)
                                        .themedTextColor()
                                )

                            Text(L("more"))
                                .font(.caption2)
                                .themedSecondaryTextColor()
                        }
                        .frame(width: 50)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        }
        .padding(16)
    }
}

struct NotificationSettingsDetails: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L("notification_types"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .themedTextColor()
                Spacer()
            }

            VStack(spacing: 8) {
                NotificationTypeRow(title: L("daily_reminders"), isEnabled: true)
                NotificationTypeRow(title: L("budget_alerts"), isEnabled: true)
                NotificationTypeRow(title: L("weekly_summaries"), isEnabled: false)
            }
        }
        .padding(16)
        .background(.orange.opacity(0.05))
        .cornerRadius(8)
    }
}

struct NotificationTypeRow: View {
    let title: String
    let isEnabled: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(isEnabled ? .green : .gray)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.caption)
                .themedTextColor()

            Spacer()

            Text(isEnabled ? L("enabled") : L("disabled"))
                .font(.caption2)
                .foregroundColor(isEnabled ? .green : .gray)
        }
    }
}

struct AppVersionWidget: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "creditcard.and.123")
                    .font(.title)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L("expense_tracker"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .themedTextColor()

                    Text(L("version") + " 1.0.0")
                        .font(.subheadline)
                        .themedSecondaryTextColor()
                }

                Spacer()
            }

            Divider()

            VStack(spacing: 8) {
                AppInfoRow(title: L("developer"), value: "Akinalp Fidan")
                AppInfoRow(title: L("build"), value: "1.0.0 (1)")
                AppInfoRow(title: L("release_date"), value: "September 2024")
            }
        }
        .padding(16)
    }
}

struct AppInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .themedSecondaryTextColor()

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .themedTextColor()
        }
    }
}

// MARK: - Additional Views

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon and info
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard.and.123")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)

                        VStack(spacing: 4) {
                            Text(L("expense_tracker"))
                                .font(.title)
                                .fontWeight(.bold)
                                .themedTextColor()

                            Text(L("version") + " 1.0.0")
                                .font(.subheadline)
                                .themedSecondaryTextColor()
                        }
                    }

                    // Description
                    Text(L("app_description"))
                        .font(.body)
                        .themedTextColor()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L("key_features"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .themedTextColor()

                        FeatureRow(icon: "chart.pie.fill", text: L("comprehensive_analytics"))
                        FeatureRow(icon: "folder.fill", text: L("category_management"))
                        FeatureRow(icon: "target", text: L("financial_planning"))
                        FeatureRow(icon: "repeat.circle", text: L("recurring_expenses"))
                        FeatureRow(icon: "bell.fill", text: L("smart_notifications"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Credits
                    VStack(spacing: 8) {
                        Text(L("developed_by"))
                            .font(.caption)
                            .themedSecondaryTextColor()

                        Text("Akinalp Fidan")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .themedTextColor()
                    }

                    Spacer(minLength: 50)
                }
                .padding()
            }
            .themedBackground()
            .navigationTitle(L("about"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .themedTextColor()

            Spacer()
        }
    }
}

struct ExportDataView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text(L("export_data"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .themedTextColor()

                VStack(spacing: 16) {
                    ExportOptionButton(
                        title: L("export_csv"),
                        description: L("spreadsheet_format"),
                        icon: "tablecells"
                    ) {
                        // Export CSV logic
                    }

                    ExportOptionButton(
                        title: L("export_json"),
                        description: L("backup_format"),
                        icon: "doc.text"
                    ) {
                        // Export JSON logic
                    }

                    ExportOptionButton(
                        title: L("share_summary"),
                        description: L("quick_overview"),
                        icon: "square.and.arrow.up"
                    ) {
                        // Share summary logic
                    }
                }

                Spacer()
            }
            .padding()
            .themedBackground()
            .navigationBarHidden(true)
        }
    }
}

struct ExportOptionButton: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .themedTextColor()
                    .frame(width: 44, height: 44)
                    .themedCardBackground()
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .themedTextColor()

                    Text(description)
                        .font(.subheadline)
                        .themedSecondaryTextColor()
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .themedSecondaryTextColor()
            }
            .padding(16)
            .themedCardBackground()
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SettingsManager.preview)
            .environmentObject(AppTheme.shared)
            .environmentObject(ExpenseViewModel.preview)
            .environmentObject(CategoryRepository())
            .preferredColorScheme(.dark)
    }
}
#endif