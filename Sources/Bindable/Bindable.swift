//
//  Bindable.swift
//
//
//  Created by John Sundell
// https://www.swiftbysundell.com/articles/bindable-values-in-swift/
//
// modified by Carl
// I just modified from class to struct.
//

import UIKit

public struct Bindable<Value> {
    private var observations = [(Value) -> Bool]()
    private var lastValue: Value?
    
    public init(_ value: Value? = nil) {
        lastValue = value
    }
    
    private mutating func addObservation<O: AnyObject>(
        for object: O,
        handler: @escaping (O, Value) -> Void
    ) {
        // If we already have a value available, we'll give the
        // handler access to it directly.
        lastValue.map { handler(object, $0) }
        
        // Each observation closure returns a Bool that indicates
        // whether the observation should still be kept alive,
        // based on whether the observing object is still retained.
        observations.append { [weak object] value in
            guard let object = object else {
                return false
            }
            
            handler(object, value)
            return true
        }
    }
    
    public mutating func update(with value: Value) {
        lastValue = value
        observations = observations.filter { $0(value) }
    }
    
    public mutating func bind<O: AnyObject, T>(
        _ sourceKeyPath: KeyPath<Value, T>,
        to object: O,
        _ objectKeyPath: ReferenceWritableKeyPath<O, T>
    ) {
        addObservation(for: object) { object, observed in
            let value = observed[keyPath: sourceKeyPath]
            object[keyPath: objectKeyPath] = value
        }
    }
    
    public mutating func bind<O: AnyObject, T>(
        _ sourceKeyPath: KeyPath<Value, T>,
        to object: O,
        // This line is the only change compared to the previous
        // code sample, since the key path we're binding *to*
        // might contain an optional.
        _ objectKeyPath: ReferenceWritableKeyPath<O, T?>
    ) {
        addObservation(for: object) { object, observed in
            let value = observed[keyPath: sourceKeyPath]
            object[keyPath: objectKeyPath] = value
        }
    }
    
    public mutating func bind<O: AnyObject, T, R>(
        _ sourceKeyPath: KeyPath<Value, T>,
        to object: O,
        _ objectKeyPath: ReferenceWritableKeyPath<O, R?>,
        transform: @escaping (T) -> R?
    ) {
        addObservation(for: object) { object, observed in
            let value = observed[keyPath: sourceKeyPath]
            let transformed = transform(value)
            object[keyPath: objectKeyPath] = transformed
        }
    }
}
