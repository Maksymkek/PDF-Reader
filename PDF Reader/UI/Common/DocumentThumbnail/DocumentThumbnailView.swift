import PDFKit
//
//  DocumentThumbnailView.swift
//  PDF Reader
//
//  Created by Максим Грищенков on 05.03.2026.
//
import UIKit

final class DocumentThumbnailView: UIView {
    private weak var pdfView: PDFView?

    private let thumbnailSize = CGSize(width: 60, height: 80)

    private var isThumbnailViewHidden = false

    private var didApplyInitialVisibility = false

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = thumbnailSize  
        layout.sectionInset = UIEdgeInsets(
            top: 12,
            left: 12,
            bottom: 12,
            right: 12
        )

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)

        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(
            PageThumbnailCell.self,
            forCellWithReuseIdentifier: PageThumbnailCell.reuseIdentifier
        )
        return cv
    }()

    private let pageNumberView: CurrentPageNumberView = CurrentPageNumberView()

    private let backGroundView = UIVisualEffectView()

    private lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView(
            arrangedSubviews: [backGroundView, pageNumberView]
        )
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setupUI() {
        let effect = UIGlassEffect(style: .regular)
        backGroundView.effect = effect
        backGroundView.cornerConfiguration = .corners(radius: 24)
        backGroundView.clipsToBounds = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        backGroundView.contentView.addSubview(collectionView)
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(onPageNumberTap(_:))
        )
        pageNumberView.addGestureRecognizer(tapGesture)
        let layout =
            collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        let leftInset = layout?.sectionInset.left ?? 0
        let rightInset = layout?.sectionInset.right ?? 0
        addSubview(horizontalStackView)
        NSLayoutConstraint.activate(
            [
                horizontalStackView.leadingAnchor.constraint(
                    equalTo: leadingAnchor
                ),
                horizontalStackView.trailingAnchor.constraint(
                    equalTo: trailingAnchor
                ),
                horizontalStackView.topAnchor.constraint(equalTo: topAnchor),
                horizontalStackView.bottomAnchor.constraint(
                    equalTo: bottomAnchor
                ),
                backGroundView.heightAnchor.constraint(
                    equalTo: horizontalStackView.heightAnchor
                ),
                collectionView.leadingAnchor
                    .constraint(equalTo: backGroundView.leadingAnchor),
                collectionView.widthAnchor
                    .constraint(
                        greaterThanOrEqualToConstant: thumbnailSize.width
                            + leftInset + rightInset
                    ),
                collectionView.trailingAnchor.constraint(
                    equalTo: backGroundView.trailingAnchor
                ),
                collectionView.topAnchor.constraint(
                    equalTo: backGroundView.topAnchor
                ),
                collectionView.bottomAnchor.constraint(
                    equalTo: backGroundView.bottomAnchor
                ),
            ]
        )
    }

    func configure(with pdfView: PDFView) {
        self.pdfView = pdfView
        pageNumberView
            .configure(
                currentPage: pdfView.currentPage?.pageRef?.pageNumber ?? 1,
                totalPages: pdfView.document?.pageCount ?? 1
            )
        setupObserver()
        reloadThumbnails()
    }

    func reloadThumbnails() {
        collectionView.reloadData()
    }

    @objc func onPageNumberTap(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            setHiddenStatus(false, animated: true)
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let interactiveViews: [UIView] = [backGroundView, pageNumberView]

        return interactiveViews.contains { view in
            guard !view.isHidden, view.alpha > 0.01,
                view.isUserInteractionEnabled
            else {
                return false
            }

            let convertedPoint = convert(point, to: view)
            return view.point(inside: convertedPoint, with: event)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !didApplyInitialVisibility {
            setHiddenStatus(true, animated: false)
            didApplyInitialVisibility = true
        }
    }

}

extension DocumentThumbnailView: UICollectionViewDataSource,
    UICollectionViewDelegate
{
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return pdfView?.document?.pageCount ?? 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PageThumbnailCell.reuseIdentifier,
                for: indexPath
            ) as? PageThumbnailCell,
            let page = pdfView?.document?.page(at: indexPath.item)
        else {
            return UICollectionViewCell()
        }

        let thumbnailSize = CGSize(width: 60, height: 80)
        cell.imageView.image = page.thumbnail(of: thumbnailSize, for: .cropBox)

        if let currentPage = pdfView?.currentPage,
            let currentIndex = pdfView?.document?.index(for: currentPage)
        {
            cell.imageView.layer.borderWidth =
                (currentIndex == indexPath.item) ? 2 : 0
            cell.imageView.layer.borderColor = UIColor.systemBlue.cgColor
        }

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let page = pdfView?.document?.page(at: indexPath.item) else {
            return
        }

        collectionView.reloadData()
        pageNumberView.updateVisibilityStatus()
        DispatchQueue.main.async { [weak self] in
            self?.parentVC?.goToPage(page)
        }

    }
}

extension DocumentThumbnailView {

    private func setupObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pdfPageChanged),
            name: .PDFViewPageChanged,
            object: self.pdfView
        )
    }

    @objc private func pdfPageChanged(notification: Notification) {
        guard let pdfView = notification.object as? PDFView,
            pdfView == self.pdfView,
            let currentPage = pdfView.currentPage,
            let pageIndex = pdfView.document?.index(for: currentPage)
        else {
            return
        }
        let pageNumber = pageIndex + 1

        collectionView.reloadData()

        let indexPath = IndexPath(item: pageIndex, section: 0)
        self.collectionView.scrollToItem(
            at: indexPath,
            at: .centeredVertically,
            animated: true
        )

        DispatchQueue.main.async {
            self.pageNumberView
                .updatePageNumber(currentPage: pageNumber)

        }

    }

    func setHiddenStatus(_ isHidden: Bool, animated: Bool) {
        guard isThumbnailViewHidden != isHidden else { return }

        isThumbnailViewHidden = isHidden
        horizontalStackView.layoutIfNeeded()
        var hiddenOffset: CGFloat = 0
        if let rootView = self.window {
            let absoluteFrame = backGroundView.convert(
                backGroundView.bounds,
                to: rootView
            )
            hiddenOffset = -absoluteFrame.maxX
        }

        let transform =
            isThumbnailViewHidden
            ? CGAffineTransform(translationX: hiddenOffset, y: 0)
            : .identity

        let animations = { [weak self] in
            guard let self else { return }
            horizontalStackView.transform = transform
        }

        if animated {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0.2,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: animations
            )
        } else {
            animations()
        }
    }

    func togglePageNumberHiddenStatus() {
        pageNumberView.updateVisibilityStatus()
    }

}

extension UIView {
    fileprivate var parentVC: DocumentViewController? {
        sequence(first: next, next: { $0?.next }).first {
            $0 is DocumentViewController
        } as? DocumentViewController
    }
}
