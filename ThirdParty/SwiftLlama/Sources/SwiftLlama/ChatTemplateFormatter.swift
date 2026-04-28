import Foundation
import llama

public enum ChatTemplateFormatter {
    public static func format(template: String, systemPrompt: String, userPrompt: String) -> String? {
        let trimmedSystemPrompt = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)

        return template.withCString { templatePointer in
            "user".withCString { userRolePointer in
                userPrompt.withCString { userContentPointer in
                    if trimmedSystemPrompt.isEmpty {
                        var messages = [
                            llama_chat_message(role: userRolePointer, content: userContentPointer)
                        ]

                        return appliedTemplate(templatePointer, messages: &messages)
                    } else {
                        return "system".withCString { systemRolePointer in
                            trimmedSystemPrompt.withCString { systemContentPointer in
                                var messages = [
                                    llama_chat_message(role: systemRolePointer, content: systemContentPointer),
                                    llama_chat_message(role: userRolePointer, content: userContentPointer)
                                ]

                                return appliedTemplate(templatePointer, messages: &messages)
                            }
                        }
                    }
                }
            }
        }
    }

    private static func appliedTemplate(_ templatePointer: UnsafePointer<CChar>, messages: inout [llama_chat_message]) -> String? {
        let characterCount = messages.reduce(0) {
            $0 + (String(cString: $1.content).utf8.count)
        }
        var buffer = [CChar](repeating: 0, count: max(characterCount * 4, 4096))
        var result = llama_chat_apply_template(templatePointer, &messages, messages.count, true, &buffer, Int32(buffer.count))

        if result < 0 {
            return nil
        }

        if result > buffer.count {
            buffer = [CChar](repeating: 0, count: Int(result))
            result = llama_chat_apply_template(templatePointer, &messages, messages.count, true, &buffer, Int32(buffer.count))
        }

        guard result > 0, result <= buffer.count else { return nil }
        let bytes = buffer.prefix(Int(result)).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
    }
}
