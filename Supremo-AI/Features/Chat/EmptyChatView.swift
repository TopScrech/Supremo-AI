import SwiftUI

struct EmptyChatView: View {
    var body: some View {
        ContentUnavailableView(
            "No Chat Selected",
            systemImage: "bubble.left.and.bubble.right",
            description: Text("Create or select a chat")
        )
    }
}
