//
//  WHPromise.swift
//  WHPromise
//
//  Created by Hsiao, Wayne on 2019/10/26.
//  Copyright © 2019 Hsiao, Wayne. All rights reserved.
//

import Foundation

/// State represent status as well as content of a promise instance
enum State<T> {
    /// The Promise execution haven't complete.
    /// - Parameter :Contained tuple consist by fulfill handler as well as reject handler.
    case pending(_ subscribers: [(fulfill: (T)->Void, reject: (Error)->Void)])
    /// Promise execution completed.
    /// - Parameter :Value provided by execution.
    case fulfilled(T)
    /// Promise execution been rejected.
    /// - Parameter :Error provided by execution.
    case rejected(Error)
}

/// WHPromise is the light weight promise class which provide basic functionality for Promise patterns.
public final class Promise<T> {
    /// Fulfill execution.
    public typealias Fulfill = (T)->Void
    /// Reject execution.
    public typealias Reject = (Error)->Void
    
    let lockQueue = DispatchQueue(label: "com.wayne.promise")
    private var state: State<T> = .pending([])
    
    /// Initialize with execution.
    /// - Parameter body: Execution which either call fulfill function or reject funtion when execution completed.
    public init(execute: @escaping (_ fulfill: @escaping Fulfill,
        _ reject: @escaping  Reject) -> Void) {
        DispatchQueue.global().async {
            execute(self.fulfill, self.reject)
        }
    }
    
    /// Initialize with a value, the instance will always provide the value to the **then** function.
    /// - Parameter value: Value which be provided in the **then** function.
    public init(value: T) {
        fulfill(value)
    }
    /// Initialize with an error, the instance will always provide the value to the **then** function.
    /// - Parameter error: Error which be provided in the **then** function.
    public init(error: Error) {
        reject(error)
    }
    
    /// Fulfill by value, the value alway updated at first time.
    /// - Parameter value: Value to be fulfilled.
    func fulfill(_ value: T) {
        lockQueue.async {
            // Promise pattern only set value once.
            guard case .pending(_) = self.state else {
                return
            }
            self.fulfillSubcribers(result: value)
            self.updateState(.fulfilled(value))
        }
    }
    
    /// Reject with an error.
    /// - Parameter error: The error of the execution.
    func reject(_ error: Error) {
        lockQueue.async {
            self.fulfillSubcribers(result: error)
            self.updateState(.rejected(error))
        }
    }
    
    /// Update subscribers if needed.
    /// - Parameter result: Either value or error.
    func fulfillSubcribers(result: Any) {
        guard case .pending(let subscribers) = self.state else {
            return
        }
        
        for subscriber in subscribers {
            if let value = result as? T {
                subscriber.fulfill(value)
            } else if let error = result as? Error {
                subscriber.reject(error)
            }
        }
    }
    
    /// Update the status of promise instance.
    /// - Parameter state: The state to update.
    func updateState(_ state: State<T>) {
        self.state = state
    }
    
    
    /// Get the result, value if successed, error if rejected. Return new promise instance with same generic type.
    /// - Parameter fulfilled: Success handler.
    /// - Parameter rejected: Failed handler.
    @discardableResult
    public func then(_ fulfilled: @escaping Fulfill,
              _ rejected: @escaping  Reject = { _ in }) -> Promise<T> {
        let promise = Promise<T>.init { (fulfill, reject) in
            self.addSubscriber({ (value) in
                fulfill(value)
            }, reject)
        }
        promise.addSubscriber(fulfill, reject)
        return promise
    }
    
    /// Get the result, value if successed, error if rejected. Return new promise instance with the generic type as same as type of value returned in success handler.
    /// - Parameter fulfilled: Success handler, value returned directly.
    /// - Parameter rejected: Failed handler.
    @discardableResult
    public func then<NewValue>(_ fulfilled: @escaping (T)->NewValue,
    _ rejected: @escaping  Reject = { _ in }) -> Promise<NewValue> {
        let promise = Promise<NewValue>.init { (_fulfill, _reject) in
            
            self.addSubscriber({ (value) in
                _fulfill(fulfilled(value))
            }) { (error) in
                rejected(error)
            }
        }
        
        return promise
    }
    
    /// Get the result, value if successed, error if rejected. Return new promise instance with the generic type as same as type of value returned in success handler.
    /// - Parameter fulfilled: Success handler, value provided in closure.
    /// - Parameter rejected: Failed handler.
    @discardableResult
    public func then<NewValue>(_ fulfilled: @escaping (T,@escaping (NewValue)->Void)->Void,
    _ rejected: @escaping  Reject = { _ in }) -> Promise<NewValue> {
        let promise = Promise<NewValue>.init { (_fulfill, _reject) in
            
            self.addSubscriber({ (value) in
                fulfilled(value) { (newValue) in
                    _fulfill(newValue)
                }
            }) { (error) in
                rejected(error)
            }
        }
        
        return promise
    }
    
    func addSubscriber(_ fulfill: @escaping Fulfill,
                       _ reject: @escaping  Reject) {
        lockQueue.async {
            switch self.state {
            case .pending(let subscribers):
                let subscriber = (fulfill, reject)
                self.updateState(.pending(subscribers + [subscriber]))
            case .fulfilled(let value):
                fulfill(value)
            case .rejected(let error):
                reject(error)
            }
        }
    }
}
