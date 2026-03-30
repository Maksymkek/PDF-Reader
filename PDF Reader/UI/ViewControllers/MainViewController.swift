//
//  MainViewController.swift
//  PDF Reader
//
//  Created by Максим Грищенков on 19.02.2026.
//
import UIKit
import UniformTypeIdentifiers

final class MainViewController: UIViewController, UIDocumentPickerDelegate {
    private var hasOpenedPicker = false
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !hasOpenedPicker else { return }
        hasOpenedPicker = true
        openPicker()
    }
    
    private func openPicker() {
        
        let types: [UTType] = [.data, .content]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        picker.modalPresentationStyle = .fullScreen
        if let root = view.window?.rootViewController {
            root.present(picker, animated: true)
        } else {
            present(picker, animated: true)
        }
    }
}
