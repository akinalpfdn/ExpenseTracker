//
//  AddExpenseView.swift
//  ExpenseTracker
//
//  Updated with comprehensive form, validation, and new architecture integration
//

import SwiftUI
import Foundation

struct AddExpenseView: View {
    // MARK: - Environment Objects

    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var appTheme: AppTheme

    // MARK: - State

    @Environment(\.dismiss) var dismiss
    @State private var currentStep: FormStep = .basicInfo
    @State private var showingCategoryPicker = false
    @State private var showingSubCategoryPicker = false
    @State private var showingDatePicker = false
    @State private var showingImagePicker = false
    @State private var showingLocationPicker = false

    // Form validation
    @State private var isFormValid = false
    @State private var validationErrors: [String] = []

    // Animation state
    @State private var keyboardHeight: CGFloat = 0
    @State private var isAnimating = false

    // Form steps
    enum FormStep: Int, CaseIterable {
        case basicInfo = 0
        case details = 1
        case recurring = 2
        case review = 3

        var title: String {
            switch self {
            case .basicInfo:
                return L("basic_information")
            case .details:
                return L("additional_details")
            case .recurring:
                return L("recurring_settings")
            case .review:
                return L("review_expense")
            }
        }

        var stepNumber: Int { rawValue + 1 }
        var totalSteps: Int { FormStep.allCases.count }
    }
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.themedBackground(appTheme.colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Header
                    headerSection

                    // MARK: - Progress Indicator
                    progressIndicator

                    // MARK: - Form Content
                    ScrollView {
                        VStack(spacing: 24) {
                            switch currentStep {
                            case .basicInfo:
                                basicInfoStep
                            case .details:
                                detailsStep
                            case .recurring:
                                recurringStep
                            case .review:
                                reviewStep
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100) // Account for bottom buttons
                    }

                    Spacer()

                    // MARK: - Bottom Actions
                    bottomActionsSection
                }
                .offset(y: -keyboardHeight/2)
                .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
            }
            .navigationBarHidden(true)
            .themedBackground()
            .onAppear {
                setupForm()
                listenForKeyboardChanges()
            }
            .onChange(of: expenseViewModel.newExpenseForm.amount) { _ in
                validateForm()
            }
            .onChange(of: expenseViewModel.newExpenseForm.description) { _ in
                validateForm()
            }
            .onChange(of: expenseViewModel.newExpenseForm.categoryId) { _ in
                validateForm()
            }
            .alert(L("error"), isPresented: $expenseViewModel.showingErrorAlert) {
                Button(L("ok")) {
                    expenseViewModel.showingErrorAlert = false
                }
            } message: {
                Text(expenseViewModel.errorMessage ?? L("unknown_error"))
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .themedTextColor()
                }

                Spacer()

                Text(currentStep.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .themedTextColor()

                Spacer()

                Button(action: { resetForm() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .themedTextColor()
                }
            }

            Text(L("step_count", currentStep.stepNumber, currentStep.totalSteps))
                .font(.caption)
                .themedSecondaryTextColor()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack(spacing: 8) {
            // Step indicators
            HStack(spacing: 8) {
                ForEach(FormStep.allCases, id: \.rawValue) { step in
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? .orange : .gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(step == currentStep ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: currentStep)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .frame(height: 2)

                    Rectangle()
                        .fill(.orange)
                        .frame(width: geometry.size.width * progressPercentage, height: 2)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .frame(height: 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Form Steps

    private var basicInfoStep: some View {
        VStack(spacing: 20) {
            // Amount input
            VStack(alignment: .leading, spacing: 8) {
                Text(L("amount"))
                    .font(.headline)
                    .themedTextColor()

                HStack(spacing: 12) {
                    TextField(L("amount_placeholder"), value: $expenseViewModel.newExpenseForm.amount, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .themedTextColor()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .themedInputBackground()
                        .cornerRadius(12)

                    // Currency picker
                    Menu {
                        ForEach(settingsManager.getAvailableCurrencies(), id: \.self) { currency in
                            Button(currency) {
                                expenseViewModel.newExpenseForm.currency = currency
                            }
                        }
                    } label: {
                        Text(expenseViewModel.newExpenseForm.currency)
                            .font(.system(size: 18, weight: .semibold))
                            .themedTextColor()
                            .frame(width: 60, height: 56)
                            .themedCardBackground()
                            .cornerRadius(12)
                    }
                }
            }

            // Description input
            VStack(alignment: .leading, spacing: 8) {
                Text(L("description"))
                    .font(.headline)
                    .themedTextColor()

                TextField(L("description_placeholder"), text: $expenseViewModel.newExpenseForm.description)
                    .themedTextColor()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .themedInputBackground()
                    .cornerRadius(12)
            }

            // Category selection
            VStack(alignment: .leading, spacing: 8) {
                Text(L("category"))
                    .font(.headline)
                    .themedTextColor()

                Button(action: { showingCategoryPicker = true }) {
                    HStack {
                        Text(selectedCategoryName)
                            .themedTextColor()
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .themedSecondaryTextColor()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .themedCardBackground()
                    .cornerRadius(12)
                }
            }

            // Subcategory selection
            if !expenseViewModel.newExpenseForm.categoryId.isEmpty && !expenseViewModel.availableSubCategories.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("subcategory"))
                        .font(.headline)
                        .themedTextColor()

                    Button(action: { showingSubCategoryPicker = true }) {
                        HStack {
                            Text(selectedSubCategoryName)
                                .themedTextColor()
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .themedSecondaryTextColor()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .themedCardBackground()
                        .cornerRadius(12)
                    }
                }
            }

            // Date selection
            VStack(alignment: .leading, spacing: 8) {
                Text(L("date"))
                    .font(.headline)
                    .themedTextColor()

                DatePicker(
                    L("expense_date"),
                    selection: $expenseViewModel.newExpenseForm.date,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .themedTextColor()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .themedCardBackground()
                .cornerRadius(12)
            }
        }
    }

    private var detailsStep: some View {
        VStack(spacing: 20) {
            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text(L("notes_optional"))
                    .font(.headline)
                    .themedTextColor()

                TextField(L("notes_placeholder"), text: $expenseViewModel.newExpenseForm.notes, axis: .vertical)
                    .lineLimit(3...6)
                    .themedTextColor()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .themedInputBackground()
                    .cornerRadius(12)
            }

            // Location
            VStack(alignment: .leading, spacing: 8) {
                Text(L("location_optional"))
                    .font(.headline)
                    .themedTextColor()

                HStack {
                    TextField(L("location_placeholder"), text: $expenseViewModel.newExpenseForm.location)
                        .themedTextColor()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .themedInputBackground()
                        .cornerRadius(12)

                    Button(action: { showingLocationPicker = true }) {
                        Image(systemName: "location")
                            .font(.title3)
                            .themedTextColor()
                            .frame(width: 56, height: 56)
                            .themedCardBackground()
                            .cornerRadius(12)
                    }
                }
            }

            // Tags
            VStack(alignment: .leading, spacing: 8) {
                Text(L("tags_optional"))
                    .font(.headline)
                    .themedTextColor()

                TagInputView(tags: $expenseViewModel.newExpenseForm.tags)
            }

            // Status
            VStack(alignment: .leading, spacing: 8) {
                Text(L("status"))
                    .font(.headline)
                    .themedTextColor()

                Picker(L("status"), selection: $expenseViewModel.newExpenseForm.status) {
                    ForEach(ExpenseStatus.allCases, id: \.rawValue) { status in
                        Label(status.displayName, systemImage: status.iconName)
                            .tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var recurringStep: some View {
        VStack(spacing: 20) {
            // Recurrence type
            VStack(alignment: .leading, spacing: 8) {
                Text(L("recurrence_type"))
                    .font(.headline)
                    .themedTextColor()

                Picker(L("recurrence_type"), selection: $expenseViewModel.newExpenseForm.recurrenceType) {
                    ForEach(RecurrenceType.allCases, id: \.rawValue) { type in
                        Label(type.displayName, systemImage: type.iconName)
                            .tag(type)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .themedCardBackground()
                .cornerRadius(12)
            }

            // End date (if recurring)
            if expenseViewModel.newExpenseForm.recurrenceType != .none {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("recurrence_end_date"))
                        .font(.headline)
                        .themedTextColor()

                    DatePicker(
                        L("recurrence_end_date"),
                        selection: Binding(
                            get: { expenseViewModel.newExpenseForm.recurrenceEndDate ?? Date() },
                            set: { expenseViewModel.newExpenseForm.recurrenceEndDate = $0 }
                        ),
                        in: expenseViewModel.newExpenseForm.date...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .themedTextColor()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .themedCardBackground()
                    .cornerRadius(12)
                }
            }

            // Custom interval (if custom recurrence)
            if expenseViewModel.newExpenseForm.recurrenceType == .custom {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("custom_interval_days"))
                        .font(.headline)
                        .themedTextColor()

                    TextField(L("days"), value: $expenseViewModel.newExpenseForm.customRecurrenceInterval, format: .number)
                        .keyboardType(.numberPad)
                        .themedTextColor()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .themedInputBackground()
                        .cornerRadius(12)
                }
            }
        }
    }

    private var reviewStep: some View {
        VStack(spacing: 24) {
            // Summary card
            VStack(spacing: 16) {
                // Amount display
                Text(formattedAmount)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)

                Text(expenseViewModel.newExpenseForm.description)
                    .font(.title3)
                    .fontWeight(.medium)
                    .themedTextColor()
                    .multilineTextAlignment(.center)

                // Details
                VStack(spacing: 12) {
                    ReviewRow(title: L("category"), value: selectedCategoryName)
                    if !selectedSubCategoryName.isEmpty {
                        ReviewRow(title: L("subcategory"), value: selectedSubCategoryName)
                    }
                    ReviewRow(title: L("date"), value: settingsManager.formatDate(expenseViewModel.newExpenseForm.date))
                    ReviewRow(title: L("status"), value: expenseViewModel.newExpenseForm.status.displayName)

                    if expenseViewModel.newExpenseForm.recurrenceType != .none {
                        ReviewRow(title: L("recurrence"), value: expenseViewModel.newExpenseForm.recurrenceType.displayName)
                    }

                    if !expenseViewModel.newExpenseForm.notes.isEmpty {
                        ReviewRow(title: L("notes"), value: expenseViewModel.newExpenseForm.notes)
                    }

                    if !expenseViewModel.newExpenseForm.location.isEmpty {
                        ReviewRow(title: L("location"), value: expenseViewModel.newExpenseForm.location)
                    }

                    if !expenseViewModel.newExpenseForm.tags.isEmpty {
                        ReviewRow(title: L("tags"), value: expenseViewModel.newExpenseForm.tags.joined(separator: ", "))
                    }
                }
            }
            .padding(20)
            .themedCardBackground()
            .cornerRadius(16)

            // Validation errors
            if !validationErrors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("validation_errors"))
                        .font(.headline)
                        .foregroundColor(.red)

                    ForEach(validationErrors, id: \.self) { error in
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
                .padding(16)
                .background(.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Bottom Actions

    private var bottomActionsSection: some View {
        VStack(spacing: 16) {
            // Action buttons
            HStack(spacing: 12) {
                if currentStep != .basicInfo {
                    Button(L("previous")) {
                        previousStep()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                }

                if currentStep != .review {
                    Button(L("next")) {
                        nextStep()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .disabled(!canProceedToNextStep())
                } else {
                    Button(expenseViewModel.isCreatingExpense ? L("saving") : L("save_expense")) {
                        saveExpense()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .disabled(!isFormValid || expenseViewModel.isCreatingExpense)
                }
            }

            // Cancel button
            Button(L("cancel")) {
                dismiss()
            }
            .font(.subheadline)
            .themedSecondaryTextColor()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34) // Account for safe area
        .themedCardBackground()
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }

    // MARK: - Helper Properties

    private var progressPercentage: Double {
        return Double(currentStep.rawValue + 1) / Double(FormStep.allCases.count)
    }

    private var selectedCategoryName: String {
        return expenseViewModel.availableCategories.first { $0.id == expenseViewModel.newExpenseForm.categoryId }?.name ?? L("select_category")
    }

    private var selectedSubCategoryName: String {
        return expenseViewModel.availableSubCategories.first { $0.id == expenseViewModel.newExpenseForm.subCategoryId }?.name ?? L("select_subcategory")
    }

    private var formattedAmount: String {
        return settingsManager.formatCurrency(expenseViewModel.newExpenseForm.amount)
    }

    // MARK: - Helper Methods

    private func setupForm() {
        expenseViewModel.prepareNewExpenseForm()
        validateForm()
    }

    private func resetForm() {
        expenseViewModel.newExpenseForm.reset()
        currentStep = .basicInfo
        validationErrors.removeAll()
        validateForm()
    }

    private func nextStep() {
        guard canProceedToNextStep() else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep.rawValue < FormStep.allCases.count - 1 {
                currentStep = FormStep(rawValue: currentStep.rawValue + 1) ?? currentStep
            }
        }

        settingsManager.triggerHapticFeedback(.light)
        validateForm()
    }

    private func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep.rawValue > 0 {
                currentStep = FormStep(rawValue: currentStep.rawValue - 1) ?? currentStep
            }
        }

        settingsManager.triggerHapticFeedback(.light)
    }

    private func canProceedToNextStep() -> Bool {
        switch currentStep {
        case .basicInfo:
            return expenseViewModel.newExpenseForm.amount > 0 &&
                   !expenseViewModel.newExpenseForm.description.isEmpty &&
                   !expenseViewModel.newExpenseForm.categoryId.isEmpty
        case .details:
            return true // Optional fields
        case .recurring:
            return expenseViewModel.newExpenseForm.recurrenceType == .none ||
                   expenseViewModel.newExpenseForm.recurrenceEndDate != nil
        case .review:
            return false // Final step
        }
    }

    private func validateForm() {
        validationErrors.removeAll()

        // Basic validation
        if expenseViewModel.newExpenseForm.amount <= 0 {
            validationErrors.append(L("error_invalid_amount"))
        }

        if expenseViewModel.newExpenseForm.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append(L("error_missing_description"))
        }

        if expenseViewModel.newExpenseForm.categoryId.isEmpty {
            validationErrors.append(L("error_missing_category"))
        }

        // Recurring validation
        if expenseViewModel.newExpenseForm.recurrenceType != .none {
            if let endDate = expenseViewModel.newExpenseForm.recurrenceEndDate,
               endDate <= expenseViewModel.newExpenseForm.date {
                validationErrors.append(L("error_invalid_recurrence_end_date"))
            }

            if expenseViewModel.newExpenseForm.recurrenceType == .custom &&
               expenseViewModel.newExpenseForm.customRecurrenceInterval <= 0 {
                validationErrors.append(L("error_invalid_custom_recurrence"))
            }
        }

        isFormValid = validationErrors.isEmpty
    }

    private func saveExpense() {
        validateForm()
        guard isFormValid else { return }

        Task {
            await expenseViewModel.createExpense()
            if !expenseViewModel.showingErrorAlert {
                dismiss()
            }
        }
    }

    private func listenForKeyboardChanges() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            keyboardHeight = 0
        }
    }
}

// MARK: - Supporting Views

struct ReviewRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .themedSecondaryTextColor()

            Spacer()

            Text(value)
                .font(.subheadline)
                .themedTextColor()
                .multilineTextAlignment(.trailing)
        }
    }
}

struct TagInputView: View {
    @Binding var tags: [String]
    @State private var newTag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Existing tags
            if !tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(text: tag) {
                            tags.removeAll { $0 == tag }
                        }
                    }
                }
            }

            // Add new tag
            HStack {
                TextField(L("add_tag"), text: $newTag)
                    .themedTextColor()
                    .onSubmit {
                        addTag()
                    }

                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.orange)
                }
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .themedInputBackground()
            .cornerRadius(12)
        }
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
            newTag = ""
        }
    }
}

struct TagChip: View {
    let text: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
                .foregroundColor(.orange)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.orange.opacity(0.2))
        .cornerRadius(12)
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.bounds
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }

    private struct FlowResult {
        var bounds = CGSize.zero
        var frames: [CGRect] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentPosition = CGPoint.zero
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)

                if currentPosition.x + subviewSize.width > maxWidth && currentPosition.x > 0 {
                    currentPosition.x = 0
                    currentPosition.y += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(origin: currentPosition, size: subviewSize))

                currentPosition.x += subviewSize.width + spacing
                lineHeight = max(lineHeight, subviewSize.height)
            }

            bounds = CGSize(width: maxWidth, height: currentPosition.y + lineHeight)
        }
    }
}

// MARK: - Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#if DEBUG
struct AddExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        AddExpenseView()
            .environmentObject(ExpenseViewModel.preview)
            .environmentObject(SettingsManager.preview)
            .environmentObject(AppTheme.shared)
            .preferredColorScheme(.dark)
    }
}
#endif
