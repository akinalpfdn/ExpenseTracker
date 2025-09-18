//
//  DateRangePicker.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI

struct DateRangePicker: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isPresented: Bool

    @State private var tempStartDate: Date
    @State private var tempEndDate: Date
    @State private var selectedPreset: DateRangePreset = .custom
    @State private var showingStartPicker = false
    @State private var showingEndPicker = false

    private let maxDateRange: TimeInterval = 365 * 24 * 60 * 60 // 1 year

    init(startDate: Binding<Date>, endDate: Binding<Date>, isPresented: Binding<Bool>) {
        self._startDate = startDate
        self._endDate = endDate
        self._isPresented = isPresented
        self._tempStartDate = State(initialValue: startDate.wrappedValue)
        self._tempEndDate = State(initialValue: endDate.wrappedValue)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView

                ScrollView {
                    VStack(spacing: 20) {
                        presetsSection
                        customDateSection
                        validationSection
                    }
                    .padding()
                }
            }
            .background(ThemeColors.backgroundColor(for: colorScheme))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingStartPicker) {
                startDatePickerView
            }
            .sheet(isPresented: $showingEndPicker) {
                endDatePickerView
            }
            .onChange(of: selectedPreset) { preset in
                applyPreset(preset)
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(L("cancel")) {
                    isPresented = false
                }
                .font(AppTypography.buttonText)
                .foregroundColor(AppColors.primaryRed)

                Spacer()

                Text(L("select_date_range"))
                    .font(AppTypography.navigationTitle)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Spacer()

                Button(L("apply")) {
                    applySelection()
                }
                .font(AppTypography.buttonText)
                .foregroundColor(isValidRange ? AppColors.primaryOrange : ThemeColors.textGrayColor(for: colorScheme))
                .disabled(!isValidRange)
            }
            .padding()

            Divider()
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme).opacity(0.3))
        }
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("quick_select"))
                .font(AppTypography.cardTitle)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(DateRangePreset.allCases, id: \.self) { preset in
                    if preset != .custom {
                        presetButton(preset)
                    }
                }
            }
        }
    }

    private func presetButton(_ preset: DateRangePreset) -> some View {
        Button(action: {
            selectedPreset = preset
        }) {
            HStack {
                Image(systemName: preset.iconName)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(selectedPreset == preset ? .white : AppColors.primaryOrange)

                Text(preset.displayName)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(selectedPreset == preset ? .white : ThemeColors.textColor(for: colorScheme))

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedPreset == preset ?
                          AppColors.primaryOrange :
                          ThemeColors.cardBackgroundColor(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedPreset == preset ?
                                AppColors.primaryOrange :
                                ThemeColors.textGrayColor(for: colorScheme).opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var customDateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("custom_range"))
                .font(AppTypography.cardTitle)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            VStack(spacing: 12) {
                dateSelectionRow(
                    title: L("start_date"),
                    date: tempStartDate,
                    isStartDate: true
                ) {
                    showingStartPicker = true
                }

                dateSelectionRow(
                    title: L("end_date"),
                    date: tempEndDate,
                    isStartDate: false
                ) {
                    showingEndPicker = true
                }
            }
            .padding()
            .background(ThemeColors.cardBackgroundColor(for: colorScheme))
            .cornerRadius(12)
        }
    }

    private func dateSelectionRow(
        title: String,
        date: Date,
        isStartDate: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.labelMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Text(formatDate(date))
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                }

                Spacer()

                Image(systemName: "calendar")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.primaryOrange)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var validationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !isValidRange {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.primaryRed)

                    Text(validationMessage)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.primaryRed)
                }
                .padding()
                .background(AppColors.primaryRed.opacity(0.1))
                .cornerRadius(8)
            }

            rangeInfoView
        }
    }

    private var rangeInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.primaryOrange)

                Text(L("range_info"))
                    .font(AppTypography.labelMedium)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(L("duration"))
                        .font(AppTypography.labelMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Spacer()

                    Text(formatDuration())
                        .font(AppTypography.labelMedium)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                }

                HStack {
                    Text(L("span"))
                        .font(AppTypography.labelMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Spacer()

                    Text(formatSpan())
                        .font(AppTypography.labelMedium)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                }
            }
        }
        .padding()
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(8)
    }

    private var startDatePickerView: some View {
        NavigationView {
            VStack {
                DatePicker(
                    L("start_date"),
                    selection: $tempStartDate,
                    in: ...tempEndDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .padding()

                Spacer()
            }
            .navigationTitle(L("select_start_date"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("cancel")) {
                        showingStartPicker = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        selectedPreset = .custom
                        showingStartPicker = false
                    }
                }
            }
        }
    }

    private var endDatePickerView: some View {
        NavigationView {
            VStack {
                DatePicker(
                    L("end_date"),
                    selection: $tempEndDate,
                    in: tempStartDate...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .padding()

                Spacer()
            }
            .navigationTitle(L("select_end_date"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("cancel")) {
                        showingEndPicker = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        selectedPreset = .custom
                        showingEndPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var isValidRange: Bool {
        tempStartDate <= tempEndDate &&
        tempEndDate.timeIntervalSince(tempStartDate) <= maxDateRange
    }

    private var validationMessage: String {
        if tempStartDate > tempEndDate {
            return L("error_start_date_after_end_date")
        } else if tempEndDate.timeIntervalSince(tempStartDate) > maxDateRange {
            return L("error_date_range_too_long")
        }
        return ""
    }

    // MARK: - Helper Functions

    private func applyPreset(_ preset: DateRangePreset) {
        let calendar = Calendar.current
        let now = Date()

        switch preset {
        case .today:
            tempStartDate = calendar.startOfDay(for: now)
            tempEndDate = calendar.date(byAdding: .day, value: 1, to: tempStartDate) ?? now

        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            tempStartDate = calendar.startOfDay(for: yesterday)
            tempEndDate = calendar.date(byAdding: .day, value: 1, to: tempStartDate) ?? now

        case .thisWeek:
            tempStartDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            tempEndDate = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now

        case .lastWeek:
            let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            tempStartDate = calendar.dateInterval(of: .weekOfYear, for: lastWeek)?.start ?? now
            tempEndDate = calendar.dateInterval(of: .weekOfYear, for: lastWeek)?.end ?? now

        case .thisMonth:
            tempStartDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
            tempEndDate = calendar.dateInterval(of: .month, for: now)?.end ?? now

        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            tempStartDate = calendar.dateInterval(of: .month, for: lastMonth)?.start ?? now
            tempEndDate = calendar.dateInterval(of: .month, for: lastMonth)?.end ?? now

        case .last30Days:
            tempEndDate = now
            tempStartDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now

        case .last90Days:
            tempEndDate = now
            tempStartDate = calendar.date(byAdding: .day, value: -90, to: now) ?? now

        case .thisYear:
            tempStartDate = calendar.dateInterval(of: .year, for: now)?.start ?? now
            tempEndDate = calendar.dateInterval(of: .year, for: now)?.end ?? now

        case .lastYear:
            let lastYear = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            tempStartDate = calendar.dateInterval(of: .year, for: lastYear)?.start ?? now
            tempEndDate = calendar.dateInterval(of: .year, for: lastYear)?.end ?? now

        case .custom:
            break // Keep current dates
        }
    }

    private func applySelection() {
        startDate = tempStartDate
        endDate = tempEndDate
        isPresented = false
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d, yyyy")
        return formatter.string(from: date)
    }

    private func formatDuration() -> String {
        let duration = tempEndDate.timeIntervalSince(tempStartDate)
        let days = Int(duration / (24 * 60 * 60))

        if days == 0 {
            return L("same_day")
        } else if days == 1 {
            return L("1_day")
        } else {
            return L("n_days", days)
        }
    }

    private func formatSpan() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMM d")

        let startString = formatter.string(from: tempStartDate)
        let endString = formatter.string(from: tempEndDate)

        return "\(startString) - \(endString)"
    }
}

// MARK: - Supporting Types

enum DateRangePreset: String, CaseIterable {
    case today = "today"
    case yesterday = "yesterday"
    case thisWeek = "thisWeek"
    case lastWeek = "lastWeek"
    case thisMonth = "thisMonth"
    case lastMonth = "lastMonth"
    case last30Days = "last30Days"
    case last90Days = "last90Days"
    case thisYear = "thisYear"
    case lastYear = "lastYear"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .today:
            return L("today")
        case .yesterday:
            return L("yesterday")
        case .thisWeek:
            return L("this_week")
        case .lastWeek:
            return L("last_week")
        case .thisMonth:
            return L("this_month")
        case .lastMonth:
            return L("last_month")
        case .last30Days:
            return L("last_30_days")
        case .last90Days:
            return L("last_90_days")
        case .thisYear:
            return L("this_year")
        case .lastYear:
            return L("last_year")
        case .custom:
            return L("custom")
        }
    }

    var iconName: String {
        switch self {
        case .today:
            return "calendar.circle"
        case .yesterday:
            return "calendar.badge.minus"
        case .thisWeek:
            return "calendar.badge.clock"
        case .lastWeek:
            return "calendar.badge.clock"
        case .thisMonth:
            return "calendar.circle.fill"
        case .lastMonth:
            return "calendar.circle.fill"
        case .last30Days:
            return "calendar.badge.plus"
        case .last90Days:
            return "calendar.badge.plus"
        case .thisYear:
            return "calendar"
        case .lastYear:
            return "calendar"
        case .custom:
            return "calendar.badge.gear"
        }
    }
}

// MARK: - DateRangeButton

struct DateRangeButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let startDate: Date
    let endDate: Date
    let onTap: () -> Void

    private var isToday: Bool {
        Calendar.current.isDateInToday(startDate) && Calendar.current.isDateInToday(endDate)
    }

    private var displayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current

        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            formatter.setLocalizedDateFormatFromTemplate("MMM d, yyyy")
            return formatter.string(from: startDate)
        } else {
            formatter.setLocalizedDateFormatFromTemplate("MMM d")
            let startString = formatter.string(from: startDate)
            let endString = formatter.string(from: endDate)
            return "\(startString) - \(endString)"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.primaryOrange)

                Text(displayText)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Image(systemName: "chevron.down")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(ThemeColors.cardBackgroundColor(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isToday ? AppColors.primaryOrange.opacity(0.5) : ThemeColors.textGrayColor(for: colorScheme).opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct DateRangePicker_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
            @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            @State private var endDate = Date()
            @State private var showingPicker = true

            var body: some View {
                VStack {
                    DateRangeButton(
                        startDate: startDate,
                        endDate: endDate
                    ) {
                        showingPicker = true
                    }
                    .padding()

                    Spacer()
                }
                .sheet(isPresented: $showingPicker) {
                    DateRangePicker(
                        startDate: $startDate,
                        endDate: $endDate,
                        isPresented: $showingPicker
                    )
                }
            }
        }

        return PreviewWrapper()
    }
}
#endif