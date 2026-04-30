import Foundation

struct GGUFMetadataReader {
    private enum ValueType: UInt32 {
        case uint8, int8, uint16, int16, uint32, int32, float32, bool, string, array, uint64, int64, float64
    }

    private var data: Data
    private var offset = 0

    init(_ data: Data) {
        self.data = data
    }

    mutating func promptTemplate() throws -> String? {
        guard try readBytes(count: 4) == Data("GGUF".utf8) else { return nil }
        _ = try readUInt32()
        _ = try readUInt64()
        let keyValueCount = try readUInt64()

        for _ in 0..<keyValueCount {
            let key = try readString()
            let type = try readValueType()

            if (key == "tokenizer.chat_template" || key == "chat_template"), type == .string {
                return try readString()
            }

            try skipValue(type)
        }

        return nil
    }

    private mutating func readValueType() throws -> ValueType {
        guard let valueType = ValueType(rawValue: try readUInt32()) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        return valueType
    }

    private mutating func readString() throws -> String {
        let length = try readUInt64()
        let bytes = try readBytes(count: length)

        guard let string = String(data: bytes, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        return string
    }

    private mutating func skipValue(_ type: ValueType) throws {
        switch type {
        case .uint8, .int8, .bool:
            try skipBytes(count: 1)
            
        case .uint16, .int16:
            try skipBytes(count: 2)
            
        case .uint32, .int32, .float32:
            try skipBytes(count: 4)
            
        case .uint64, .int64, .float64:
            try skipBytes(count: 8)
            
        case .string:
            _ = try readString()
            
        case .array:
            let elementType = try readValueType()
            let elementCount = try readUInt64()

            for _ in 0..<elementCount {
                try skipValue(elementType)
            }
        }
    }

    private mutating func readUInt32() throws -> UInt32 {
        UInt32(try readInteger(byteCount: 4))
    }

    private mutating func readUInt64() throws -> Int {
        let value = try readInteger(byteCount: 8)
        guard value <= UInt64(Int.max) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        return Int(value)
    }

    private mutating func readInteger(byteCount: Int) throws -> UInt64 {
        let bytes = try readBytes(count: byteCount)
        var value: UInt64 = 0

        for (index, byte) in bytes.enumerated() {
            value |= UInt64(byte) << UInt64(index * 8)
        }

        return value
    }

    private mutating func readBytes(count: Int) throws -> Data {
        guard count >= 0, offset + count <= data.count else {
            throw CocoaError(.fileReadTooLarge)
        }

        let range = offset..<(offset + count)
        offset += count
        
        return data.subdata(in: range)
    }

    private mutating func skipBytes(count: Int) throws {
        guard count >= 0, offset + count <= data.count else {
            throw CocoaError(.fileReadTooLarge)
        }

        offset += count
    }
}
