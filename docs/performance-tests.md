# Performance and Memory Testing Guide

Guide for testing Locate with large datasets and monitoring resource usage.

## Test Goals

Verify that Locate meets performance targets:
- **Indexing:** Index 10k files in under 30 seconds
- **Search:** Return results in under 100ms for typical queries
- **Memory:** Stay under 50MB when idle, under 200MB during indexing
- **Responsiveness:** UI remains responsive during all operations

## Test Datasets

### Small Dataset (~10,000 files)
Best for initial testing and baseline measurements.

**Create test data:**
```bash
# Generate 10,000 test files in a test directory
mkdir -p ~/LocateTest/small
cd ~/LocateTest/small

for i in {1..10000}; do
    cat=$(( $i % 10 ))
    size=$(( $RANDOM % 100000 ))
    echo "File $i content" > "test_file_${cat}_${i}.txt"
done

# Add some variety
for i in {1..1000}; do
    echo "Document $i" > "document_${i}.pdf"
    echo "Image $i" > "image_${i}.png"
    echo "Code $i" > "script_${i}.swift"
done
```

### Medium Dataset (~50,000 files)
Realistic dataset for typical user.

**Use actual directories:**
- ~/Documents
- ~/Downloads
- ~/Desktop
- ~/Developer (if exists)

### Large Dataset (~100,000+ files)
Stress test for power users.

**Generate large dataset:**
```bash
mkdir -p ~/LocateTest/large
cd ~/LocateTest/large

for dir in {1..10}; do
    mkdir -p "category_$dir"
    cd "category_$dir"

    for i in {1..10000}; do
        echo "Content $i" > "file_${dir}_${i}.dat"
    done

    cd ..
done
```

Or use real heavy directories:
- Entire home directory
- Developer projects with node_modules
- Large photo/video libraries

## Indexing Performance Tests

### Test 1: Small Dataset Index Time

**Steps:**
1. Clean index: `rm -rf ~/Library/Application\ Support/Locate/locate.db`
2. Launch Locate
3. Add ~/LocateTest/small to indexed folders
4. Start timer
5. Click "Rebuild Index Now"
6. Stop timer when "Completed" appears

**Expected Results:**
- 10k files: < 30 seconds
- Progress updates appear regularly
- UI remains responsive
- Memory usage < 200MB

**Record:**
- Time taken: _____ seconds
- Final file count: _____
- Peak memory usage: _____ MB
- CPU usage: _____ %

### Test 2: Medium Dataset Index Time

**Steps:**
Same as Test 1, but with ~/Documents, ~/Downloads, etc.

**Expected Results:**
- 50k files: < 2 minutes
- Batch progress visible
- No freezing or hangs

**Record:**
- Time taken: _____ seconds
- Final file count: _____
- Peak memory usage: _____ MB
- CPU usage: _____ %

### Test 3: Large Dataset Index Time

**Steps:**
Same as Test 1, but with 100k+ files

**Expected Results:**
- 100k files: < 5 minutes
- Memory stays reasonable
- Can still use app during indexing

**Record:**
- Time taken: _____ seconds
- Final file count: _____
- Peak memory usage: _____ MB
- Database file size: _____ MB

### Test 4: Re-index Performance

**Steps:**
1. With existing index, click "Rebuild Index Now"
2. Measure time to completion

**Expected Results:**
- Similar to initial index
- Old entries properly deleted

**Record:**
- Time taken: _____ seconds
- Memory usage: _____ MB

## Search Performance Tests

### Test 5: Simple Name Search

**Setup:** Index containing 100k+ files

**Test Queries:**
```
test
document
image
readme
config
```

**For each query:**
1. Clear search
2. Type query
3. Measure time to first result
4. Check memory usage

**Expected Results:**
- First result: < 50ms
- Full results: < 100ms
- No UI lag

**Record per query:**
| Query    | Time to Results | Result Count | Memory |
|----------|----------------|--------------|--------|
| test     |                |              |        |
| document |                |              |        |
| image    |                |              |        |

### Test 6: Filtered Search

**Test combinations:**
```
Query: "test"
- + File type: Code
- + Size: > 1MB
- + Date: Last 7 days
- All three filters combined
```

**Expected Results:**
- With 1 filter: < 100ms
- With all filters: < 150ms

**Record:**
| Filters    | Time | Result Count |
|------------|------|--------------|
| None       |      |              |
| Type       |      |              |
| Size       |      |              |
| Date       |      |              |
| All three  |      |              |

### Test 7: Regex Search Performance

**Test patterns:**
```
^\d{4}           # Year prefix
\.pdf$           # PDF files only
(test|prod)      # OR pattern
file\d{3,5}      # Numbered files
[A-Z]{2,3}_\d+   # Code pattern
```

**Expected Results:**
- Simple regex: < 100ms
- Complex regex: < 200ms

**Record:**
| Pattern         | Time | Result Count |
|-----------------|------|--------------|
| ^\d{4}          |      |              |
| \.pdf$          |      |              |
| (test\|prod)    |      |              |

### Test 8: Large Result Set

**Setup:** Query that returns 1000+ results

**Steps:**
1. Type query that matches many files
2. Measure render time
3. Scroll through results
4. Select items

**Expected Results:**
- Initial render: < 200ms
- Smooth scrolling (60fps)
- Selection responsive

**Record:**
- Result count: _____
- Render time: _____ ms
- Scrolling FPS: _____
- Memory usage: _____ MB

### Test 9: Rapid Search Changes

**Steps:**
1. Type "test"
2. Immediately change to "testing"
3. Immediately change to "testfile"
4. Repeat 10 times rapidly

**Expected Results:**
- No crashes
- Results always match current query
- Debouncing works correctly

**Record:**
- Any lag or freeze: Y/N
- Results accuracy: _____/10 correct

## Memory Tests

### Test 10: Idle Memory Usage

**Steps:**
1. Launch app
2. Complete onboarding
3. Wait 1 minute
4. Check memory in Activity Monitor

**Expected Results:**
- < 50MB idle memory
- No memory leaks over time

**Record:**
- Memory at launch: _____ MB
- Memory after 1 min: _____ MB
- Memory after 5 min: _____ MB
- Memory after 30 min: _____ MB

### Test 11: Active Usage Memory

**Steps:**
1. Perform 100 searches
2. Open 50 files
3. Rebuild index twice
4. Check memory

**Expected Results:**
- Memory stays reasonable
- No continuous growth
- Returns to baseline when idle

**Record:**
- Memory after tests: _____ MB
- Memory after 5 min idle: _____ MB

### Test 12: Memory Leak Test

**Steps:**
1. Run overnight with auto-reindex enabled (every 1 hour)
2. Check memory in morning
3. Compare to baseline

**Expected Results:**
- Memory similar to baseline
- No continuous growth

**Record:**
- Start memory: _____ MB
- End memory (after 8 hours): _____ MB
- Number of reindexes: _____

## Database Tests

### Test 13: Database Size

**Steps:**
1. Index various dataset sizes
2. Check database file size
3. Check if size is proportional to file count

**Expected Results:**
- Reasonable overhead (~100-200 bytes per file)
- SQLite vacuum works

**Record:**
| File Count | DB Size | Bytes per File |
|------------|---------|----------------|
| 10k        |         |                |
| 50k        |         |                |
| 100k       |         |                |

### Test 14: Database Corruption Recovery

**Steps:**
1. Create index
2. Corrupt database file (truncate)
3. Try to search
4. Rebuild index

**Expected Results:**
- Error message shown
- App doesn't crash
- Rebuild fixes issue

**Record:**
- Error handling: Good / Fair / Poor
- Data recovery: Success / Fail

## Stress Tests

### Test 15: Concurrent Operations

**Steps:**
1. Start index rebuild
2. Open main window and search
3. Open menu bar and search
4. Trigger global hotkey
5. Open settings
6. All simultaneously

**Expected Results:**
- No crashes
- All operations complete
- No data corruption

**Record:**
- Crashes: Y/N
- Errors: Y/N
- Performance degradation: Y/N

### Test 16: Resource Limits

**Test scenarios:**
- Full disk (< 100MB free)
- Low memory (< 1GB available)
- Many apps running (> 100)
- External drive disconnect during index

**Expected Results:**
- Graceful error handling
- Clear error messages
- No data loss

**Record observations:**

### Test 17: Long Running Test

**Steps:**
1. Enable auto-reindex (every 1 hour)
2. Leave app running for 24 hours
3. Monitor periodically

**Expected Results:**
- No crashes
- Memory stable
- Auto-reindex works
- UI remains responsive

**Record:**
- Uptime: _____ hours
- Number of auto-reindexes: _____
- Final memory: _____ MB
- Any issues: _____

## Performance Summary

**Test Date:** _________
**Environment:**
- Mac Model: _________
- macOS Version: _________
- RAM: _________
- Storage Type: SSD / HDD

**Results Summary:**

| Metric              | Target   | Actual   | Pass/Fail |
|---------------------|----------|----------|-----------|
| Index 10k files     | < 30s    |          |           |
| Simple search       | < 100ms  |          |           |
| Regex search        | < 200ms  |          |           |
| Idle memory         | < 50MB   |          |           |
| Active memory       | < 200MB  |          |           |
| UI responsiveness   | No lag   |          |           |

**Critical Issues:**

**Performance Bottlenecks:**

**Optimization Recommendations:**

## Tools

### Activity Monitor
- Monitor memory usage
- Check CPU usage
- Watch for memory leaks

### Instruments
- Time Profiler: Find slow code
- Allocations: Track memory usage
- Leaks: Detect memory leaks
- File Activity: Monitor I/O

### Console.app
- View app logs
- Check for errors
- Monitor system messages

### Terminal Commands

Check memory:
```bash
ps aux | grep Locate
```

Monitor continuously:
```bash
watch -n 1 'ps aux | grep Locate'
```

Database size:
```bash
ls -lh ~/Library/Application\ Support/Locate/locate.db
```

Database statistics:
```bash
sqlite3 ~/Library/Application\ Support/Locate/locate.db "SELECT COUNT(*) FROM files;"
```
