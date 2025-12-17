import Foundation
import Observation

@MainActor
@Observable
public final class AppSettings {
    public static let shared = AppSettings()

    private let defaults = UserDefaults.standard
    private let indexedFoldersKey = "indexedFolders"
    private let exclusionPatternsKey = "exclusionPatterns"
    private let autoReindexKey = "autoReindex"
    private let reindexIntervalKey = "reindexInterval"
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    public var indexedFolders: [String] {
        didSet {
            defaults.set(indexedFolders, forKey: indexedFoldersKey)
        }
    }

    public var exclusionPatterns: [String] {
        didSet {
            defaults.set(exclusionPatterns, forKey: exclusionPatternsKey)
        }
    }

    public var autoReindex: Bool {
        didSet {
            defaults.set(autoReindex, forKey: autoReindexKey)
        }
    }

    public var reindexIntervalHours: Double {
        didSet {
            defaults.set(reindexIntervalHours, forKey: reindexIntervalKey)
        }
    }

    public var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: hasCompletedOnboardingKey)
        }
    }

    private init() {
        // Load persisted values or use defaults
        self.indexedFolders = defaults.stringArray(forKey: indexedFoldersKey) ?? []
        self.exclusionPatterns = defaults.stringArray(forKey: exclusionPatternsKey) ?? [
            "Library",
            ".git",
            "node_modules",
            ".Trash",
            ".npm",
            ".cargo",
            ".gradle",
            "build",
            "DerivedData"
        ]
        self.autoReindex = defaults.bool(forKey: autoReindexKey)
        self.reindexIntervalHours = defaults.double(forKey: reindexIntervalKey).isZero ? 6.0 : defaults.double(forKey: reindexIntervalKey)
        self.hasCompletedOnboarding = defaults.bool(forKey: hasCompletedOnboardingKey)
    }

    public func addIndexedFolder(_ path: String) {
        guard !indexedFolders.contains(path) else { return }
        indexedFolders.append(path)
    }

    public func removeIndexedFolders(_ paths: Set<String>) {
        indexedFolders.removeAll { paths.contains($0) }
    }

    public func addExclusionPattern(_ pattern: String) {
        guard !exclusionPatterns.contains(pattern) else { return }
        exclusionPatterns.append(pattern)
    }

    public func removeExclusionPatterns(_ patterns: Set<String>) {
        exclusionPatterns.removeAll { patterns.contains($0) }
    }
}
