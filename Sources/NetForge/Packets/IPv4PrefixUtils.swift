//
//  IPv4PrefixUtils.swift
//  NetForge
//
//  Created by MagicianQuinn on 2025/12/19.
//


import Darwin
import Foundation
import Network

public enum IPv4PrefixUtils {
    // MARK: - IPv4Address ⇄ UInt32 (Byte Order Explicit)

    @inline(__always)
    static func uint32NetworkOrder(from address: IPv4Address) -> UInt32 {
        let bytes = address.rawValue
        precondition(bytes.count == 4, "Invalid IPv4Address rawValue length")

        return UInt32(bytes[0]) << 24 |
            UInt32(bytes[1]) << 16 |
            UInt32(bytes[2]) << 8 |
            UInt32(bytes[3])
    }

    @inline(__always)
    static func address(
        fromNetworkOrder value: UInt32,
        interface: NWInterface? = nil
    ) -> IPv4Address? {
        let data = Data([
            UInt8((value >> 24) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF),
        ])
        return IPv4Address(data, interface)
    }

    @inline(__always)
    static func netmaskNetworkOrder(prefixLength: Int) -> UInt32? {
        guard (0 ... 32).contains(prefixLength) else { return nil }
        guard prefixLength > 0 else { return 0 }
        return UInt32.max << (32 - prefixLength)
    }

    @inline(__always)
    static func networkBaseNetworkOrder(
        addressNetworkOrder: UInt32,
        prefixLength: Int
    ) -> UInt32? {
        guard let mask = netmaskNetworkOrder(prefixLength: prefixLength) else {
            return nil
        }
        return addressNetworkOrder & mask
    }

    static func parseCIDR(
        _ cidr: String
    ) -> (networkNetworkOrder: UInt32, prefixLength: Int)? {
        let parts = cidr.split(separator: "/")
        guard parts.count == 2,
              let prefixLength = Int(parts[1]),
              (0 ... 32).contains(prefixLength),
              let address = IPv4Address(String(parts[0]))
        else {
            return nil
        }

        let addressNO = uint32NetworkOrder(from: address)
        guard let networkNO =
            networkBaseNetworkOrder(
                addressNetworkOrder: addressNO,
                prefixLength: prefixLength
            )
        else {
            return nil
        }

        return (networkNO, prefixLength)
    }

    @inline(__always)
    static func contains(
        _ address: IPv4Address,
        networkNetworkOrder: UInt32,
        prefixLength: Int
    ) -> Bool {
        guard let mask = netmaskNetworkOrder(prefixLength: prefixLength) else {
            return false
        }
        let addrNO = uint32NetworkOrder(from: address)
        return (addrNO & mask) == networkNetworkOrder
    }

    static func dottedDecimalString(
        from address: IPv4Address
    ) -> String? {
        let bytes = address.rawValue
        guard bytes.count == 4 else { return nil }

        var addr = in_addr(
            s_addr: UInt32(bytes[0]) << 24 |
                UInt32(bytes[1]) << 16 |
                UInt32(bytes[2]) << 8 |
                UInt32(bytes[3])
        )

        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        guard inet_ntop(AF_INET, &addr, &buffer, socklen_t(buffer.count)) != nil else {
            return nil
        }

        return String(cString: buffer)
    }

    public static func parseCIDRToStrings(
        _ cidr: String
    ) -> (base: String, mask: String)? {
        guard let (networkNO, prefixLength) = parseCIDR(cidr),
              let networkAddr = address(fromNetworkOrder: networkNO),
              let maskNO = netmaskNetworkOrder(prefixLength: prefixLength),
              let maskAddr = address(fromNetworkOrder: maskNO),
              let baseStr = dottedDecimalString(from: networkAddr),
              let maskStr = dottedDecimalString(from: maskAddr)
        else {
            return nil
        }

        return (base: baseStr, mask: maskStr)
    }
}

extension IPv4Address {
    public var dottedDecimalString: String {
        IPv4PrefixUtils.dottedDecimalString(from: self) ?? "<invalid>"
    }

    public var networkOrder: UInt32 {
        IPv4PrefixUtils.uint32NetworkOrder(from: self)
    }
}
