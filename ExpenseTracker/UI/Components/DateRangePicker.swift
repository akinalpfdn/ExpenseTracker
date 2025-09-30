//
//  DateRangePicker.swift
//  ExpenseTracker
//
//  Created by migration from Android DateRangePicker.kt
//

import SwiftUI

struct DateRange: Equatable {
    let startDate: Date
    let endDate: Date

    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

struct DateRangePicker: View {
    @Binding var selectedRange: DateRange?
    let onRangeSelected: (DateRange) -> Void
    let isDarkTheme: Bool

    @State private var showingStartPicker = false
    @State private var showingEndPicker = false
    @State private var tempStartDate = Date()
    @State private var tempEndDate = Date()
    @State private var isSelectingRange = false

    init(
        selectedRange: Binding<DateRange?>,
        onRangeSelected: @escaping (DateRange) -> Void = { _ in },
        isDarkTheme: Bool = true
    ) {
        self._selectedRange = selectedRange
        self.onRangeSelected = onRangeSelected
        self.isDarkTheme = isDarkTheme
    }

    var body: some View {
        VStack(spacing: 16) {
            headerSection
            dateSelectionSection
            actionButtons
        }
        .padding(16)
        .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(16)
        .onAppear {
            setupInitialDates()
        }
    }
}

// MARK: - View Components
extension DateRangePicker {
    private var headerSection: some View {
        HStack {
            Text("select_date_range".localized)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Spacer()

            if selectedRange != nil {
                Button(action: clearSelection) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
            }
        }
    }

    private var dateSelectionSection: some View {
        VStack(spacing: 12) {
            startDateSection
            endDateSection
        }
    }

    private var startDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("start_date".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Button(action: { showingStartPicker = true }) {
                HStack {
                    Text(formattedDate(tempStartDate))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                    Spacer()

                    Image(systemName: "calendar")
                        .foregroundColor(AppColors.primaryOrange)
                }
                .padding(12)
                .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showingStartPicker) {
            startDatePickerSheet
        }
    }

    private var endDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("end_date".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Button(action: { showingEndPicker = true }) {
                HStack {
                    Text(formattedDate(tempEndDate))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                    Spacer()

                    Image(systemName: "calendar")
                        .foregroundColor(AppColors.primaryOrange)
                }
                .padding(12)
                .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showingEndPicker) {
            endDatePickerSheet
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: clearSelection) {
                Text("clear".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 1)
                    )
                    .cornerRadius(12)
            }

            Button(action: applyDateRange) {
                Text("apply".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(AppColors.primaryOrange)
                    .cornerRadius(12)
            }
            .disabled(!isValidDateRange)
        }
    }

    private var startDatePickerSheet: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "start_date".localized,
                    selection: $tempStartDate,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()

                Spacer()
            }
            .navigationTitle("select_start_date".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("cancel".localized) {
                    showingStartPicker = false
                },
                trailing: Button("done".localized) {
                    showingStartPicker = false
                    validateAndAdjustDates()
                }
            )
        }
    }

    private var endDatePickerSheet: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "end_date".localized,
                    selection: $tempEndDate,
                    in: tempStartDate...,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()

                Spacer()
            }
            .navigationTitle("select_end_date".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("cancel".localized) {
                    showingEndPicker = false
                },
                trailing: Button("done".localized) {
                    showingEndPicker = false
                    validateAndAdjustDates()
                }
            )
        }
    }
}

// MARK: - Computed Properties
extension DateRangePicker {
    private var isValidDateRange: Bool {
        tempStartDate <= tempEndDate
    }

    private var selectedRangeText: String {
        guard let range = selectedRange else { return "" }
        return "\(formattedDate(range.startDate)) - \(formattedDate(range.endDate))"
    }
}

// MARK: - Helper Methods
extension DateRangePicker {
    private func setupInitialDates() {
        if let range = selectedRange {
            tempStartDate = range.startDate
            tempEndDate = range.endDate
        } else {
            let calendar = Calendar.current
            tempStartDate = calendar.startOfDay(for: Date())
            tempEndDate = calendar.startOfDay(for: Date())
        }
    }

    private func validateAndAdjustDates() {
        if tempStartDate > tempEndDate {
            tempEndDate = tempStartDate
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    private func clearSelection() {
        selectedRange = nil
        setupInitialDates()
    }

    private func applyDateRange() {
        guard isValidDateRange else { return }

        let range = DateRange(startDate: tempStartDate, endDate: tempEndDate)
        selectedRange = range
        onRangeSelected(range)
    }
}

// MARK: - Quick Selection Options
extension DateRangePicker {
    private var quickSelectionOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("quick_select".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                quickSelectButton("today".localized) { selectToday() }
                quickSelectButton("yesterday".localized) { selectYesterday() }
                quickSelectButton("this_week".localized) { selectThisWeek() }
                quickSelectButton("last_week".localized) { selectLastWeek() }
                quickSelectButton("this_month".localized) { selectThisMonth() }
                quickSelectButton("last_month".localized) { selectLastMonth() }
            }
        }
    }

    private func quickSelectButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 0.5)
                )
        }
    }

    private func selectToday() {
        let today = Calendar.current.startOfDay(for: Date())
        tempStartDate = today
        tempEndDate = today
    }

    private func selectYesterday() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayStart = calendar.startOfDay(for: yesterday)
        tempStartDate = yesterdayStart
        tempEndDate = yesterdayStart
    }

    private func selectThisWeek() {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        tempStartDate = startOfWeek
        tempEndDate = calendar.date(byAdding: .second, value: -1, to: endOfWeek) ?? endOfWeek
    }

    private func selectLastWeek() {
        let calendar = Calendar.current
        let now = Date()
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        let startOfLastWeek = calendar.dateInterval(of: .weekOfYear, for: lastWeek)?.start ?? lastWeek
        let endOfLastWeek = calendar.dateInterval(of: .weekOfYear, for: lastWeek)?.end ?? lastWeek
        tempStartDate = startOfLastWeek
        tempEndDate = calendar.date(byAdding: .second, value: -1, to: endOfLastWeek) ?? endOfLastWeek
    }

    private func selectThisMonth() {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        tempStartDate = startOfMonth
        tempEndDate = calendar.date(byAdding: .second, value: -1, to: endOfMonth) ?? endOfMonth
    }

    private func selectLastMonth() {
        let calendar = Calendar.current
        let now = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.start ?? lastMonth
        let endOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.end ?? lastMonth
        tempStartDate = startOfLastMonth
        tempEndDate = calendar.date(byAdding: .second, value: -1, to: endOfLastMonth) ?? endOfLastMonth
    }
}

// MARK: - Preview
struct DateRangePicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            DateRangePicker(
                selectedRange: .constant(nil),
                isDarkTheme: true
            )

            DateRangePicker(
                selectedRange: .constant(DateRange(
                    startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                    endDate: Date()
                )),
                isDarkTheme: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
