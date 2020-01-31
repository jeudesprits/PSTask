//
//  EmptyTask.swift
//  PSTask
//
//  Created by Ruslan Lutfullin on 1/30/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class EmptyTask: NonFailTask {
  
  public override func execute() { finish(with: .success) }
}
