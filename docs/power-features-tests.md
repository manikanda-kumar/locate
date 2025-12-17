# Power Features Regression Tests

Focused testing checklist for Phase 3 power features (regex, case sensitivity, menu bar, global hotkey).

## Regex Search

### Basic Regex Patterns
- [ ] `.` matches any character: `test.txt` matches `test1txt`, `test.txt`
- [ ] `*` matches zero or more: `test*.txt` matches `testtxt`, `test123.txt`
- [ ] `+` matches one or more: `test+.txt` requires at least one 't'
- [ ] `?` matches zero or one: `tests?.txt` matches `test.txt` and `tests.txt`
- [ ] `^` matches start: `^test` only matches files starting with "test"
- [ ] `$` matches end: `\.pdf$` only matches files ending in .pdf

### Character Classes
- [ ] `[abc]` matches any of a, b, or c
- [ ] `[^abc]` matches anything except a, b, or c
- [ ] `[a-z]` matches any lowercase letter
- [ ] `[A-Z]` matches any uppercase letter
- [ ] `[0-9]` matches any digit
- [ ] `\d` matches digits (shorthand)
- [ ] `\w` matches word characters
- [ ] `\s` matches whitespace

### Quantifiers
- [ ] `{3}` matches exactly 3 times
- [ ] `{3,}` matches 3 or more times
- [ ] `{3,5}` matches between 3 and 5 times
- [ ] `file\d{4}` matches file0001, file2024
- [ ] `test{2,4}` matches testt, testtt, testttt

### Grouping & Alternation
- [ ] `(test|prod)` matches files with "test" OR "prod"
- [ ] `(IMG|DSC)_\d+` matches IMG_1234 or DSC_5678
- [ ] `report_(2024|2025)` matches report_2024 and report_2025

### Real-World Patterns
- [ ] `^\d{4}-\d{2}-\d{2}` matches date-prefixed files (2024-01-15)
- [ ] `\.(jpg|jpeg|png|gif)$` matches image files
- [ ] `backup_.*\.tar\.gz$` matches compressed backup files
- [ ] `^[A-Z]{2,3}_\d+` matches codes like IMG_001, DSC_12345
- [ ] `^\.` matches hidden files (starting with dot)

### Invalid Regex Handling
- [ ] `(unclosed` shows error "unclosed parenthesis"
- [ ] `[unclosed` shows error about unclosed bracket
- [ ] `*invalid` shows error about invalid quantifier
- [ ] `(?invalid)` shows error about invalid group
- [ ] Error message is clear and doesn't crash app
- [ ] Can fix regex and search continues working

### Regex + Filters
- [ ] Regex works with file type filter
- [ ] Regex works with size filter
- [ ] Regex works with date filter
- [ ] All three filters + regex work together
- [ ] Results are correct intersection of all filters

## Case Sensitivity

### Case Insensitive (Default)
- [ ] "test" matches "test", "Test", "TEST", "TeSt"
- [ ] "PDF" matches "pdf", "PDF", "Pdf"
- [ ] Works with file names: "readme" matches "README.md"
- [ ] Works with extensions: searching "jpg" finds ".JPG" files

### Case Sensitive
- [ ] "test" only matches "test", not "Test"
- [ ] "PDF" only matches "PDF", not "pdf"
- [ ] "README" doesn't match "readme.md"
- [ ] ".JPG" doesn't match ".jpg"

### Case Sensitivity + Regex
- [ ] Case insensitive: `^test` matches "Test", "TEST"
- [ ] Case sensitive: `^test` only matches "test"
- [ ] Character classes respect setting: `[a-z]` with case sensitive
- [ ] `\d` works same in both modes (digits have no case)

### Edge Cases
- [ ] Unicode characters (café vs CAFÉ)
- [ ] Emoji (not affected by case sensitivity)
- [ ] Numbers (not affected)
- [ ] Special characters (not affected)

## Menu Bar Extra

### Appearance
- [ ] Icon appears in menu bar
- [ ] Icon is clearly visible in both light and dark mode
- [ ] Icon matches macOS menu bar style
- [ ] Icon has reasonable size

### Popover Interaction
- [ ] Clicking icon opens popover
- [ ] Popover appears below menu bar icon
- [ ] Popover has reasonable size (not too small/large)
- [ ] Clicking outside popover closes it
- [ ] Clicking icon again closes popover
- [ ] Escape key closes popover

### Search in Popover
- [ ] Search field is visible and focused on open
- [ ] Typing performs search
- [ ] Results appear in compact list
- [ ] File icons show in results
- [ ] Can scroll through many results
- [ ] Clicking result opens file
- [ ] Opening file closes popover

### Popover + Main Window
- [ ] Both can be open simultaneously
- [ ] Searches in each are independent
- [ ] Opening file from popover doesn't affect main window
- [ ] Closing popover doesn't close main window
- [ ] Main window hotkey works while popover is open

### Popover Limitations
- [ ] Filters visible (or intentionally hidden)
- [ ] Advanced options accessible (or intentionally simplified)
- [ ] Context menu available for results
- [ ] Keyboard navigation works

## Global Hotkey (⌥Space)

### Registration
- [ ] Hotkey registers on app launch
- [ ] Console message confirms registration
- [ ] Registration failure handled gracefully
- [ ] Hotkey unregisters on app quit

### Activation from Different States
- [ ] Works when app is in background
- [ ] Works when app is hidden
- [ ] Works when other apps are focused
- [ ] Works when Terminal/iTerm is focused
- [ ] Works when browser is focused
- [ ] Works when Finder is focused
- [ ] Works in full-screen app (brings out of full-screen)

### Window Behavior
- [ ] Brings main window to front
- [ ] Makes app active
- [ ] Focuses search field
- [ ] Clears previous search (optional behavior to verify)
- [ ] Window appears in center (or last position)

### Search Field Focus
- [ ] Search field is focused after hotkey
- [ ] Can immediately start typing
- [ ] Previous search selected/cleared appropriately
- [ ] Cursor in correct position

### Edge Cases
- [ ] Hotkey while indexing (should still work)
- [ ] Hotkey rapid press (doesn't cause issues)
- [ ] Hotkey while another dialog is open
- [ ] Hotkey with modified keyboard layouts (e.g., Dvorak)
- [ ] Conflicts with other app hotkeys (document behavior)

### Alternative Activation Methods
- [ ] Dock icon still works
- [ ] Applications folder launch still works
- [ ] Spotlight launch still works
- [ ] All methods focus search field

## Integration Tests

### Regex + Case Sensitivity
- [ ] Insensitive regex: `test` matches "Test"
- [ ] Sensitive regex: `[a-z]+` doesn't match "TEST"
- [ ] Both modes produce correct results
- [ ] Switching modes updates results immediately

### Regex + Menu Bar
- [ ] Can use regex in menu bar popover
- [ ] Invalid regex shows error in popover
- [ ] Regex state independent between windows

### Global Hotkey + Menu Bar
- [ ] Hotkey doesn't trigger menu bar
- [ ] Menu bar icon still works after using hotkey
- [ ] Both can search different queries

### All Power Features Together
- [ ] Hotkey → Main window → Regex + Case sensitive search
- [ ] Menu bar → Regex search with filters
- [ ] Switch between modes rapidly (no crashes)
- [ ] Settings persist across all access methods

## Performance with Power Features

### Regex Performance
- [ ] Simple regex (<20 char pattern) under 100ms
- [ ] Complex regex under 200ms
- [ ] Regex on large dataset (100k files) acceptable
- [ ] Invalid regex doesn't hang app

### Menu Bar Performance
- [ ] Popover opens instantly (<100ms)
- [ ] Search in popover is fast as main window
- [ ] Doesn't slow down main window
- [ ] Memory usage reasonable with both open

### Hotkey Performance
- [ ] Activation is instant (<100ms)
- [ ] No delay in window appearing
- [ ] Doesn't interfere with typing

## State & Persistence

### Settings Persistence
- [ ] Regex mode persists across sessions
- [ ] Case sensitivity persists across sessions
- [ ] Menu bar state persists (if configurable)
- [ ] Hotkey registration persists

### State Independence
- [ ] Main window state independent of menu bar
- [ ] Settings changes affect both interfaces
- [ ] Database shared between all access points
- [ ] No race conditions with concurrent searches

## Error Recovery

### Regex Errors
- [ ] Error shown inline
- [ ] Error doesn't crash app
- [ ] Can fix error and continue
- [ ] Error clears when valid

### Hotkey Conflicts
- [ ] If hotkey taken by another app, shows message
- [ ] Graceful fallback (app still works)
- [ ] Can try re-registering

### Menu Bar Issues
- [ ] If menu bar icon fails, app still works
- [ ] Can access features via main window
- [ ] Error logged but not shown to user

## Accessibility

### Keyboard-Only Usage
- [ ] Can toggle regex without mouse
- [ ] Can toggle case sensitivity without mouse
- [ ] Menu bar accessible via keyboard (system shortcut)
- [ ] All hotkey features work obviously

### VoiceOver
- [ ] Regex toggle announced correctly
- [ ] Case sensitivity toggle announced
- [ ] Search mode changes announced
- [ ] Error messages are read

## Results

**Test Date:** _________
**Tester:** _________
**Environment:**
- macOS Version: _________
- Mac Model: _________
- Build Version: _________

**Pass Rate:** _____ / _____ tests passed

**Critical Issues:**

**Known Limitations:**

**Notes:**
