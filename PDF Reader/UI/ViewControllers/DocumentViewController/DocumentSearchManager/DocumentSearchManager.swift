//
//  SearchExtension.swift
//  PDF Reader
//
//  Created by Максим Грищенков on 18.03.2026.
//
import PDFKit

final class DocumentSearchManager: NSObject, UISearchBarDelegate {

    weak var vc: DocumentViewController?
    weak var searchView: DocumentSearchView?
    private(set) var searchResults: [PDFSelection] = []
    private let serial = DispatchQueue(
        label: "Document_search_sq",
        qos: .userInteractive
    )
    private var searchWorkItem: DispatchWorkItem?

    private(set) var currentSearchIndex = 0

    func configure(vc: DocumentViewController?, searchView: DocumentSearchView?)
    {
        self.vc = vc
        self.searchView = searchView
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            search(searchText)
            DispatchQueue.main.async {
                self.searchView?
                    .updateSearchCounter(
                        currentIndex: self.currentSearchIndex,
                        totalCount: self.searchResults
                            .count,
                        hide: searchText.isEmpty
                    )
            }
        }
        searchWorkItem = workItem
        DispatchQueue
            .global(qos: .userInteractive)
            .asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search(searchBar.text ?? "")

    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        cancelSearch(searchBar)
        UIView.animate(withDuration: 0.3) {
            self.vc?.navigationController?.toolbar.alpha = 1.0
        }
    }

    private func search(_ text: String) {
        guard let document = vc?.pdfView.document else {
            return
        }

        self.searchResults = document.findString(
            text,
            withOptions: .caseInsensitive
        )

        self.removeAllHighlights(from: document)

        for searchResult in self.searchResults {
            self.highlightSelection(searchResult)
        }
        self.currentSearchIndex = 0
        guard let firstResult = self.searchResults.first else { return }
        DispatchQueue.main.async {
            if let pdfView = self.vc?.pdfView {
                self.goToSearchResult(to: firstResult, in: pdfView)
            }

        }

    }
    
    private func goToSearchResult(to result: PDFSelection, in pdfView: PDFView){
        guard let viewController = vc else { return }
        pdfView.setCurrentSelection(result, animate: true)
        if let page = result.pages.first, page != pdfView.currentPage {
            DispatchQueue.main.async {
                viewController.goToSelection(result)
            }
        }
    }

    func removeAllHighlights(from document: PDFDocument) {
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }

            for annotation in page.annotations {
                if annotation.userName == "searchHighlight" {
                    page.removeAnnotation(annotation)
                }
            }
        }
    }

    func highlightSelection(_ selection: PDFSelection) {

        for _ in selection.pages {
            let boundsArray = selection.selectionsByLine()

            for lineSelection in boundsArray {
                guard let page = lineSelection.pages.first else { continue }
                let bounds = lineSelection.bounds(for: page)

                let highlight = PDFAnnotation(
                    bounds: bounds,
                    forType: .highlight,
                    withProperties: nil
                )
                highlight.userName = "searchHighlight"
                highlight.color = UIColor.yellow.withAlphaComponent(0.4)

                page.addAnnotation(highlight)
            }
        }
    }

    func showNextResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex + 1) % searchResults.count
        let result = searchResults[currentSearchIndex]
       // vc?.pdfView.setCurrentSelection(result, animate: true)
        //vc?.pdfView.go(to: result)
        if let pdfView = self.vc?.pdfView {
            self.goToSearchResult(to: result, in: pdfView)
        }
        searchView?
            .updateSearchCounter(
                currentIndex: currentSearchIndex,
                totalCount: searchResults
                    .count
            )

    }

    func showPreviousResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex =
            (currentSearchIndex - 1 + searchResults.count) % searchResults.count
        let result = searchResults[currentSearchIndex]
//        vc?.pdfView.setCurrentSelection(result, animate: true)
//        vc?.pdfView.go(to: result)
        if let pdfView = self.vc?.pdfView {
            self.goToSearchResult(to: result, in: pdfView)
        }
        searchView?
            .updateSearchCounter(
                currentIndex: currentSearchIndex,
                totalCount: searchResults
                    .count
            )
    }

    func cancelSearch(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.searchTextField.isEnabled = false
        searchBar.resignFirstResponder()
        vc?.view.window?.endEditing(true)
        searchBar.isUserInteractionEnabled = false

        searchResults.removeAll()
        currentSearchIndex = 0
        vc?.pdfView.clearSelection()
        if let document = vc?.pdfView.document {
            removeAllHighlights(from: document)
        }

    }
}
