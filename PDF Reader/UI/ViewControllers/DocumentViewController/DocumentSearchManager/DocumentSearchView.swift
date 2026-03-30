//
//  DocumentSearchView.swift
//  PDF Reader
//
//  Created by Максим Грищенков on 25.03.2026.
//
import UIKit

class DocumentSearchView : UIView, UISearchBarDelegate {
    
    private var searchManager: DocumentSearchManager
    
    private lazy var counterLabel: UILabel = {
            let label = UILabel()
            label.text = ""
            label.font = .systemFont(ofSize: 14)
            label.textColor = .secondaryLabel
            label.sizeToFit()
            return label
        }()
    private var didSetupCounterView = false

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = searchManager
        searchBar.placeholder = "Find"
        return searchBar
    }()

    private lazy var previousSearchResultButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        button.addTarget(
            self,
            action: #selector(didTapPreviousSearchResult),
            for: .touchUpInside
        )
        return button
    }()

    private lazy var nextSearchResultButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.addTarget(
            self,
            action: #selector(didTapNextSearchResult),
            for: .touchUpInside
        )
        return button
    }()

    private lazy var doneSearchButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = .prominentGlass()
        button.tintColor = .systemBlue
        button.setImage(UIImage(systemName: "checkmark"), for: .normal)
        button.addTarget(
            self,
            action: #selector(didTapCloseSearch),
            for: .touchUpInside
        )
        return button
    }()
    
    private lazy var glassContainer : UIVisualEffectView = {
        let glassEffect: UIGlassEffect = UIGlassEffect(style: .regular)
        glassEffect.isInteractive = true
        let glassContainer = UIVisualEffectView(effect: glassEffect)
        glassContainer.translatesAutoresizingMaskIntoConstraints = false
        glassContainer.cornerConfiguration = .capsule()
        return glassContainer
    }()

    private(set) lazy var searchContainerView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [
            doneSearchButton, searchBar,
        ])

        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 8
        view.isLayoutMarginsRelativeArrangement = true
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: 12,
            bottom: 0,
            trailing: 12
        )
       // view.isHidden = true

        return view
    }()
     
    init( vc: DocumentViewController) {
        self.searchManager = DocumentSearchManager()
        super.init(frame: .zero)
        setupUI()
        searchManager.configure(vc: vc, searchView: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(){
        setVisibilityStatus(false)
        let stack = UIStackView(
            arrangedSubviews: [
                previousSearchResultButton,
                nextSearchResultButton,
            ]
        )
        stack.axis = .horizontal
        stack.spacing = 1
        stack.translatesAutoresizingMaskIntoConstraints = false

        glassContainer.contentView.addSubview(stack)
        glassContainer.setContentHuggingPriority(.required, for: .horizontal)
        glassContainer.setContentCompressionResistancePriority(
            .required,
            for: .horizontal
        )
        glassContainer.tintColor = .black
        addSubview(searchContainerView)
        searchContainerView.addArrangedSubview(glassContainer)
        NSLayoutConstraint.activate([
            searchContainerView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
            ),
            searchContainerView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
            ),
            searchContainerView.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -8
            ),
            searchContainerView.topAnchor.constraint(
                equalTo: topAnchor,
           
            ),
            stack.topAnchor.constraint(
                equalTo: glassContainer.contentView.topAnchor
            ),
            stack.bottomAnchor.constraint(
                equalTo: glassContainer.contentView.bottomAnchor
            ),
            stack.leadingAnchor.constraint(
                equalTo: glassContainer.contentView.leadingAnchor
            ),
            stack.trailingAnchor.constraint(
                equalTo: glassContainer.contentView.trailingAnchor
            ),
            previousSearchResultButton.widthAnchor.constraint(
                equalToConstant: 44
            ),
            nextSearchResultButton.widthAnchor.constraint(
                equalToConstant: 44
            ),
            doneSearchButton.widthAnchor.constraint(equalToConstant: 44),
            doneSearchButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
    
    private func setupCounterRightViewIfNeeded() {
        guard !didSetupCounterView else { return }

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(counterLabel)

        NSLayoutConstraint.activate([
            counterLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            counterLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            counterLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            counterLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        searchBar.searchTextField.rightView = containerView
        searchBar.searchTextField.rightViewMode = .always

        didSetupCounterView = true
    }
    
    override func layoutSubviews() {
          super.layoutSubviews()
          setupCounterRightViewIfNeeded()
      }
    
    @objc func didTapSearch() {
 
        setVisibilityStatus(true,setToolbarVisible: false)
        searchBar.searchTextField.isEnabled = true
        searchBar.isUserInteractionEnabled = true
        searchBar.becomeFirstResponder()
    }
    
    func updateSearchCounter(currentIndex: Int, totalCount: Int, hide: Bool = false) {
       // setupCounterRightViewIfNeeded()
        guard !hide else {
            counterLabel.text = ""
            return
        }
        if totalCount > 0 {
            counterLabel.text = "\(currentIndex) of \(totalCount)"
        }
        else {
            counterLabel.text = "0"
        }
    }

    @objc private func didTapPreviousSearchResult() {
        searchManager.showPreviousResult()
      
    }

    @objc private func didTapNextSearchResult() {
        searchManager.showNextResult()
        
    }
    
    private func setVisibilityStatus(_ visible: Bool, setToolbarVisible: Bool? = nil){
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.searchContainerView.alpha = visible ? 1.0 : 0.0
        } completion: { [weak self] status in
            if let visible = setToolbarVisible{
                self?.searchManager.vc?.setToolbarVisibility(visible: visible)
            }
        }
    }

    @objc private func didTapCloseSearch() {
        searchManager.cancelSearch(searchBar)
        setVisibilityStatus(false, setToolbarVisible: true)
    }
}
