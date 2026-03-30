//
//  DarkPdfPage.swift
//  PDF Reader
//
//  Created by Максим Грищенков on 27.02.2026.
//

import PDFKit

class DarkModePDFPage: PDFPage {
    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        // 1. Отрисовываем оригинальную страницу (со всеми шрифтами и картинками)
        super.draw(with: box, to: context)
        
        // 2. Включаем режим наложения "Разница" (Difference)
        context.saveGState()
        context.setBlendMode(.difference)
        
        // 3. Заливаем всю страницу белым цветом
        // В режиме .difference наложение белого на белый дает черный, а белого на черный - белый!
        context.setFillColor(UIColor.white.cgColor)
     //   context.fill()
        context.fill(bounds(for: box))
        context.restoreGState()
    }
}
