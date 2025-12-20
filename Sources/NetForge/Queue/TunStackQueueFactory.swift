//
//  TunStackQueueFactory.swift
//  NetForge
//
//  Created by MagicianQuinn on 2025/12/19.
//


import Foundation

public enum QueueRole {
    case process
    case delegate
}

public enum TunStackQueueFactory {
    private static let processKey: DispatchSpecificKey<String> = .init()
    private static let delegateKey: DispatchSpecificKey<String> = .init()

    private static let processLabel = "NetForge.TunStack.ProcessQueue"
    private static let delegateLabel = "NetForge.TunStack.delegateQueue"

    private static let processQueue: DispatchQueue = {
        let queue = DispatchQueue(label: processLabel, qos: .userInitiated)
        queue.setSpecific(key: processKey, value: processLabel)
        return queue
    }()

    private static let delegateQueue: DispatchQueue = {
        let queue = DispatchQueue(label: delegateLabel, qos: .userInitiated)
        queue.setSpecific(key: delegateKey, value: delegateLabel)
        return queue
    }()

    @inline(__always)
    public static func getQueue(_ role: QueueRole) -> DispatchQueue {
        switch role {
        case .process:
            return processQueue
        case .delegate:
            return delegateQueue
        }
    }

    @inline(__always)
    public static func onQueue(_ role: QueueRole) -> Bool {
        switch role {
        case .process:
            return DispatchQueue.getSpecific(key: processKey) == processLabel
        case .delegate:
            return DispatchQueue.getSpecific(key: delegateKey) == delegateLabel
        }
    }

    @inline(__always)
    public static func performSync<T>(on role: QueueRole, _ work: () throws -> T) rethrows -> T {
        if onQueue(role) {
            return try work()
        } else {
            return try getQueue(role).sync(execute: work)
        }
    }

    @inline(__always)
    public static func performAsync(on role: QueueRole, _ work: @escaping () -> Void) {
        if onQueue(role) {
            work()
        } else {
            getQueue(role).async(execute: work)
        }
    }

    @inline(__always)
    public static func require(_role: QueueRole, file: StaticString = #file, line: UInt = #line) {
        precondition(onQueue(_role), "This method must be called on the \(_role) queue.", file: file, line: line)
    }
}
