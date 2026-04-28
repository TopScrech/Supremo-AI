import Foundation
import OSLog

#if os(iOS)
import BackgroundTasks

final class BackgroundModelDownloadScheduler {
    static let shared = BackgroundModelDownloadScheduler()
    static let taskIdentifierPrefix = "\(Bundle.main.bundleIdentifier ?? "dev.topscrech.Supremo-AI").model-download."

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Supremo-AI", category: "BackgroundModelDownloadScheduler")

    private init() {}

    func schedule(
        title: String,
        subtitle: String,
        handler: @escaping @MainActor @Sendable (Progress) async -> Bool
    ) {
        guard #available(iOS 26.0, *) else {
            Task { @MainActor in
                _ = await handler(Progress(totalUnitCount: 1))
            }
            return
        }

        let taskID = Self.taskIdentifierPrefix + UUID().uuidString
        registerContinuedProcessingTask(taskID: taskID, handler: handler)
        submitContinuedProcessingTask(taskID: taskID, title: title, subtitle: subtitle)
    }

    @available(iOS 26.0, *)
    private func registerContinuedProcessingTask(
        taskID: String,
        handler: @escaping @MainActor @Sendable (Progress) async -> Bool
    ) {
        let didRegister = BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            guard let task = task as? BGContinuedProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }

            let work = Task { @MainActor in
                let success = await handler(task.progress)
                task.setTaskCompleted(success: success)
                self.logger.info("Completed model download continued processing: \(success)")
            }

            task.expirationHandler = {
                work.cancel()
            }
        }

        if !didRegister {
            logger.error("Failed to register model download continued processing task")
        }
    }

    @available(iOS 26.0, *)
    private func submitContinuedProcessingTask(taskID: String, title: String, subtitle: String) {
        let request = BGContinuedProcessingTaskRequest(identifier: taskID, title: title, subtitle: subtitle)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            logger.error("Failed to submit model download continued processing task: \(error.localizedDescription, privacy: .public)")
        }
    }
}
#else
final class BackgroundModelDownloadScheduler {
    static let shared = BackgroundModelDownloadScheduler()
    static let taskIdentifierPrefix = "dev.topscrech.Supremo-AI.model-download."

    private init() {}

    func schedule(
        title: String,
        subtitle: String,
        handler: @escaping @MainActor @Sendable (Progress) async -> Bool
    ) {
        Task { @MainActor in
            _ = await handler(Progress(totalUnitCount: 1))
        }
    }
}
#endif
