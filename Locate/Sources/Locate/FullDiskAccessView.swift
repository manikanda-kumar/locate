import SwiftUI
import LocateViewModel

struct FullDiskAccessGuideView: View {
    @State private var hasAccess = PermissionsHelper.hasFullDiskAccess()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: hasAccess ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(hasAccess ? .green : .orange)

                VStack(alignment: .leading, spacing: 8) {
                    Text(hasAccess ? "Full Disk Access Granted" : "Full Disk Access Required")
                        .font(.title)
                        .fontWeight(.bold)

                    Text(hasAccess ? "Locate can access all files on your Mac" : "Grant access to search all files")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if !hasAccess {
                Divider()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Why Full Disk Access?")
                        .font(.headline)

                    Text("macOS protects certain system and user directories. Full Disk Access allows Locate to index and search all your files, including:")
                        .font(.body)

                    VStack(alignment: .leading, spacing: 8) {
                        ProtectedLocationRow(icon: "folder.fill", text: "~/Library folder")
                        ProtectedLocationRow(icon: "mail.fill", text: "Mail attachments")
                        ProtectedLocationRow(icon: "safari.fill", text: "Downloads from Safari")
                        ProtectedLocationRow(icon: "calendar", text: "Calendar attachments")
                    }
                    .padding(.leading, 16)
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("How to Enable")
                        .font(.headline)

                    InstructionStep(number: 1, text: "Click 'Open System Settings' below")
                    InstructionStep(number: 2, text: "Find 'Locate' in the list (you may need to scroll)")
                    InstructionStep(number: 3, text: "Toggle the switch next to 'Locate' to ON")
                    InstructionStep(number: 4, text: "Restart Locate for changes to take effect")
                }

                HStack {
                    Button("Open System Settings") {
                        PermissionsHelper.openSystemPreferences()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Check Again") {
                        hasAccess = PermissionsHelper.hasFullDiskAccess()
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }
                .padding(.top, 8)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("You're all set! Locate can search all your files.")
                            .font(.body)
                    }

                    Text("If you're having trouble accessing specific folders, make sure they're added to your indexed folders in the Settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(24)
    }
}

struct ProtectedLocationRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number).")
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
                .frame(width: 24, alignment: .leading)

            Text(text)
                .font(.body)
        }
    }
}

struct FullDiskAccessBanner: View {
    @State private var isExpanded = false
    @State private var isDismissed = false

    var body: some View {
        if !isDismissed && !PermissionsHelper.hasFullDiskAccess() {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)

                    Text("Locate needs Full Disk Access to search all files")
                        .font(.subheadline)

                    Spacer()

                    Button("Learn More") {
                        isExpanded.toggle()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        isDismissed = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))

                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Without Full Disk Access, Locate cannot index:")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Files in ~/Library")
                            Text("• System directories")
                            Text("• Some application data")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Button("Open System Settings") {
                            PermissionsHelper.openSystemPreferences()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.05))
                }
            }
        }
    }
}
