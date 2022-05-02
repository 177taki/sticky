//
//  SeriesCollectionViewCell.swift
//  sensor-ios
//
//  Created by taki on 9/2/16.
//  Copyright © 177taki. All rights reserved.
//

import UIKit

class SeriesCollectionViewCell: UICollectionViewCell {
    
    var id: String?
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var subject: UILabel!
    @IBOutlet weak var predicate: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var author: UILabel!
    
}
