//
//  CoreDataScheduler.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 15.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import Foundation
import CoreData
import ReactiveCocoa
import ReactiveSwift

class CoreDataScheduler : Scheduler {
    private let context: NSManagedObjectContext
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    @discardableResult func schedule(_ action: @escaping () -> Void) -> Disposable? {
        let disposable = AnyDisposable()

        context.perform {
            guard !disposable.isDisposed else {
                return
            }
            action()
        }

        return disposable
    }
}
