//
//  ZipTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 2/2/20.
//

import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, macCatalyst 13.0, *)
extension Tasks {

  public final class Zip<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol>:
    GroupProducerTask<(T1.Output, T2.Output), T1.Failure>
    where T1.Failure == T2.Failure
  {
    
    public init(
      tasks: (T1, T2)
    ) {
      let name = String(describing: Self.self)
      
      let maxQos =
        QualityOfService(rawValue: max(tasks.0.qualityOfService.rawValue, tasks.1.qualityOfService.rawValue))!
      let maxPriority =
        Operation.QueuePriority(rawValue: max(tasks.0.queuePriority.rawValue, tasks.1.queuePriority.rawValue))!
      
      let zip =
        BlockProducerTask<(T1.Output, T2.Output), T1.Failure>(
          name: "\(name).Zip",
          qos: maxQos,
          priority: maxPriority
        ) { (task, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          guard let consumed1 = tasks.0.produced,
                let consumed2 = tasks.1.produced else
          {
            finish(.failure(.internalFailure(ConsumerProducerTaskError.producingFailure)))
            return
          }
          
          if case let .success(value1) = consumed1,
             case let .success(value2) = consumed2
          {
            finish(.success((value1, value2)))
          } else if case let .failure(error) = consumed1 {
            finish(.failure(error))
          } else if case let .failure(error) = consumed2 {
            finish(.failure(error))
          }
        }
        .addDependency(tasks.0)
        .addDependency(tasks.1)
      
      super.init(
        name: name,
        qos: maxQos,
        priority: maxPriority,
        underlyingQueue: (tasks.0 as? TaskQueueContainable)?.innerQueue.underlyingQueue,
        tasks: (tasks.0, tasks.1, zip),
        produced: zip
      )
    }
  }
  
  // MARK: -
  
  public final class Zip3<T1: ProducerTaskProtocol, T2: ProducerTaskProtocol, T3: ProducerTaskProtocol>:
    GroupProducerTask<(T1.Output, T2.Output, T3.Output), T1.Failure>
    where T1.Failure == T2.Failure,
          T2.Failure == T3.Failure
  {
  
    public init(
      tasks: (T1, T2, T3),
      underlyingQueue: DispatchQueue? = nil
    ) {
      let name = String(describing: Self.self)
      
      let maxQos =
        QualityOfService(
          rawValue: max(
            tasks.0.qualityOfService.rawValue,
            tasks.1.qualityOfService.rawValue,
            tasks.2.qualityOfService.rawValue))!
      let maxPriority =
        Operation.QueuePriority(
          rawValue: max(
            tasks.0.queuePriority.rawValue,
            tasks.1.queuePriority.rawValue,
            tasks.2.queuePriority.rawValue))!
      
      let zip =
        BlockProducerTask<(T1.Output, T2.Output, T3.Output), T1.Failure>(
          name: "\(name).Zip",
          qos: maxQos,
          priority: maxPriority
        ) { (task, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          guard let consumed1 = tasks.0.produced,
            let consumed2 = tasks.1.produced,
            let consumed3 = tasks.2.produced else
          {
            finish(.failure(.internalFailure(ConsumerProducerTaskError.producingFailure)))
            return
          }
          
          if case let .success(value1) = consumed1,
            case let .success(value2) = consumed2,
            case let .success(value3) = consumed3
          {
            finish(.success((value1, value2, value3)))
          } else if case let .failure(error) = consumed1 {
            finish(.failure(error))
          } else if case let .failure(error) = consumed2 {
            finish(.failure(error))
          } else if case let .failure(error) = consumed3 {
            finish(.failure(error))
          }
        }
        .addDependency(tasks.0)
        .addDependency(tasks.1)
        .addDependency(tasks.2)
      
      super.init(
        name: name,
        qos: maxQos,
        priority: maxPriority,
        underlyingQueue: (tasks.0 as? TaskQueueContainable)?.innerQueue.underlyingQueue,
        tasks: (tasks.0, tasks.1, tasks.2, zip),
        produced: zip
      )
  }
}
  
  // MARK: -
  
  public final class Zip4<T1: ProducerTaskProtocol,
                          T2: ProducerTaskProtocol,
                          T3: ProducerTaskProtocol,
                          T4: ProducerTaskProtocol>:
    GroupProducerTask<(T1.Output, T2.Output, T3.Output, T4.Output), T1.Failure>
    where T1.Failure == T2.Failure,
          T2.Failure == T3.Failure,
          T3.Failure == T4.Failure
  {
    
    public init(
      tasks: (T1, T2, T3, T4),
      underlyingQueue: DispatchQueue? = nil
    ) {
      let name = String(describing: Self.self)
      
      let maxQos =
        QualityOfService(
          rawValue: max(
            tasks.0.qualityOfService.rawValue,
            tasks.1.qualityOfService.rawValue,
            tasks.2.qualityOfService.rawValue,
            tasks.3.qualityOfService.rawValue))!
      let maxPriority =
        Operation.QueuePriority(
          rawValue: max(
            tasks.0.queuePriority.rawValue,
            tasks.1.queuePriority.rawValue,
            tasks.2.queuePriority.rawValue,
            tasks.3.queuePriority.rawValue))!
      
      let zip =
        BlockProducerTask<(T1.Output, T2.Output, T3.Output, T4.Output), T1.Failure>(
          name: "\(name).Zip",
          qos: maxQos,
          priority: maxPriority
        ) { (task, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          guard let consumed1 = tasks.0.produced,
                let consumed2 = tasks.1.produced,
                let consumed3 = tasks.2.produced,
                let consumed4 = tasks.3.produced else
          {
            finish(.failure(.internalFailure(ConsumerProducerTaskError.producingFailure)))
            return
          }
          
          if case let .success(value1) = consumed1,
             case let .success(value2) = consumed2,
             case let .success(value3) = consumed3,
             case let .success(value4) = consumed4
          {
            finish(.success((value1, value2, value3, value4)))
          } else if case let .failure(error) = consumed1 {
            finish(.failure(error))
          } else if case let .failure(error) = consumed2 {
            finish(.failure(error))
          } else if case let .failure(error) = consumed3 {
            finish(.failure(error))
          } else if case let .failure(error) = consumed4 {
            finish(.failure(error))
          }
        }
        .addDependency(tasks.0)
        .addDependency(tasks.1)
        .addDependency(tasks.2)
        .addDependency(tasks.3)
      
      super.init(
        name: name,
        qos: maxQos,
        priority: maxPriority,
        underlyingQueue: (tasks.0 as? TaskQueueContainable)?.innerQueue.underlyingQueue,
        tasks: (tasks.0, tasks.1, tasks.2, tasks.3, zip),
        produced: zip
      )
    }
  }
  
  // MARK: -
  
  public final class Zip5<T1: ProducerTaskProtocol,
                          T2: ProducerTaskProtocol,
                          T3: ProducerTaskProtocol,
                          T4: ProducerTaskProtocol,
                          T5: ProducerTaskProtocol>:
    GroupProducerTask<(T1.Output, T2.Output, T3.Output, T4.Output, T5.Output), T1.Failure>
    where T1.Failure == T2.Failure,
          T2.Failure == T3.Failure,
          T3.Failure == T4.Failure,
          T4.Failure == T5.Failure
  {
    
    public init(
      tasks: (T1, T2, T3, T4, T5),
      underlyingQueue: DispatchQueue? = nil
    ) {
      let name = String(describing: Self.self)
      
      let maxQos =
        QualityOfService(
          rawValue: max(
            tasks.0.qualityOfService.rawValue,
            tasks.1.qualityOfService.rawValue,
            tasks.2.qualityOfService.rawValue,
            tasks.3.qualityOfService.rawValue,
            tasks.4.qualityOfService.rawValue))!
      let maxPriority =
        Operation.QueuePriority(
          rawValue: max(
            tasks.0.queuePriority.rawValue,
            tasks.1.queuePriority.rawValue,
            tasks.2.queuePriority.rawValue,
            tasks.3.queuePriority.rawValue,
            tasks.4.queuePriority.rawValue))!
      
      let zip =
        BlockProducerTask<(T1.Output, T2.Output, T3.Output, T4.Output, T5.Output), T1.Failure>(
          name: "\(name).Zip",
          qos: maxQos,
          priority: maxPriority
        ) { (task, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          guard let consumed1 = tasks.0.produced,
                let consumed2 = tasks.1.produced,
                let consumed3 = tasks.2.produced,
                let consumed4 = tasks.3.produced,
                let consumed5 = tasks.4.produced else
          {
            finish(.failure(.internalFailure(ConsumerProducerTaskError.producingFailure)))
            return
          }
          
          if case let .success(value1) = consumed1,
             case let .success(value2) = consumed2,
             case let .success(value3) = consumed3,
             case let .success(value4) = consumed4,
             case let .success(value5) = consumed5
          {
            finish(.success((value1, value2, value3, value4, value5)))
          } else if case let .failure(error) = consumed1 {
            finish(.failure(error))
          } else if case let .failure(error) = consumed2 {
            finish(.failure(error))
          } else if case let .failure(error) = consumed3 {
            finish(.failure(error))
          } else if case let .failure(error) = consumed4 {
            finish(.failure(error))
          } else if case let .failure(error) = consumed5 {
            finish(.failure(error))
          }
        }
        .addDependency(tasks.0)
        .addDependency(tasks.1)
        .addDependency(tasks.2)
        .addDependency(tasks.3)
        .addDependency(tasks.4)
      
      super.init(
        name: name,
        qos: maxQos,
        priority: maxPriority,
        underlyingQueue: (tasks.0 as? TaskQueueContainable)?.innerQueue.underlyingQueue,
        tasks: (tasks.0, tasks.1, tasks.2, tasks.3, tasks.4, zip),
        produced: zip
      )
    }
  }
  
  // MARK: -
  
  public final class Zip6<T1: ProducerTaskProtocol,
                          T2: ProducerTaskProtocol,
                          T3: ProducerTaskProtocol,
                          T4: ProducerTaskProtocol,
                          T5: ProducerTaskProtocol,
                          T6: ProducerTaskProtocol>:
    GroupProducerTask<(T1.Output, T2.Output, T3.Output, T4.Output, T5.Output, T6.Output), T1.Failure>
    where T1.Failure == T2.Failure,
          T2.Failure == T3.Failure,
          T3.Failure == T4.Failure,
          T4.Failure == T5.Failure,
          T5.Failure == T6.Failure
  {
    
    public init(
      tasks: (T1, T2, T3, T4, T5, T6),
      underlyingQueue: DispatchQueue? = nil
    ) {
      let name = String(describing: Self.self)
      
      let maxQos =
        QualityOfService(
          rawValue: max(
            tasks.0.qualityOfService.rawValue,
            tasks.1.qualityOfService.rawValue,
            tasks.2.qualityOfService.rawValue,
            tasks.3.qualityOfService.rawValue,
            tasks.4.qualityOfService.rawValue,
            tasks.5.qualityOfService.rawValue))!
      let maxPriority =
        Operation.QueuePriority(
          rawValue: max(
            tasks.0.queuePriority.rawValue,
            tasks.1.queuePriority.rawValue,
            tasks.2.queuePriority.rawValue,
            tasks.3.queuePriority.rawValue,
            tasks.4.queuePriority.rawValue,
            tasks.5.queuePriority.rawValue))!
      
      let zip =
        BlockProducerTask<(T1.Output, T2.Output, T3.Output, T4.Output, T5.Output, T6.Output), T1.Failure>(
          name: "\(name).Zip",
          qos: maxQos,
          priority: maxPriority
        ) { (task, finish) in
          guard !task.isCancelled else {
            finish(.failure(.internalFailure(ProducerTaskError.executionFailure)))
            return
          }
          
          guard let consumed1 = tasks.0.produced,
            let consumed2 = tasks.1.produced,
            let consumed3 = tasks.2.produced,
            let consumed4 = tasks.3.produced,
            let consumed5 = tasks.4.produced,
            let consumed6 = tasks.5.produced else
          {
            finish(.failure(.internalFailure(ConsumerProducerTaskError.producingFailure)))
            return
          }
          
          if case let .success(value1) = consumed1,
            case let .success(value2) = consumed2,
            case let .success(value3) = consumed3,
            case let .success(value4) = consumed4,
            case let .success(value5) = consumed5,
            case let .success(value6) = consumed6
          {
            finish(.success((value1, value2, value3, value4, value5, value6)))
          } else if case let .failure(error) = consumed1 {
            finish(.failure(error))
          } else if case let .failure(error) = consumed2 {
            finish(.failure(error))
          } else if case let .failure(error) = consumed3 {
            finish(.failure(error))
          } else if case let .failure(error) = consumed4 {
            finish(.failure(error))
          } else if case let .failure(error) = consumed5 {
            finish(.failure(error))
          } else if case let .failure(error) = consumed6 {
            finish(.failure(error))
          }
        }
        .addDependency(tasks.0)
        .addDependency(tasks.1)
        .addDependency(tasks.2)
        .addDependency(tasks.3)
        .addDependency(tasks.4)
        .addDependency(tasks.5)
      
      super.init(
        name: name,
        qos: maxQos,
        priority: maxPriority,
        underlyingQueue: (tasks.0 as? TaskQueueContainable)?.innerQueue.underlyingQueue,
        tasks: (tasks.0, tasks.1, tasks.2, tasks.3, tasks.4, tasks.5, zip),
        produced: zip
      )
    }
  }
}
