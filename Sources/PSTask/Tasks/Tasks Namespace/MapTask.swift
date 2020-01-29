//
//  Map.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/28/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Tasks {
  
  public final class Map<Input, Failure1: Error, Output, Failure2: Error>: GroupProducerTask<Output, Failure2> {
    
    private let transform: (Input) -> Output
    
    // MARK: -
    
    public init(
      from: ProducerTask<Input, Failure1>,
      transform: (Input) -> Output
    ) {
      
      let transformTask =
        BlockConsumerProducerTask<Input, Output, Failure1>(
          name: "Map.Transform",
          qos: from.qualityOfService,
          priority: from.queuePriority,
          producing: from
        ) { (consumed, finishing) in finishing(consumed.map(transform)) }
      
      super.init(
        name: "Map",
        qos: from.qualityOfService,
        priority: from.queuePriority,
        underlyingQueue: nil,
        tasks: [transformTask]
      )
    }
  }
}
