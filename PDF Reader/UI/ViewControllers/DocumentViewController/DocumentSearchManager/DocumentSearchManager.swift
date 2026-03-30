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
    private(set) var currentSearchIndex = 0

    func configure(vc: DocumentViewController?, searchView: DocumentSearchView? ) {
        self.vc = vc
        self.searchView = searchView
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        search(searchText)
        searchView?
            .updateSearchCounter(
                currentIndex: currentSearchIndex,
                totalCount: searchResults
                    .count,
                hide: searchText.isEmpty)
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
        guard let document = vc?.pdfView.document, !text.isEmpty else {
            return
        }
        let serial = DispatchQueue(label: "Serial", qos: .userInteractive)
        serial.async{
            self.searchResults = document.findString(text, withOptions: .caseInsensitive)
            
            self.removeAllHighlights(from: document)
            for searchResult in self.searchResults {
                self.highlightSelection(searchResult)
            }
            self.currentSearchIndex = 0
            
            
        }
        guard let firstResult = searchResults.first else { return }
        vc?.pdfView.setCurrentSelection(firstResult, animate: true)
        vc?.pdfView.go(to: firstResult)
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
        vc?.pdfView.setCurrentSelection(result, animate: true)
        vc?.pdfView.go(to: result)
        searchView?
            .updateSearchCounter(
                currentIndex: currentSearchIndex,
                totalCount: searchResults
                    .count)
                
    }

    func showPreviousResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex =
            (currentSearchIndex - 1 + searchResults.count) % searchResults.count
        let result = searchResults[currentSearchIndex]
        vc?.pdfView.setCurrentSelection(result, animate: true)
        vc?.pdfView.go(to: result)
        searchView?
            .updateSearchCounter(
                currentIndex: currentSearchIndex,
                totalCount: searchResults
                    .count)
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

