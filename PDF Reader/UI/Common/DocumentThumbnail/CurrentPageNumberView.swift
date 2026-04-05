//
//  CurrentPageNumberView.swift
//  PDF Reader
//
//  Created by Максим Грищенков on 13.03.2026.
//
import UIKit

final class CurrentPageNumberView: UIVisualEffectView {
    private let makeLabel: (String?) -> UILabel = { text in
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.text = text
        return label
    }
    private lazy var pageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.text = "1 of 1"
        return label
    }()

    private var totalPages: Int = 1
    private var timer: Timer?

    private lazy var icon: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(systemName: "sidebar.squares.leading")
        )
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        return imageView
    }()

    private lazy var stackView: UIStackView = {

        let stackView = UIStackView(
            arrangedSubviews: [icon, pageLabel]
        )
        stackView.axis = .horizontal
        stackView.alignment = .top
        // stackView.distribution = .equalSpacing
        stackView.spacing = 8
        return stackView
    }()

    override init(effect: UIVisualEffect?) {
        super.init(effect: UIGlassEffect(style: .regular))
        setupUI()

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        cornerConfiguration = .capsule()
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 8
            ),
            stackView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -8
            ),
            stackView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 8
            ),
            stackView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -8
            ),
        ])

    }
    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil {
            self.timer = Timer.scheduledTimer(
                withTimeInterval: 3.0,
                repeats: false,
                block: {
                    timerInstance in
                    UIView
                        .animate(
                            withDuration: 0.5,
                            delay: 0,
                            usingSpringWithDamping: 0.9,
                            initialSpringVelocity: 0.2,
                            options: [.beginFromCurrentState],
                            animations: {
                                self.alpha = 0
                            }
                        )
                }
            )
        }
    }

    func configure(currentPage: Int, totalPages: Int) {
        self.totalPages = totalPages
        pageLabel.text = "\(currentPage) of \(totalPages)"
    }

    func updateVisibilityStatus() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(
            withTimeInterval: 3.0,
            repeats: false,
            block: {
                timerInstance in
                UIView
                    .animate(
                        withDuration: 0.5,
                        delay: 0,
                        usingSpringWithDamping: 0.9,
                        initialSpringVelocity: 0.2,
                        options: [.beginFromCurrentState],
                        animations: {
                            self.alpha = 0
                        }
                    )
            }
        )

        UIView
            .animate(
                withDuration: 0.5,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0.2,
                options: [.beginFromCurrentState],
                animations: {
                    self.alpha = 1
                },

            )
    }

    func updatePageNumber(currentPage: Int) {
        pageLabel.text = "\(currentPage) of \(totalPages)"
    }
}
