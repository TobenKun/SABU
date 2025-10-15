# Database Service Contract

**Purpose**: Define all database operations for the savings app  
**Implementation**: SQLite via sqflite package

## Core Operations

### SavingsService

#### saveMoney()
**Purpose**: Record a new 1000원 savings event (FR-001, FR-005)
```dart
Future<SavingsResult> saveMoney() async
```

**Behavior**:
- Creates new SavingsSession with current timestamp
- Updates UserProgress totals immediately  
- Detects and records milestone achievements
- Returns result with new totals and milestone info

**Performance Requirements**:
- MUST complete database write within 50ms
- MUST support rapid consecutive calls
- MUST maintain data integrity under concurrent access

**Returns**:
```dart
class SavingsResult {
  final int newTotal;              // Updated total savings
  final int todayCount;            // Today's save count
  final List<int> milestonesHit;   // New milestones achieved
  final bool success;              // Operation success
  final String? error;             // Error message if failed
}
```

#### getCurrentProgress()
**Purpose**: Load current savings state for display (FR-004, FR-007)
```dart
Future<UserProgress> getCurrentProgress() async
```

**Behavior**:
- Reads current totals from user_progress table
- Updates today_count if date changed
- Recalculates streak based on last_save_date
- Returns complete progress state

**Performance Requirements**:
- MUST complete within 20ms
- MUST be callable on every app launch
- MUST handle empty database (first run)

#### getSavingsHistory()
**Purpose**: Load historical savings data for progress view
```dart
Future<List<SavingsSession>> getSavingsHistory({
  DateTime? startDate,
  DateTime? endDate, 
  int? limit,
}) async
```

**Behavior**:
- Returns chronologically ordered savings sessions
- Supports date range filtering
- Supports pagination via limit
- Efficient for large datasets

**Performance Requirements**:
- MUST use indexed queries
- MUST limit results to prevent memory issues
- MUST support lazy loading

### Database Management

#### initializeDatabase()
**Purpose**: Set up database schema and initial data
```dart
Future<void> initializeDatabase() async
```

**Behavior**:
- Creates all required tables
- Sets up indexes for performance
- Configures SQLite for optimal performance (WAL mode)
- Initializes user_progress with default values

#### resetUserData()
**Purpose**: Clear all savings data (for testing/reset)
```dart
Future<void> resetUserData() async
```

**Behavior**:
- Deletes all savings_sessions
- Resets user_progress to defaults
- Maintains database schema
- Cannot be undone

## Database Schema Operations

### Table Creation
```sql
-- Savings sessions table
CREATE TABLE IF NOT EXISTS savings_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount INTEGER NOT NULL CHECK (amount = 1000),
  timestamp INTEGER NOT NULL
);

-- User progress table (single row)
CREATE TABLE IF NOT EXISTS user_progress (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  total_savings INTEGER NOT NULL DEFAULT 0,
  total_sessions INTEGER NOT NULL DEFAULT 0,
  today_session_count INTEGER NOT NULL DEFAULT 0,
  last_save_date INTEGER NOT NULL DEFAULT 0,
  current_streak INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  milestones TEXT DEFAULT '[]'
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_savings_timestamp 
ON savings_sessions(timestamp);
```

### Optimized Queries

#### Insert new savings (with progress update)
```sql
-- Transaction for atomic savings + progress update
BEGIN TRANSACTION;

INSERT INTO savings_sessions (amount, timestamp) 
VALUES (1000, ?);

UPDATE user_progress 
SET 
  total_savings = total_savings + 1000,
  total_sessions = total_sessions + 1,
  today_session_count = CASE 
    WHEN date(last_save_date/1000, 'unixepoch') = date('now') 
    THEN today_session_count + 1 
    ELSE 1 
  END,
  last_save_date = ?,
  current_streak = CASE
    WHEN date(last_save_date/1000, 'unixepoch') = date('now') 
    THEN current_streak
    WHEN date(last_save_date/1000, 'unixepoch', '+1 day') = date('now')
    THEN current_streak + 1
    ELSE 1
  END,
  longest_streak = MAX(longest_streak, 
    CASE
      WHEN date(last_save_date/1000, 'unixepoch') = date('now') 
      THEN current_streak
      WHEN date(last_save_date/1000, 'unixepoch', '+1 day') = date('now')
      THEN current_streak + 1
      ELSE 1
    END
  )
WHERE id = 1;

COMMIT;
```

#### Get current progress
```sql
SELECT 
  total_savings,
  total_sessions,
  CASE 
    WHEN date(last_save_date/1000, 'unixepoch') = date('now')
    THEN today_session_count
    ELSE 0
  END as today_session_count,
  last_save_date,
  current_streak,
  longest_streak,
  milestones
FROM user_progress 
WHERE id = 1;
```

#### Get recent history
```sql
SELECT id, amount, timestamp
FROM savings_sessions
ORDER BY timestamp DESC
LIMIT ?;
```

## Error Handling

### Database Errors
```dart
enum DatabaseError {
  connectionFailed,
  constraintViolation, 
  diskFull,
  corruptedData,
  concurrencyConflict
}

class DatabaseException implements Exception {
  final DatabaseError type;
  final String message;
  final dynamic originalError;
  
  DatabaseException(this.type, this.message, [this.originalError]);
}
```

### Recovery Strategies
- **Connection failures**: Retry with exponential backoff
- **Disk full**: Clear cache, show user warning
- **Corruption**: Attempt repair, fallback to backup
- **Concurrency**: Automatic retry for write conflicts

## Performance Contracts

### Response Time Requirements
- `saveMoney()`: <50ms including UI update
- `getCurrentProgress()`: <20ms on app launch  
- `getSavingsHistory()`: <100ms for 100 records

### Concurrency Support
- Multiple rapid `saveMoney()` calls MUST be handled safely
- Database MUST use WAL mode for concurrent reads
- Batch operations MUST be used for bulk updates

### Memory Usage
- Query results MUST be limited to prevent excessive memory
- Large history queries MUST support pagination
- Database connections MUST be properly managed

## Testing Contract

### Unit Test Requirements
```dart
// Database service tests
test('saveMoney updates totals correctly');
test('getCurrentProgress handles empty database');
test('rapid saveMoney calls maintain data integrity');
test('milestone detection works for 10,000원 increments');

// Performance tests  
test('saveMoney completes within 50ms');
test('getCurrentProgress completes within 20ms');
test('handles 1000+ consecutive saves without data loss');
```

### Integration Test Requirements
```dart
// End-to-end database tests
test('full user session preserves data across app restarts');
test('database corruption recovery works correctly');
test('concurrent access from multiple isolates');
```