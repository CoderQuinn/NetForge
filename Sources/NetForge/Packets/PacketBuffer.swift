//
//  PacketBuffer.swift
//  NetForge
//
//  Created by MagicianQuinn on 2025/12/19.
//


import Foundation

// MARK: - PacketBuffer

public protocol PacketBuffer {
    var readableBytes: Int { get }

    func loadUInt8(at offset: Int) -> UInt8?
    func loadUInt16(at offset: Int) -> UInt16?
    func loadUInt32(at offset: Int) -> UInt32?

    /// Returns a view (no copy if possible) of [offset, offset+length)
    func slice(from offset: Int, length: Int) -> PacketBuffer?
}

@inline(__always)
fileprivate func loadUnaligned<T>(
    _: T.Type,
    from data: Data,
    at offset: Int
) -> T {
    data.withUnsafeBytes {
        $0.baseAddress!
            .advanced(by: offset)
            .loadUnaligned(as: T.self)
    }
}

/// Backing storage: whole Data
public struct DataPacketBuffer: PacketBuffer {
    public let data: Data
    public init(_ data: Data) { self.data = data }

    public var readableBytes: Int { data.count }

    public func loadUInt8(at offset: Int) -> UInt8? {
        guard offset >= 0, offset + 1 <= data.count else { return nil }
        return loadUnaligned(UInt8.self, from: data, at: offset)
    }

    public func loadUInt16(at offset: Int) -> UInt16? {
        guard offset >= 0, offset + 2 <= data.count else { return nil }
        let v: UInt16 = loadUnaligned(UInt16.self, from: data, at: offset)
        return UInt16(bigEndian: v)
    }

    public func loadUInt32(at offset: Int) -> UInt32? {
        guard offset >= 0, offset + 4 <= data.count else { return nil }
        let v: UInt32 = loadUnaligned(UInt32.self, from: data, at: offset)
        return UInt32(bigEndian: v)
    }

    public func slice(from offset: Int, length: Int) -> PacketBuffer? {
        guard offset >= 0, length >= 0, offset + length <= data.count else { return nil }
        return DataSlicePacketBuffer(data: data, start: offset, length: length)
    }

    public func materialize() -> Data { data }
}

/// Backing storage: Data + range (real view, no subdata copy)
public struct DataSlicePacketBuffer: PacketBuffer {
    public let data: Data
    public let start: Int
    public let length: Int

    public init(data: Data, start: Int, length: Int) {
        self.data = data
        self.start = start
        self.length = length
    }

    public var readableBytes: Int { length }

    @inline(__always)
    private func absolute(_ offset: Int) -> Int { start + offset }

    public func loadUInt8(at offset: Int) -> UInt8? {
        guard offset >= 0, offset + 1 <= length else { return nil }
        let abs = absolute(offset)
        return data.withUnsafeBytes {
            $0.load(fromByteOffset: abs, as: UInt8.self)
        }
    }

    public func loadUInt16(at offset: Int) -> UInt16? {
        guard offset >= 0, offset + 2 <= length else { return nil }
        let abs = absolute(offset)
        let v: UInt16 = loadUnaligned(UInt16.self, from: data, at: abs)
        return UInt16(bigEndian: v)
    }

    public func loadUInt32(at offset: Int) -> UInt32? {
        guard offset >= 0, offset + 4 <= length else { return nil }
        let abs = absolute(offset)
        let v: UInt32 = loadUnaligned(UInt32.self, from: data, at: abs)
        return UInt32(bigEndian: v)
    }

    public func slice(from offset: Int, length: Int) -> PacketBuffer? {
        guard offset >= 0, length >= 0, offset + length <= self.length else { return nil }
        return DataSlicePacketBuffer(data: data, start: start + offset, length: length)
    }

    public func materialize() -> Data {
        data.subdata(in: start ..< start + length)
    }
}
