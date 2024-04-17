//
//  ViewController.swift
//  iOS Assignment
//
//  Created by Bhargav Bhatti on 17/04/24.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView?
    var isLoading = false
    let refreshControl = UIRefreshControl()
    var currentPage = 2
    let totalPages = 10000
    
    var imageUrls: [URL] = []{
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.collectionView?.reloadData()
                self.currentPage += 1
                self.hideLoader()
            }
        }
    }
 
    var imageCache: NSCache<NSString, UIImage> = NSCache()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupCollectionView()
        self.fetchImageURLs()
      
    }
    
    private func setupCollectionView() {
            collectionView?.delegate = self
            collectionView?.dataSource = self
            collectionView?.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
            
            if #available(iOS 10.0, *) {
                collectionView?.refreshControl = refreshControl
            } else {
                collectionView?.addSubview(refreshControl)
            }
            
            refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        }
    
    @objc private func refreshData() {
        fetchImageURLs()
    }
}

extension ViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        
        let imageUrl = imageUrls[indexPath.item]
        let placeholderImage = UIImage(named: "placeholder")
        loadImage(from: imageUrl, placeholder: placeholderImage) { image in
            cell.configure(with: image)
        }
        
        return cell
    }
    
}
extension ViewController: UICollectionViewDelegate{
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if indexPath.item == imageUrls.count - 1, currentPage < totalPages && !isLoading{
            showLoader()
            self.fetchImageURLs()
        }
    }
}
extension ViewController{
    @objc func fetchImageURLs() {
        
        let initialURL = URL(string: "\(baseUrl)?client_id=\(accessKey)&order_by=ORDER&per_page=\(currentPage)")!
        print("initialURL:- \(initialURL)")
        URLSession.shared.dataTask(with: initialURL) { data, response, error in
           
            if let error = error {
                print("Error fetching image URLs: \(error)")
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            guard response.statusCode == 200 else {
                print("HTTP status code: \(response.statusCode)")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    
                    let urls = json.compactMap { $0["urls"] as? [String: String] }
                        .compactMap { $0["regular"] }
                        .compactMap { URL(string: $0) }
                    
                    self.imageUrls.append(contentsOf: urls)
                   
                    
                } else {
                    print("Invalid JSON format")
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }.resume()
    }
    
    
    
    
    
    func loadImage(from url: URL, placeholder: UIImage?, completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = imageCache.object(forKey: url.absoluteString as NSString) {
            completion(cachedImage)
            return
        }
        
        if let placeholderImage = placeholder {
            completion(placeholderImage)
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            
            
            self.imageCache.setObject(image, forKey: url.absoluteString as NSString)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}

extension ViewController{
    func showLoader() {
        let loaderView = UIActivityIndicatorView(style: .gray)
        loaderView.startAnimating()
        loaderView.center = CGPoint(x: collectionView?.bounds.size.width ?? 0.0 / 2, y: collectionView?.contentSize.height ?? 0.0 + 50)
        
        collectionView?.addSubview(loaderView)
        isLoading = true
    }
    
    func hideLoader() {
        collectionView?.subviews.forEach { subview in
            if let loaderView = subview as? UIActivityIndicatorView {
                loaderView.removeFromSuperview()
                isLoading = false
            }
        }
    }
}

