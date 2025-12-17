# Locate QA Checklist

Comprehensive testing checklist for Locate v1.0 before release.

## Test Environment

- [ ] macOS 12.0 (minimum supported version)
- [ ] macOS 13.x (Ventura)
- [ ] macOS 14.x (Sonoma)
- [ ] macOS 15.x (Sequoia)
- [ ] Intel Mac
- [ ] Apple Silicon Mac

## Installation & First Launch

### Fresh Install
- [ ] DMG opens without security warnings
- [ ] Drag to Applications works smoothly
- [ ] App launches successfully
- [ ] No Gatekeeper blocks ("App is damaged" message)
- [ ] Onboarding screen appears on first launch

### Onboarding Flow
- [ ] Welcome screen displays correctly
- [ ] Feature list is readable and accurate
- [ ] "Get Started" button advances to folder selection
- [ ] Can add folders via "Add Folder" button
- [ ] File picker allows multi-selection
- [ ] Selected folders display in list with icons
- [ ] Can remove folders before building index
- [ ] "Skip for Now" closes onboarding and marks as complete
- [ ] "Build Index" button disabled when no folders selected
- [ ] "Build Index" starts indexing
- [ ] Progress indicator shows during indexing
- [ ] Progress messages update correctly
- [ ] Complete screen appears after indexing
- [ ] "Start Searching" transitions to main UI
- [ ] Onboarding doesn't reappear on subsequent launches

## Core Search Functionality

### Basic Search
- [ ] Search field accepts input
- [ ] Search triggers automatically with debounce (~200-300ms)
- [ ] Results appear in scrollable table
- [ ] Empty query shows no results
- [ ] Special characters in search work correctly
- [ ] Search is case-insensitive by default
- [ ] Results show file name, path, size, and modified date
- [ ] File icons display correctly for different file types

### Search Performance
- [ ] Search completes in under 100ms for typical queries
- [ ] Large result sets (1000+ items) render smoothly
- [ ] Rapid typing doesn't cause lag or crashes
- [ ] Clearing search is instant

### Filters

#### File Type Filter
- [ ] "All" filter shows all files
- [ ] "Documents" filter shows only: pdf, doc, docx, txt, rtf, pages
- [ ] "Images" filter shows only: png, jpg, jpeg, gif, tiff, heic, webp
- [ ] "Code" filter shows only source code files
- [ ] Filter changes update results immediately
- [ ] Filter persists during session

#### Size Filter
- [ ] "Any Size" shows all files
- [ ] "> 1 MB" only shows files larger than 1MB
- [ ] "> 10 MB" only shows files larger than 10MB
- [ ] "> 100 MB" only shows files larger than 100MB
- [ ] Size filter works correctly with other filters

#### Date Filter
- [ ] "Any Date" shows all files
- [ ] "Last 24h" shows only files modified in last 24 hours
- [ ] "Last 7 days" shows only files modified in last week
- [ ] "Last 30 days" shows only files modified in last month
- [ ] Date calculations are accurate

### Advanced Features

#### Regex Mode
- [ ] Regex toggle is visible and clickable
- [ ] Valid regex patterns work correctly
- [ ] Invalid regex shows clear error message
- [ ] Regex error doesn't crash app
- [ ] Turning regex off returns to normal search
- [ ] Common patterns work: `\.pdf$`, `^test.*`, `\d{4}`

#### Case Sensitivity
- [ ] Case sensitive toggle is visible
- [ ] When off: "test" matches "Test", "TEST", "TeSt"
- [ ] When on: "test" only matches "test"
- [ ] Works with both normal and regex search

## File Actions

### Open File
- [ ] Double-click opens file in default app
- [ ] Return key opens selected file
- [ ] ⌘O opens selected file
- [ ] Directories open in Finder
- [ ] Error shown if file doesn't exist
- [ ] Multiple file types open correctly

### Reveal in Finder
- [ ] Right-click menu shows "Reveal in Finder"
- [ ] Selecting "Reveal in Finder" opens Finder
- [ ] File is selected/highlighted in Finder
- [ ] Works for files in different directories

### Copy Path
- [ ] Right-click menu shows "Copy Path"
- [ ] "Copy Path" puts full absolute path on clipboard
- [ ] Pasted path is correct and complete
- [ ] Works for files with spaces in path

## Indexing

### Build Index
- [ ] "Update Index" menu item exists (⌘R)
- [ ] Clicking triggers indexing
- [ ] Progress indicator appears
- [ ] Progress messages update
- [ ] Can search during indexing
- [ ] Button disabled while indexing
- [ ] Status bar updates after completion

### Index Settings (Settings > Indexed Folders)
- [ ] Settings window opens via menu (⌘,)
- [ ] Can add new folders
- [ ] Multi-selection in folder picker works
- [ ] Added folders appear in list immediately
- [ ] Can select folders in list
- [ ] Can remove selected folders
- [ ] Changes persist after app restart
- [ ] "Rebuild Index Now" processes all folders
- [ ] Empty folder list disables rebuild button

### Exclusions (Settings > Exclusions)
- [ ] Default exclusion patterns present
- [ ] Can add new exclusion pattern
- [ ] Enter key adds pattern
- [ ] Can select patterns in list
- [ ] Can remove selected patterns
- [ ] Changes persist after app restart
- [ ] New exclusions apply on next index rebuild
- [ ] Library, .git, node_modules correctly excluded

### Auto-Reindex (Settings > Indexing)
- [ ] Auto-reindex toggle works
- [ ] Interval slider adjusts from 1-24 hours
- [ ] Interval displays correctly
- [ ] Settings persist after restart
- [ ] Auto-reindex triggers at configured interval
- [ ] Index status displays correctly
- [ ] Last indexed time is accurate

## Privacy & Permissions

### Full Disk Access (Settings > Privacy)
- [ ] Displays current permission status
- [ ] Shows helpful explanation when not granted
- [ ] Lists protected locations correctly
- [ ] Instructions are clear and accurate
- [ ] "Open System Settings" button works
- [ ] "Check Again" updates status
- [ ] Status changes after granting permission

### FDA Banner
- [ ] Banner appears in main window if no FDA
- [ ] Banner is dismissible
- [ ] "Learn More" expands additional info
- [ ] "Open System Settings" button works
- [ ] Banner doesn't reappear when dismissed (session)

## UI & Navigation

### Main Window
- [ ] Window opens on launch
- [ ] Title bar shows "Locate"
- [ ] Window is resizable
- [ ] Minimum window size enforced
- [ ] Window state doesn't persist (always default size)
- [ ] ⌘W closes window
- [ ] Escape key closes window

### Menu Bar
- [ ] "File" menu exists
- [ ] "Edit" menu exists with "Find" (⌘F)
- [ ] "Window" menu exists
- [ ] "Help" menu exists
- [ ] "Locate" > "Preferences..." opens Settings (⌘,)
- [ ] "Locate" > "Quit" exits app (⌘Q)

### Menu Bar Extra
- [ ] Menu bar icon appears (magnifying glass)
- [ ] Clicking icon opens popover
- [ ] Popover shows search interface
- [ ] Search works in popover
- [ ] Results appear in popover
- [ ] Can open files from popover
- [ ] Popover closes on click outside
- [ ] Both main window and popover work simultaneously

### Global Hotkey
- [ ] ⌥Space registered on launch
- [ ] ⌥Space brings main window to front
- [ ] Works when app in background
- [ ] Works when other apps are focused
- [ ] Focuses search field when activated
- [ ] Console confirms successful registration

### Keyboard Shortcuts
- [ ] ⌘F focuses search field
- [ ] ⌘R triggers index rebuild
- [ ] ⌘, opens Settings
- [ ] ⌘Q quits app
- [ ] ⌘W closes window
- [ ] Escape closes window
- [ ] Return opens selected file
- [ ] ⌘O opens selected file
- [ ] Tab navigates between fields
- [ ] Arrow keys navigate results list

## Status & Feedback

### Status Bar
- [ ] Shows file and folder count after indexing
- [ ] Shows "Last indexed X minutes ago"
- [ ] Shows "No index yet" when appropriate
- [ ] Updates in real-time during indexing
- [ ] Time updates are relative and human-readable

### Error Handling
- [ ] File not found shows error message
- [ ] Database errors show user-friendly message
- [ ] Permission denied handled gracefully
- [ ] Invalid regex shows clear error
- [ ] App never crashes on errors

## Performance

### Indexing Performance
- [ ] 10k files index in under 30 seconds
- [ ] 100k files index in under 5 minutes
- [ ] Memory usage stays reasonable (<200MB during index)
- [ ] CPU usage is reasonable (not sustained 100%)
- [ ] App remains responsive during indexing

### Search Performance
- [ ] Typical search (<20 chars) under 50ms
- [ ] Complex regex under 200ms
- [ ] Large result sets (1000+ items) render quickly
- [ ] Memory usage stays under 50MB when idle
- [ ] No memory leaks during extended use

### Large Dataset Test
Test with 100k+ files:
- [ ] Index completes successfully
- [ ] Search performance acceptable (<100ms)
- [ ] Memory usage reasonable (<100MB idle)
- [ ] App responsive throughout
- [ ] Database file size reasonable

## Edge Cases & Error Conditions

### Data Edge Cases
- [ ] Files with Unicode names (emoji, CJK characters)
- [ ] Files with spaces in name
- [ ] Very long file names (>255 chars truncate gracefully)
- [ ] Very long paths (>1024 chars handled)
- [ ] Files with no extension
- [ ] Files with multiple dots (file.tar.gz)
- [ ] Hidden files (starting with .)

### Search Edge Cases
- [ ] Empty search query
- [ ] Only whitespace in query
- [ ] Very long search query (>1000 chars)
- [ ] Special regex characters: `.*+?[]{}()|^$\`
- [ ] SQL injection attempts (properly escaped)
- [ ] Search while index is empty

### System Edge Cases
- [ ] No disk space for database
- [ ] Database file corrupted (shows error, suggests rebuild)
- [ ] Indexed folder deleted (handled gracefully)
- [ ] Indexed folder permission changed (shows warning)
- [ ] External drive indexed then unmounted (shows warning)
- [ ] Very large files (>10GB) don't cause issues

## Cross-Feature Integration

### Settings + Search
- [ ] Changing indexed folders updates status bar
- [ ] Rebuilding index updates search results
- [ ] Filter changes work with all search types
- [ ] Settings changes persist across restarts

### Onboarding + Settings
- [ ] Folders added in onboarding appear in Settings
- [ ] Can modify onboarding selections in Settings
- [ ] "Skip" in onboarding can be redone via Settings

### Global Hotkey + Menu Bar
- [ ] Both access methods work independently
- [ ] Don't interfere with each other
- [ ] Share same search state

## Accessibility

- [ ] All UI elements have accessibility labels
- [ ] VoiceOver can navigate the app
- [ ] Keyboard-only navigation works
- [ ] Color contrast is sufficient
- [ ] Text is readable at default size
- [ ] No flashing or rapidly changing content

## Localization

- [ ] Dates formatted correctly for locale
- [ ] Numbers formatted correctly (1,000 vs 1.000)
- [ ] File sizes use appropriate units (MB vs MiB)
- [ ] Relative times in English ("2 minutes ago")

## Final Checks

- [ ] App icon shows in Dock
- [ ] App icon shows in Applications folder
- [ ] About panel shows correct version
- [ ] Copyright notice is current
- [ ] No debug logging in release build
- [ ] No test data in release build
- [ ] Performance is acceptable on minimum spec Mac
- [ ] Battery usage is reasonable on laptop

## Regression Tests (From Previous Builds)

- [ ] All Phase 1 core features still work
- [ ] All Phase 2 UI features still work
- [ ] All Phase 3 power features still work
- [ ] No new bugs introduced

## Notes

Record any issues found:
- Issue:
  - Steps to reproduce:
  - Expected behavior:
  - Actual behavior:
  - Severity: [Critical/High/Medium/Low]
