//
//  RightThinkingChatTableViewCell.swift
//  Uncommon Application
//
//  Created by qizihan  on 6/8/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

/*
 The code of RightThinkingChatTableViewCell and the thinking images are used in courtesy of the ChatBot app created by Apple Inc for "AP® Computer Science Principles with Swift".
 
 Copyright © 2017 Apple Inc.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

class RightThinkingChatTableViewCell: UITableViewCell {

    @IBOutlet weak var thinkingImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        thinkingImage.animationImages = (1...3).map { index in
            return UIImage(named: "Thinking\(index)")!
        }
        thinkingImage.animationDuration = 1.5
    }
}
