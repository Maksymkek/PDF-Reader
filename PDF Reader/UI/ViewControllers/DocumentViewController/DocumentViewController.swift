//
//  DocumentViewController.swift
//  PDF Reader
//
//  Created by Максим Грищенков on 24.02.2026.
//

import PDFKit
import UIKit

final class DocumentViewController: UIViewController, UIGestureRecognizerDelegate
{
    var documentURL: URL?
    let pdfView = PDFView()
    private let thumbnailView = PDFThumbnailView()
    let documentViewModel: DocumentViewModel
    private let customThumbnailView = DocumentThumbnailView()
    var transitionController: UIDocumentBrowserTransitionController?
    private var didApplyInitialScale = false
    private var searchResults: [PDFSelection] = []
    private var currentSearchIndex = 0
   
    private lazy var searchView: DocumentSearchView = {
        return DocumentSearchView(vc: self)}()
    
    private lazy var closeButton = UIBarButtonItem(
        barButtonSystemItem: .close,
        target: self,
        action: #selector(dismissSelf)
    )

    private lazy var searchButton = UIBarButtonItem(
        image: UIImage(systemName: "magnifyingglass"),
        style: .plain,
        target: searchView.self,
        action: #selector(searchView.didTapSearch)
    )

    init(_ documentViewModel: DocumentViewModel) {
        self.documentViewModel = documentViewModel
        super.init(nibName: nil, bundle: nil)
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        customThumbnailView.translatesAutoresizingMaskIntoConstraints = false
        searchView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(pdfView)
        view.addSubview(customThumbnailView)
        view.addSubview(searchView)

        setGestures()
        
  
        NSLayoutConstraint.activate(
            [
                pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                pdfView.topAnchor
                    .constraint(equalTo: view.topAnchor),
                pdfView.bottomAnchor.constraint(
                    equalTo: view.bottomAnchor
                ),

                customThumbnailView.leadingAnchor.constraint(
                    equalTo: view.leadingAnchor,
                    constant: 16
                ),
                customThumbnailView.topAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.topAnchor,
                    constant: 0
                ),

                customThumbnailView.bottomAnchor
                    .constraint(
                        equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                        constant: 0
                    ),
                searchView.bottomAnchor
                    .constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
                searchView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                searchView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ]
        )
        
        
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItems = [makeMenuButton()]
        toolbarItems = [UIBarButtonItem.flexibleSpace(), searchButton]
        
        loadPDF(url: documentViewModel.documentURL)
        customThumbnailView.configure(with: pdfView)
        
    }
    
   

    override func viewDidAppear(_ animated: Bool) {
        setToolbarVisibility(visible: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didApplyInitialScale {
            applyScaleToFitIfNeeded(force: !didApplyInitialScale)
            let extractedExpr: Int = documentViewModel.loadLastReadPage()
            if let documentPage = pdfView.document?.page(
                at: extractedExpr
            ) {
                goToPage(documentPage)
            }
        }
    }
    
    private func setGestures() {
        let swipeLeftGesture = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipe(_:))
        )
        swipeLeftGesture.direction = .left
        
        let swipeRightGesture = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipe(_:))
        )
        swipeRightGesture.direction = .right
        let swipeVerticalGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePan(_:))
        )
        swipeVerticalGesture.delegate = self
        swipeVerticalGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(swipeLeftGesture)
        view.addGestureRecognizer(swipeRightGesture)
        view.addGestureRecognizer(swipeVerticalGesture)
    }
    
    @objc func setToolbarVisibility(visible: Bool){
        if let  navController = navigationController {
            navController.setToolbarHidden(!visible, animated: true)
            navController.toolbar.layoutIfNeeded()
        }
    }
    

    private func loadPDF(url: URL) {
        let isAccessing = url.startAccessingSecurityScopedResource()
        if let document = PDFDocument(url: url) {
            pdfView.document = document
            title = url.lastPathComponent
        } else {
            print("Can't open PDF")
        }
        if isAccessing {
            url.stopAccessingSecurityScopedResource()
        }
    }

    @objc func dismissSelf() {
        if let document = pdfView.document,
            let currentPage = pdfView.currentPage
        {
            let pageIndex = document.index(for: currentPage)
            documentViewModel.saveLastReadPage(page: pageIndex)
        }
        dismiss(animated: true)
    }

    private func makeMenuButton() -> UIBarButtonItem {

        let shareAction = UIAction(
            title: "Share",
            image: UIImage(systemName: "square.and.arrow.up")
        ) { [weak self] _ in
            self?.shareDocument()
        }
        let menu = UIMenu(title: "", children: [shareAction])
        return UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            menu: menu
        )
    }

    private func shareDocument() {
        guard let url = documentURL else { return }
        let activityController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        activityController.popoverPresentationController?.barButtonItem =
            navigationItem.rightBarButtonItem
        present(activityController, animated: true)
    }

    private func applyScaleToFitIfNeeded(force: Bool) {
        guard pdfView.document != nil, pdfView.bounds.width > 0,
            pdfView.bounds.height > 0
        else { return }
        pdfView.autoScales = false
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false, withViewOptions: nil)
        pdfView.displaysPageBreaks = false
        pdfView.displayMode = .singlePageContinuous
        let fitScale = pdfView.scaleFactorForSizeToFit
        guard fitScale > 0 else { return }
        
        pdfView.minScaleFactor = fitScale
        pdfView.maxScaleFactor = max(fitScale * 5, 5.0)
        if force {
            pdfView.scaleFactor = fitScale
            didApplyInitialScale = true
        }
    }

    func goToPage(_ page: PDFPage) {
        let pageBounds = page.bounds(for: .cropBox)
        let destination = PDFDestination(
            page: page,
            at: CGPoint(x: pageBounds.minX, y: pageBounds.maxY)
        )
        pdfView.go(to: destination)
    }

    func goToSelection(_ selection: PDFSelection) {
        self.pdfView.setCurrentSelection(selection, animate: true)
       
        guard let page = selection.pages.first else { return }
        goToPage( page)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let scrollView = self.pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
                var offset = scrollView.contentOffset
                if page.pageRef?.pageNumber != 1 {
                    offset.y -= self.view.safeAreaInsets.top
                    scrollView.setContentOffset(offset, animated: false)
                }
            }
        }
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:
            customThumbnailView.setHiddenStatus(true, animated: true)
        case .right:
            customThumbnailView.setHiddenStatus(false, animated: true)
        default:
            break
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer)
        -> Bool
    {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        let velocity = pan.velocity(in: view)
        return abs(velocity.y) > abs(velocity.x)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer:
            UIGestureRecognizer
    ) -> Bool {
        true
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .changed:
            if abs(translation.y) > abs(translation.x) {
                customThumbnailView.togglePageNumberHiddenStatus()
            }
        default:
            break
        }
    }
}
