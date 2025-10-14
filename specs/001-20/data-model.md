# Data Model: One-Touch Savings App

**Generated**: 2025-10-14  
**Source**: Feature spec functional requirements analysis

## Entity Definitions

### SavingsSession
**Purpose**: Individual button press event with amount and timestamp  
**Source**: FR-001, FR-006 - Track individual save events

**Fields**:
```dart
class SavingsSession {
  final int id;              // Primary key
  final int amount;          // Always 1000 (won)
  final DateTime timestamp;  // When save occurred
  final String? notes;       // Optional user notes (future)
  
  SavingsSession({
    required this.id,
    required this.amount, 
    required this.timestamp,
    this.notes,
  });
}
```

**Validation Rules**:
- `amount` MUST equal 1000 (per FR-001)
- `timestamp` MUST be valid DateTime
- `id` MUST be unique auto-increment

**SQLite Schema**:
```sql
CREATE TABLE savings_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount INTEGER NOT NULL CHECK (amount = 1000),
  timestamp INTEGER NOT NULL,
  notes TEXT
);

CREATE INDEX idx_savings_timestamp ON savings_sessions(timestamp);
```

### UserProgress  
**Purpose**: Accumulated total, session count, streak tracking, milestone achievements  
**Source**: FR-004, FR-007 - Display progress and track milestones

**Fields**:
```dart
class UserProgress {
  final int totalSavings;           // Sum of all sessions
  final int totalSessions;          // Count of save events
  final int todaySessionCount;      // Today's save count
  final DateTime lastSaveDate;      // Last activity
  final int currentStreak;          // Consecutive days
  final int longestStreak;          // Best streak achieved
  final List<int> milestones;       // Achieved milestones
  
  UserProgress({
    required this.totalSavings,
    required this.totalSessions,
    required this.todaySessionCount,
    required this.lastSaveDate,
    required this.currentStreak,
    required this.longestStreak,
    required this.milestones,
  });
}
```

**Validation Rules**:
- `totalSavings` MUST equal `totalSessions * 1000`
- `todaySessionCount` MUST be non-negative
- `currentStreak` MUST be non-negative
- `milestones` MUST contain only 10,000원 increments

**SQLite Schema**:
```sql
CREATE TABLE user_progress (
  id INTEGER PRIMARY KEY CHECK (id = 1), -- Single row table
  total_savings INTEGER NOT NULL DEFAULT 0,
  total_sessions INTEGER NOT NULL DEFAULT 0,
  today_session_count INTEGER NOT NULL DEFAULT 0,
  last_save_date INTEGER NOT NULL,
  current_streak INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  milestones TEXT DEFAULT '[]' -- JSON array of achieved milestones
);

-- Initialize single row
INSERT OR IGNORE INTO user_progress (id, last_save_date) 
VALUES (1, strftime('%s', 'now') * 1000);
```

### FeedbackEvent
**Purpose**: Visual/audio responses triggered by saving actions  
**Source**: FR-002, FR-010 - Track feedback for analytics

**Fields**:
```dart
class FeedbackEvent {
  final int id;                    // Primary key
  final int sessionId;             // Reference to SavingsSession
  final FeedbackType type;         // Basic or milestone
  final DateTime timestamp;        // When feedback occurred
  final int? milestoneAmount;      // If milestone feedback
  
  FeedbackEvent({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.timestamp,
    this.milestoneAmount,
  });
}

enum FeedbackType { basic, milestone }
```

**Validation Rules**:
- `sessionId` MUST reference valid SavingsSession
- `milestoneAmount` MUST be multiple of 10,000 if type is milestone
- `timestamp` MUST match or follow session timestamp

**SQLite Schema**:
```sql
CREATE TABLE feedback_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  feedback_type TEXT NOT NULL CHECK (feedback_type IN ('basic', 'milestone')),
  timestamp INTEGER NOT NULL,
  milestone_amount INTEGER,
  FOREIGN KEY (session_id) REFERENCES savings_sessions(id)
);
```

## State Transitions

### Savings Flow
```
[App Launch] → [Display Current Total] → [Button Tap] → [Immediate UI Update] 
    ↓
[Haptic Feedback] → [Animation] → [Database Persist] → [Check Milestones]
    ↓
[Milestone Feedback?] → [Update Progress] → [Ready for Next Tap]
```

### Milestone Detection
```dart
bool isMilestone(int newTotal) {
  return newTotal % 10000 == 0 && newTotal > 0;
}

List<int> detectNewMilestones(int oldTotal, int newTotal) {
  final oldMilestones = (oldTotal / 10000).floor();
  final newMilestones = (newTotal / 10000).floor();
  
  if (newMilestones > oldMilestones) {
    return List.generate(
      newMilestones - oldMilestones, 
      (i) => (oldMilestones + i + 1) * 10000
    );
  }
  return [];
}
```

### Streak Calculation
```dart
int calculateStreak(DateTime lastSave, DateTime now) {
  final daysDiff = now.difference(lastSave).inDays;
  
  if (daysDiff == 0) return currentStreak; // Same day
  if (daysDiff == 1) return currentStreak + 1; // Next day
  return 0; // Streak broken
}
```

## Database Relationships

```
savings_sessions (1) ← (many) feedback_events
user_progress (1) ← (aggregate) savings_sessions
```

**Aggregate Queries**:
```sql
-- Update user progress after new session
UPDATE user_progress 
SET 
  total_savings = (SELECT SUM(amount) FROM savings_sessions),
  total_sessions = (SELECT COUNT(*) FROM savings_sessions),
  today_session_count = (
    SELECT COUNT(*) FROM savings_sessions 
    WHERE date(timestamp/1000, 'unixepoch') = date('now')
  ),
  last_save_date = (SELECT MAX(timestamp) FROM savings_sessions)
WHERE id = 1;
```

## Data Access Patterns

### High-Frequency Operations (Performance Critical)
- **Insert savings session** - Called on every button tap
- **Update user progress** - Called on every button tap  
- **Read current totals** - Called on app launch/resume

### Low-Frequency Operations
- **Calculate streaks** - Daily calculation
- **Load history** - User-initiated only
- **Milestone queries** - Triggered by total changes

## Validation Rules Summary

1. **Data Integrity**: All amounts MUST be exactly 1000원
2. **Timestamp Consistency**: Events MUST be chronologically ordered
3. **Progress Accuracy**: Totals MUST match session aggregates
4. **Milestone Logic**: Only multiples of 10,000원 trigger celebrations
5. **Streak Rules**: Consecutive day requirement for streak maintenance