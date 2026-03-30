//
//  AppCoordinator.swift
//  PDF Reader
//
//  Created by Максим Грищенков on 18.02.2026.
//
import UIKit

final class AppCoordinator {

    private let window: UIWindow
    private let navigationController: UIDocumentBrowserViewController
    private let mainFactory: DocumentFactory
    private var documentCoordinator: DocumentCoordinator?

    init(window: UIWindow,
         navigationController: UIDocumentBrowserViewController,
         mainFactory: DocumentFactory) {

        self.window = window
        self.navigationController = navigationController
        self.mainFactory = mainFactory
    }

    func start() {
        window.rootViewController = navigationController
    }

    func showDocumentScreen(documentURL: URL){
        let coordinator = DocumentCoordinator(
            navigationController: navigationController,
            factory: mainFactory
        )
        documentCoordinator = coordinator
        coordinator.start(documentURL)
    }
}
