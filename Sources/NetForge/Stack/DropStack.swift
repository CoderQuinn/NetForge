//
//  DropStack.swift
//  NetForge
//
//  Created by MagicianQuinn on 2025/12/19.
//

import Foundation

final class DropStack: IPStackProtocol {
    var outboundHandler: OutboundHandler?

    func start() {}

    func inBound(packet: Data, version: NSNumber) -> Bool {
        return true
    }
}
