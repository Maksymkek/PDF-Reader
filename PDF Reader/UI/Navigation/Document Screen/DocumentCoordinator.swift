//
//  MainCoordinator.swift
//  PDF Reader
//
//  Created by Максим Грищенков on 19.02.2026.
//
import UIKit

final class DocumentCoordinator {

    private let navigationController: UIDocumentBrowserViewController
    private let factory: DocumentFactory
    private var transitionController: UIDocumentBrowserTransitionController?
    private var transitionDelegate: DocumentBrowserTransitioningDelegate?

    init(
        navigationController: UIDocumentBrowserViewController,
        factory: DocumentFactory
    ) {

        self.navigationController = navigationController
        self.factory = factory
    }

    func start(_ documentURL: URL) {
        showScreen(documentURL)
    }

    private func showScreen(_ documentURL: URL) {
        let vc = factory.makeDocumentScreen(
            for: documentURL,
        )
        vc.loadViewIfNeeded()
        let transitionController = navigationController.transitionController(
            forDocumentAt: documentURL,
        )
        vc.transitionController = transitionController
        transitionController.targetView = vc.view
        let navController = UINavigationController(rootViewController: vc)
        let transitionDelegate = DocumentBrowserTransitioningDelegate(
            transitionController: transitionController
        )
        navController.transitioningDelegate = transitionDelegate
        navController.modalPresentationStyle = .custom
        self.transitionController = transitionController
        self.transitionDelegate = transitionDelegate
        navigationController.present(navController, animated: true)
    }

}

private final class DocumentBrowserTransitioningDelegate: NSObject,
    UIViewControllerTransitioningDelegate
{
    private let transitionController: UIDocumentBrowserTransitionController

    init(transitionController: UIDocumentBrowserTransitionController) {
        self.transitionController = transitionController
        super.init()
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        transitionController
    }

    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning?
    {
        transitionController
    }
}
