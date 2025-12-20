//
//  TUNInterface.swift
//  NetForge
//
//  Created by MagicianQuinn on 2025/12/19.
//

import Foundation
import NetworkExtension

class TUNInterface {
    private unowned var packetFlow: NEPacketTunnelFlow
    private var stacks: [IPStackProtocol] = []
    private var running: Bool = false

    init(packetFlow: NEPacketTunnelFlow) {
        self.packetFlow = packetFlow
    }

    private func getFlow() -> NEPacketTunnelFlow? {
        TunStackQueueFactory.require(_role: .process)
        return packetFlow
    }

    func registerStack(stack: IPStackProtocol) {
        TunStackQueueFactory.performAsync(on: .process) { [weak self] in
            guard let self = self else {
                return
            }

            stack.outboundHandler = self.outbound()
            self.stacks.append(stack)

            if self.running {
                stack.start()
            }
        }
    }

    func start() {
        TunStackQueueFactory.performAsync(on: .process) { [weak self] in
            guard let self = self, !self.running else {
                return
            }

            for stack in self.stacks {
                stack.start()
            }

            self.loopInbound()
        }
    }

    private func loopInbound() {
        guard running else {
            return
        }

        getFlow()?.readPackets { [weak self] packets, protocols in
            guard let self = self else {
                return
            }

            TunStackQueueFactory.performAsync(on: .process) {
                guard self.running else {
                    return
                }

                for (index, packet) in packets.enumerated() {
                    for stack in self.stacks {
                        if stack.inBound(packet: packet, version: protocols[index]) {
                            break
                        }
                    }
                }

                self.loopInbound()
            }
        }
    }

    private func outbound() -> OutboundHandler {
        return { [weak self] packets, versions in
            guard let self = self else {
                return
            }

            TunStackQueueFactory.performAsync(on: .process) {
                self.getFlow()?.writePackets(packets, withProtocols: versions)
            }
        }
    }
}
