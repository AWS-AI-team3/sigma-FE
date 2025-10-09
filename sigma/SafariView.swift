//
//  SafariView.swift
//  sigma
//
//  Created by ashcircle on 10/9/25.
//

import SwiftUI
import SafariServices

/// A SwiftUI wrapper for `SFSafariViewController` to present web content in-app.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let controller = SFSafariViewController(url: url, configuration: config)
        // Customize appearance if desired
        controller.preferredControlTintColor = .label
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // SFSafariViewController doesn't support changing the URL after initialization.
        // If the URL needs to change, present a new instance instead.
    }
}
