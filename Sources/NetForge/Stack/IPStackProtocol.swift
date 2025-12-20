//
//  IPStackProtocol.swift
//  NetForge
//
//  Created by MagicianQuinn on 2025/12/19.
//


import Foundation

public typealias OutboundHandler = (_ packets: [Data], _ versions: [NSNumber]) -> Void

public protocol IPStackProtocol: AnyObject {
    func inBound(packet: Data, version: NSNumber) -> Bool
    var outboundHandler: OutboundHandler? { get set }
    func start()
    func stop()
}

public extension IPStackProtocol {
    func stop() {}
}
