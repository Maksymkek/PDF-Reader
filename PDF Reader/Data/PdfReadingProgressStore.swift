//
//  PdfReadingProgressStore.swift
//  PDF Reader
//
//  Created by Максим Грищенков on 03.03.2026.
//

import Foundation


final class PDFReadingProgressStore {
    
    private enum DefaultsKeys: String{
        case pdfLastPage = "pdf_lastPage_"
    }
    
    func save(page: Int, for documentID: String) {
        UserDefaults.standard.set(page, forKey: key(for: documentID))
    }

    func load(for documentID: String) -> Int {
        UserDefaults.standard.integer(forKey: key(for: documentID))
    }

    private func key(for documentID: String) -> String {
        "\(DefaultsKeys.pdfLastPage)\(documentID)"
    }
    
    func clearKeys() {
        if let bundleID = Bundle.main.bundleIdentifier,
           let dict = UserDefaults.standard.persistentDomain(forName: bundleID) {

            let matchedKeys = dict.keys.filter { $0.contains("pdf_lastPage_") }

            print(matchedKeys)
        }
    }
    
    func clearKey(for documentID: String){
        UserDefaults.standard.removeObject(forKey: key(for: documentID))
    }
}
