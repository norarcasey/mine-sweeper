import SwiftUI
import UIKit

/// Reports the window scene's interface orientation, now and as it changes.
/// The size classes say the phone is on its side but not which way round;
/// this says which, so the controls can follow the phone's top edge.
struct InterfaceOrientationReader: UIViewRepresentable {
    let onChange: @MainActor (UIInterfaceOrientation) -> Void

    func makeUIView(context: Context) -> ReaderView {
        let view = ReaderView()
        view.onChange = onChange
        return view
    }

    func updateUIView(_ view: ReaderView, context: Context) {
        view.onChange = onChange
    }

    final class ReaderView: UIView {
        var onChange: (@MainActor (UIInterfaceOrientation) -> Void)?
        private var observation: NSKeyValueObservation?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            // A turn from one side straight to the other changes no size, so
            // SwiftUI redraws nothing for it; the scene's geometry does change.
            observation = window?.windowScene?.observe(\.effectiveGeometry, options: [.initial]) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.report() }
            }
        }

        private func report() {
            guard let scene = window?.windowScene else { return }
            onChange?(scene.effectiveGeometry.interfaceOrientation)
        }
    }
}
