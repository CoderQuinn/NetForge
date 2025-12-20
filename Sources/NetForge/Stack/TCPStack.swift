//
//  TCPStack.swift
//  NetForge
//
//  Created by MagicianQuinn on 2025/12/19.
//

import Foundation
import Darwin
import TunForgeCore

public final class TCPStack: NSObject, IPStackProtocol, @unchecked Sendable {
    public weak var delegate: TSIPStackDelegate?

    private let tsIPStack: LWIPStack

    public override init() {
        // Initialize stored properties before calling super.init()
        tsIPStack = LWIPStack.defaultIPStack(withProcessQueue: TunStackQueueFactory.getQueue(.process))
        super.init()
    }

    public nonisolated(unsafe) static let shared: TCPStack = {
        let stack = TCPStack()
        stack.tsIPStack.delegate = stack
        stack.tsIPStack.delegateQueue = TunStackQueueFactory.getQueue(.delegate)
        return stack
    }()

    public func inBound(packet: Data, version: NSNumber) -> Bool {
        // Not support IPv6 packets now
        if version.int32Value == AF_INET6 {
            return false
        }

        let buffer = DataPacketBuffer(packet)
        guard let view = IPPacketView(buffer: buffer) else {
            return false
        }

        if view.protocolNumber != .tcp {
            return false
        }

        tsIPStack.receivedPacket(packet)
        return true
    }

    public var outboundHandler: OutboundHandler? {
        get {
            return tsIPStack.outboundHandler
        }
        set {
            tsIPStack.outboundHandler = newValue
        }
    }

    public func start() {
        tsIPStack.resumeTimer()
    }

    public func stop() {
        tsIPStack.suspendTimer()
        tsIPStack.delegate = nil
        tsIPStack.delegateQueue = nil
    }
}

extension TCPStack: TSIPStackDelegate {
    public func didAccept(_: LWTCPSocket) {
        // TODO: wire accepted sockets to proxy/NIO layer
    }
}
