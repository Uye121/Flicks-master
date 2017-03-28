//
//  MovieViewController.swift
//  Flicks
//
//  Created by Ulric Ye on 2/3/17.
//  Copyright © 2017 uye. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MovieViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var movies: [NSDictionary]?
    var endpoint: String!
    var filteredMovies: [NSDictionary] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: .valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
        // Do any additional setup after loading the view.
        
        refresh(refreshControl: refreshControl)
    }
    
    func refreshControlAction(_ refreshControl: UIRefreshControl){
        refresh(refreshControl: refreshControl)
    }
    
    func refresh(refreshControl: UIRefreshControl) {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(self.endpoint!)?api_key=\(apiKey)")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        let label = UILabel(frame: CGRect(x: 10, y: 10, width: 50, height: 100))
        label.tag = 1
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let data = data {
                // Remove the network error screen
                self.view.alpha = 1
                self.view.backgroundColor = UIColor.white
                self.view.viewWithTag(1)?.removeFromSuperview()
                if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    print(dataDictionary)
                    
                    self.movies = dataDictionary["results"] as! [NSDictionary]
                    self.tableView.reloadData()
                }
                self.filteredMovies = self.movies!
            } else {
                label.text = "Network error"
                
                self.view.alpha = 0.5
                self.view.backgroundColor = UIColor.gray
                
                label.textAlignment = NSTextAlignment.center
                label.center = self.view.center
                label.sizeToFit()
                self.view.addSubview(label)
            }
            MBProgressHUD.hide(for: self.view, animated: true)
            // ... Use the new data to update the data source ...
            
            // Reload the tableView now that there is new data
            self.tableView.reloadData()
            
            // Tell the refreshControl to stop spinning
            refreshControl.endRefreshing()
        }
        task.resume()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filteredMovies != nil {
            return filteredMovies.count
        } else {
            return 0
        }
        
        return movies!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        
        let movie = filteredMovies[indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        
        let baseURL = "https://image.tmdb.org/t/p/w342"
        if let posterPath = movie["poster_path"] as? String {
            let imageURLRequest = NSURLRequest(url: NSURL(string: baseURL + posterPath) as! URL)
            // Have image fade in when they are initially loaded from online
            cell.posterView.setImageWith(imageURLRequest as URLRequest, placeholderImage: nil, success: { (imageURLRequest, imageResponse, image) in
                if imageResponse != nil {
                    print("Image was NOT cached, fade in image")
                    cell.posterView.alpha = 0.0
                    cell.posterView.image = image
                    UIView.animate(withDuration: 0.3, animations: {
                        cell.posterView.alpha = 1.0
                    })
                } else {
                    print("Image was cached so just update the image")
                    cell.posterView.image = image
                }
            }, failure: { (imageRequest, imageResponse, error) in
                // Do something
            })
        }
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        cell.backgroundColor = UIColor.black
        cell.overviewLabel.textColor = UIColor.white
        cell.titleLabel.textColor = UIColor.white
        
        // No color when the user selects cell
        cell.selectionStyle = .none
        
        // Use a red color when the user selects the cell
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.red
        cell.selectedBackgroundView = backgroundView
        
        print("row \(indexPath.row)")
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filteredMovies = searchText.isEmpty ? movies!: (movies?.filter({ (data: NSDictionary) -> Bool in
            let result = data["title"] as! String
            return result.range(of: searchText, options: .caseInsensitive) != nil
        }))!
        searchBar.showsCancelButton = true
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        let refreshControl = UIRefreshControl()
        
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        refresh(refreshControl: refreshControl)
        tableView.reloadData()
        
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPath(for: cell)
        let movie = movies![indexPath!.row]
        
        let detailViewController = segue.destination as! DetailViewController
        detailViewController.movie = movie
        
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
}
