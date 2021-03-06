//
//  TweetCell.swift
//  ReactiveTwitterSearch
//
//  Created by Colin Eberhardt on 11/05/2015.
//  Copyright (c) 2015 Colin Eberhardt. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa

class TweetCellView: UITableViewCell, ReactiveView {
  
  @IBOutlet weak var usernameText: UILabel!
  @IBOutlet weak var statusText: UILabel!
  @IBOutlet weak var avatarImageView: UIImageView!
  @IBOutlet weak var ageText: UILabel!
  
  lazy var scheduler: QueueScheduler = {
    let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
    return QueueScheduler(queue)
  }()
  
  func bindViewModel(viewModel: AnyObject) {
    if let tweetViewModel = viewModel as? TweetViewModel {
      statusText.rac_text <~ tweetViewModel.status
      usernameText.rac_text <~ tweetViewModel.username.producer |> map { "@\($0)" };
      ageText.rac_text <~ tweetViewModel.ageInSeconds.producer |> map { "\($0) secs" };
      
      let triggerSignal = self.rac_prepareForReuseSignal.asSignal() |> toVoidSignal
      
      avatarImageView.image = nil
      avatarImageSignalProducer(tweetViewModel.profileImageUrl.value)
        |> startOn(scheduler)
        |> takeUntil(triggerSignal)
        |> observeOn(QueueScheduler.mainQueueScheduler)
        |> start(next: {
          self.avatarImageView.image = $0
        })
    }
  }
  
  private func avatarImageSignalProducer(imageUrl: String) -> SignalProducer<UIImage, NoError> {
    return SignalProducer {
      sink, _ in
      let data = NSData(contentsOfURL: NSURL(string: imageUrl)!)
      let image = UIImage(data: data!)
      sendNext(sink, image!)
      sendCompleted(sink)
    }
  }
}
