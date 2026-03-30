//
//  AppFactory.swift
//  PDF Reader
//
//  Created by Максим Грищенков on 18.02.2026.
//
import UIKit
import UniformTypeIdentifiers

final class AppFactory {

    func makeAppCoordinator(window: UIWindow, documentBrowser: UIDocumentBrowserViewController) -> AppCoordinator {
        let mainFactory = DocumentFactory()
        
        return AppCoordinator(
            window: window,
            navigationController: documentBrowser,
            mainFactory: mainFactory
        )
    }
    
    func makePDFReadingProgressStore() -> PDFReadingProgressStore {
        PDFReadingProgressStore()
    }
}
