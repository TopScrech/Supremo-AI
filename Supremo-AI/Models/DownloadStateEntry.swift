import Foundation

@Observable
final class DownloadStateEntry {
    var state: DownloadState?
    
    init(state: DownloadState? = nil) {
        self.state = state
    }
}
