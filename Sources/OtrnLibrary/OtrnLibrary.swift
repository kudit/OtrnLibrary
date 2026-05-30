import Foundation

public struct OtrnReply: Codable, Identifiable {
    public let comment: String
    public let commenter: String?
    public let timestamp: String?
    public let replyId: UUID?

    public var id: UUID? { replyId }

    public init(comment: String, commenter: String? = nil, timestamp: String? = nil, replyId: UUID? = UUID()) {
        self.comment = comment
        self.commenter = commenter
        self.timestamp = timestamp
        self.replyId = replyId
    }
}

public struct OtrnTag: Codable, Identifiable {
    public let name: String
    public let tagId: UUID?
    public let group: String?

    public var id: UUID? { tagId }

    public init(name: String, tagId: UUID? = UUID(), group: String? = nil) {
        self.name = name
        self.tagId = tagId
        self.group = group
    }
}

public struct OtrnNote: Codable, Identifiable {
    public let time: Float
    public let comment: String

    public let timecode: String?
    public let frame: Int?

    public let range: Bool?
    public let timeOut: Float?
    public let timecodeOut: String?
    public let frameOut: Int?

    public let name: String?
    public let commenter: String?
    public let color: String?
    public let colorHex: String?
    public let category: String?
    public let track: String?
    public let complete: Bool
    public let timestamp: String?

    public let noteId: UUID
    public var id: UUID { noteId }

    public var replies: [OtrnReply]
    public var tags: [OtrnTag]

    public init(time: Float, comment: String, timecode: String? = nil, frame: Int? = nil, range: Bool = false, timeOut: Float? = nil, timecodeOut: String? = nil, frameOut: Int? = nil, name: String? = nil, commenter: String? = nil, color: String? = nil, colorHex: String? = nil, category: String? = nil, track: String? = nil, complete: Bool = false, timestamp: String? = nil, noteId: UUID = UUID(), replies: [OtrnReply] = [], tags: [OtrnTag] = []) {
        self.time = time
        self.comment = comment
        self.timecode = timecode
        self.frame = frame
        self.range = range
        self.timeOut = timeOut
        self.timecodeOut = timecodeOut
        self.frameOut = frameOut
        self.name = name
        self.commenter = commenter
        self.color = color
        self.colorHex = colorHex
        self.category = category
        self.track = track
        self.complete = complete
        self.timestamp = timestamp
        self.noteId = noteId
        self.replies = replies
        self.tags = tags
    }
}

public struct OtrnSequence: Codable {
    public let name: String?
    public let frameRate: Float?
    public let dropFrame: Bool

    public let startTime: Float
    public let startTimecode: String
    public let startFrame: Int

    public var notes: [OtrnNote]

    public init(name: String? = nil, frameRate: Float? = nil, dropFrame: Bool = false, startTime: Float = 0.0, startTimecode: String = "00:00:00:00", startFrame: Int = 0, notes: [OtrnNote] = []) {
        self.name = name
        self.frameRate = frameRate
        self.dropFrame = dropFrame
        self.startTime = startTime
        self.startTimecode = startTimecode
        self.startFrame = startFrame
        self.notes = notes
    }
}

public struct OtrnFile: Codable {
    public let fileName: String
    public let filePath: String

    public let clipName: String?

    public let name: String?
    public let frameRate: Float?
    public let dropFrame: Bool
    public let startTime: Float
    public let startTimecode: String
    public let startFrame: Int
    public var notes: [OtrnNote]

    public init(fileName: String, filePath: String, clipName: String? = nil, name: String? = nil, frameRate: Float? = nil, dropFrame: Bool = false, startTime: Float = 0.0, startTimecode: String = "00:00:00:00", startFrame: Int = 0, notes: [OtrnNote] = []) {
        self.fileName = fileName
        self.filePath = filePath
        self.clipName = clipName
        self.name = name
        self.frameRate = frameRate
        self.dropFrame = dropFrame
        self.startTime = startTime
        self.startTimecode = startTimecode
        self.startFrame = startFrame
        self.notes = notes
    }
}

public struct OtrnMetadata: Codable {
    public let project: String?
    public let fileName: String?
    public let fileUrl: String?
    public let software: String?
    public let otrnVersion: Int
    public let otrnInfo: String?
    public let timestamp: String?

    public static var defaultTimestamp: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withTimeZone]
        return formatter.string(from: Date())
    }

    public init(project: String? = nil, fileName: String? = nil, fileUrl: String? = nil, software: String? = nil, otrnVersion: Int = 1, otrnInfo: String? = "This is an OTRN (Open Timecode-Related Notes) notes file. Learn more about the specification on https://otrn.editingtools.io", timestamp: String? = OtrnMetadata.defaultTimestamp) {
        self.project = project
        self.fileName = fileName
        self.fileUrl = fileUrl
        self.software = software
        self.otrnVersion = otrnVersion
        self.otrnInfo = otrnInfo
        self.timestamp = timestamp
    }
}

public struct OtrnDocument: Codable {
    public let metadata: OtrnMetadata
    public var sequence: OtrnSequence
    public let files: [OtrnFile]?

    public init(metadata: OtrnMetadata = OtrnMetadata(), sequence: OtrnSequence = OtrnSequence(), files: [OtrnFile]? = nil) {
        self.metadata = metadata
        self.sequence = sequence
        self.files = files
    }

    private enum CodingKeys: String, CodingKey {
        case metadata, sequence, files
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(metadata, forKey: .metadata)
        try container.encode(sequence, forKey: .sequence)

        if let files = files, !files.isEmpty {
            try container.encode(files, forKey: .files)
        }
    }
}

extension OtrnDocument {
    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        return encoder
    }

    public static func read(from filepath: String) throws -> OtrnDocument {
        let url = URL(fileURLWithPath: filepath)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()

        do {
            let document = try decoder.decode(OtrnDocument.self, from: data)
            print("[\(filepath)] successfully loaded OTRN document.")
            return document
        } catch {
            print("[\(filepath)] error decoding OTRN document: \(error.localizedDescription)")
            throw error
        }
    }

    public func write(to filepath: String) throws {
        let url = URL(fileURLWithPath: filepath)
        let encoder = OtrnDocument.makeEncoder()

        do {
            let jsonData = try encoder.encode(self)
            try jsonData.write(to: url, options: .atomic)
            print("[\(filepath)] successfully wrote OTRN document.")
        } catch {
            print("[\(filepath)] error encoding or writing OTRN document: \(error.localizedDescription)")
            throw error
        }
    }
}
