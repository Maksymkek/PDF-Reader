//
//  MainFactory.swift
//  PDF Reader
//
//  Created by Максим Грищенков on 18.02.2026.
//
import UIKit
import PDFKit

final class DocumentFactory {

    func makeDocumentScreen(for documentURL: URL) -> DocumentViewController {
        let vc = DocumentViewController(makeDocumentViewModel(for: documentURL))
        vc.documentURL = documentURL
        
        return vc
    }
    
    func makeDocumentViewModel(for documentURL: URL) -> DocumentViewModel{
        return DocumentViewModel(
            documentURL: documentURL,
            store: AppFactory().makePDFReadingProgressStore()
        )
    }
}
