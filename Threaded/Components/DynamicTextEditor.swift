//Made by Lumaa

import SwiftUI
import UIKit

/// A SwiftUI TextView implementation that supports both scrolling and auto-sizing layouts
public struct DynamicTextEditor: View {
    @Environment(\.layoutDirection) private var layoutDirection
    
    @Binding private var text: NSMutableAttributedString
    @Binding private var isEmpty: Bool
    
    @State private var calculatedHeight: CGFloat = 44
    
    private var getTextView: ((UITextView) -> Void)?
    private var onFocusAction: (() -> Void) = {}
    private var onDimissAction: (() -> Void) = {}
    
    var placeholderView: AnyView?
    var placeholderText: String?
    var keyboard: UIKeyboardType = .default
    
    /// Makes a new TextView that supports `NSAttributedString`
    /// - Parameters:
    ///   - text: A binding to the attributed text
    public init(_ text: Binding<NSMutableAttributedString>,
                getTextView: ((UITextView) -> Void)? = nil)
    {
        _text = text
        _isEmpty = Binding(
            get: { text.wrappedValue.length <= 0 || text.wrappedValue.string.isEmpty },
            set: { _ in }
        )
        
        self.getTextView = getTextView
    }
    
    public var body: some View {
        Representable(
            text: $text,
            calculatedHeight: $calculatedHeight,
            keyboard: keyboard,
            getTextView: getTextView,
            onFocus: onFocusAction,
            onDismiss: onDimissAction
        )
        .frame(
            minHeight: calculatedHeight,
            maxHeight: calculatedHeight
        )
        .accessibilityValue($text.wrappedValue.string.isEmpty ? (placeholderText ?? "") : $text.wrappedValue.string)
        .background(
            placeholderView?
                .foregroundColor(Color(.placeholderText))
                .multilineTextAlignment(.leading)
                .font(.callout)
                .padding(.horizontal, 0)
                .padding(.vertical, 0)
                .opacity(isEmpty ? 1 : 0)
                .accessibilityHidden(true),
            alignment: .topLeading
        )
    }
}

final class UIKitTextView: UITextView {
    override var keyCommands: [UIKeyCommand]? {
        (super.keyCommands ?? []) + [
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(escape(_:))),
        ]
    }
    
    @objc private func escape(_: Any) {
        resignFirstResponder()
    }
}

public extension DynamicTextEditor {
    /// Specify a placeholder text
    /// - Parameter placeholder: The placeholder text
    func placeholder(_ placeholder: String) -> DynamicTextEditor {
        self.placeholder(placeholder) { $0 }
    }
    
    /// Specify a placeholder with the specified configuration
    ///
    /// Example:
    ///
    ///     TextView($text)
    ///         .placeholder("placeholder") { view in
    ///             view.foregroundColor(.red)
    ///         }
    func placeholder(_ placeholder: String, _ configure: (Text) -> some View) -> DynamicTextEditor {
        var view = self
        let text = Text(placeholder)
        view.placeholderView = AnyView(configure(text))
        view.placeholderText = placeholder
        return view
    }
    
    /// Specify a custom placeholder view
    func placeholder(_ placeholder: some View) -> DynamicTextEditor {
        var view = self
        view.placeholderView = AnyView(placeholder)
        return view
    }
    
    func setKeyboardType(_ keyboardType: UIKeyboardType) -> DynamicTextEditor {
        var view = self
        view.keyboard = keyboardType
        return view
    }
    
    func onFocus(_ action: @escaping () -> Void) -> DynamicTextEditor {
        var view = self
        view.onFocusAction = action
        return view
    }
    
    func onDismiss(_ action: @escaping () -> Void) -> DynamicTextEditor {
        var view = self
        view.onDimissAction = action
        return view
    }
}

extension DynamicTextEditor {
    struct Representable: UIViewRepresentable {
        @Binding var text: NSMutableAttributedString
        @Binding var calculatedHeight: CGFloat
        @Environment(\.sizeCategory) var sizeCategory
        
        let keyboard: UIKeyboardType
        var getTextView: ((UITextView) -> Void)?
        var onFocus: (() -> Void)
        var onDismiss: (() -> Void)
        
        func makeUIView(context: Context) -> UIKitTextView {
            context.coordinator.textView
        }
        
        func updateUIView(_: UIKitTextView, context: Context) {
            context.coordinator.update(representable: self)
            if !context.coordinator.didBecomeFirstResponder {
                context.coordinator.textView.becomeFirstResponder()
                context.coordinator.didBecomeFirstResponder = true
            }
        }
        
        @discardableResult func makeCoordinator() -> Coordinator {
            Coordinator(
                text: $text,
                calculatedHeight: $calculatedHeight,
                sizeCategory: sizeCategory,
                getTextView: getTextView,
                onFocus: onFocus,
                onDismiss: onDismiss
            )
        }
    }
}

extension DynamicTextEditor.Representable {
    final class Coordinator: NSObject, UITextViewDelegate {
        let textView: UIKitTextView
        
        private var originalText: NSMutableAttributedString = .init()
        private var text: Binding<NSMutableAttributedString>
        private var sizeCategory: ContentSizeCategory
        private var calculatedHeight: Binding<CGFloat>
        
        var didBecomeFirstResponder = false
        
        var getTextView: ((UITextView) -> Void)?
        var onFocus: (() -> Void)
        var onDismiss: (() -> Void)
        
        init(text: Binding<NSMutableAttributedString>,
             calculatedHeight: Binding<CGFloat>,
             sizeCategory: ContentSizeCategory,
             getTextView: ((UITextView) -> Void)?,
             onFocus: @escaping (() -> Void),
             onDismiss: @escaping (() -> Void))
        {
            textView = UIKitTextView()
            textView.backgroundColor = .clear
            textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            textView.isScrollEnabled = false
            textView.textContainer.lineFragmentPadding = 0
            textView.textContainerInset = .zero
            
            self.text = text
            self.calculatedHeight = calculatedHeight
            self.sizeCategory = sizeCategory
            self.getTextView = getTextView
            self.onFocus = onFocus
            self.onDismiss = onDismiss
            
            super.init()
            
            textView.delegate = self
            
            textView.font = UIFont.preferredFont(forTextStyle: .callout)
            textView.adjustsFontForContentSizeCategory = true
            textView.autocapitalizationType = .sentences
            textView.autocorrectionType = .yes
            textView.isEditable = true
            textView.isSelectable = true
            textView.dataDetectorTypes = []
            textView.allowsEditingTextAttributes = false
            textView.returnKeyType = .default
            textView.allowsEditingTextAttributes = true

            
            self.getTextView?(textView)
        }
        
        func textViewDidBeginEditing(_: UITextView) {
            originalText = text.wrappedValue
            DispatchQueue.main.async {
                self.recalculateHeight()
            }
            _ = onFocus()
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            _ = onDismiss()
        }
        
        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.text.wrappedValue = NSMutableAttributedString(attributedString: textView.attributedText)
                self.recalculateHeight()
            }
        }
        
        func textView(_: UITextView, shouldChangeTextIn _: NSRange, replacementText _: String) -> Bool {
            true
        }
    }
}

extension DynamicTextEditor.Representable.Coordinator {
    func update(representable: DynamicTextEditor.Representable) {
        textView.keyboardType = representable.keyboard
        recalculateHeight()
        textView.setNeedsDisplay()
    }
    
    private func recalculateHeight() {
        let newSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
        guard calculatedHeight.wrappedValue != newSize.height else { return }
        
        DispatchQueue.main.async { // call in next render cycle.
            self.calculatedHeight.wrappedValue = newSize.height
        }
    }
}
