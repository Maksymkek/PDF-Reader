//
//  DocumentViewModel.swift
//  PDF Reader
//
//  Created by Максим Грищенков on 03.03.2026.
//

import PDFKit

final class DocumentViewModel {

    let documentURL: URL
    let store: PDFReadingProgressStore

    init(documentURL: URL, store: PDFReadingProgressStore) {
        self.documentURL = documentURL
        self.store = store
    }

    func loadLastReadPage() -> Int {
        let documentID = documentURL.absoluteString
        return
            store
            .load(
                for: documentID
            )
    }

    func saveLastReadPage(page: Int) {
        let documentID = documentURL.absoluteString
        store.save(
            page: page,
            for: documentID
        )

    }
}
