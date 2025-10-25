# Quest Event Investigation Results
## Classic Era (1.12)

**Date:** October 25, 2025
**Purpose:** Document which quest events fire and when in WoW Classic Era
**Method:** Live testing with event listeners, hooks, and UI frame monitors

---

## Events Available in Classic Era

### ✅ Events That Fire (Confirmed)

| Event | Args | Description |
|-------|------|-------------|
| `QUEST_ACCEPTED` | questLogIndex, questId | Quest added to quest log |
| `QUEST_REMOVED` | questId | Quest removed from log |
| `QUEST_TURNED_IN` | questId, xpReward, moneyReward | Quest completion confirmed |
| `QUEST_COMPLETE` | (none) | Quest objectives finished |
| `QUEST_PROGRESS` | (none) | Quest progress dialog shown |
| `QUEST_WATCH_UPDATE` | questId | Quest objective progress updated |
| `QUEST_DETAIL` | ??? | Quest details displayed |
| `QUEST_FINISHED` | (none) | Quest dialog closed |
| `QUEST_LOG_UPDATE` | (none) | Generic quest log change |
| `UNIT_QUEST_LOG_CHANGED` | unitId | Quest log changed for unit |
| `PLAYER_ENTERING_WORLD` | isLogin, isReload | World entry/reload |

### ❌ Events That Don't Fire (Not Triggered)

- `QUEST_POI_UPDATE`
- `QUEST_ITEM_UPDATE`
- `QUEST_GREETING`
- `QUEST_ACCEPT_CONFIRM`

### 🎣 UI Hooks (hooksecurefunc)

| Hook | When It Fires |
|------|---------------|
| `QuestLog_Update` | Quest log UI updates |
| `QuestInfo_Display` | Quest info shown at NPC |
| `QuestFrameProgressItems_Update` | Quest progress dialog shown |

---

## Event Flows

### 1. Login / UI Reload

```
[Quest Hook] QuestLog_Update (×4)
  ↓
[Quest Event] PLAYER_ENTERING_WORLD → true, false
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] QUEST_LOG_UPDATE (×3)
```

---

### 2. Open/Close Quest Log

```
[Quest Hook] QuestLog_Update
[Quest UI] Quest Log OPENED
[Quest UI] Quest Log CLOSED
```

**No quest events fire**

---

### 3. Select Different Quests in Quest Log

```
[Quest UI] Quest Log OPENED
  ↓
[Quest Hook] QuestLog_Update  ← Select quest 1
  ↓
[Quest Hook] QuestLog_Update  ← Select quest 2
  ↓
[Quest UI] Quest Log CLOSED
```

**No quest events fire**

---

### 4. Abandon Quest

```
[Quest UI] Quest Log OPENED
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] QUEST_REMOVED → 1395
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] UNIT_QUEST_LOG_CHANGED → player
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] QUEST_LOG_UPDATE
  ↓
[Quest UI] Quest Log CLOSED
```

---

### 5. Accept Quest from NPC

```
[Quest Hook] QuestInfo_Display
[Quest UI] Quest NPC Dialog OPENED
  ↓
[Quest Event] QUEST_DETAIL → 0
  ↓
[Quest UI] Quest NPC Dialog CLOSED
[Quest Event] QUEST_FINISHED
  ↓
[Quest Event] QUEST_ACCEPTED → 7, 1395
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] UNIT_QUEST_LOG_CHANGED → player
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] QUEST_LOG_UPDATE (×2)
```

---

### 6. Turn In Quest (Check Progress - Incomplete)

```
[Quest Hook] QuestFrameProgressItems_Update
[Quest UI] Quest NPC Dialog OPENED
  ↓
[Quest Event] QUEST_PROGRESS
  ↓
[Quest Event] QUEST_FINISHED
[Quest UI] Quest NPC Dialog CLOSED
  ↓
[Quest Event] QUEST_FINISHED
```

---

### 7. Turn In Quest (Complete - No Reward Choice)

```
[Quest Hook] QuestInfo_Display
[Quest UI] Quest NPC Dialog OPENED
  ↓
[Quest Event] QUEST_COMPLETE
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] QUEST_TURNED_IN → 1395, 2900, 5000
  ↓
[Quest UI] Quest NPC Dialog CLOSED
[Quest Event] QUEST_FINISHED
  ↓
[Quest Event] QUEST_REMOVED → 1395
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] UNIT_QUEST_LOG_CHANGED → player
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] QUEST_LOG_UPDATE
```

---

### 8. Turn In Quest (Complete - With Reward Choice)

```
[Quest Hook] QuestInfo_Display
[Quest UI] Quest NPC Dialog OPENED
  ↓
[Quest Event] QUEST_COMPLETE
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] QUEST_TURNED_IN → 1477, 975, 0
  ↓
[Quest UI] Quest NPC Dialog CLOSED
[Quest Event] QUEST_FINISHED
  ↓
[Quest Hook] QuestInfo_Display
[Quest UI] Quest NPC Dialog OPENED
[Quest Event] QUEST_DETAIL → 0
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] QUEST_LOG_UPDATE
  ↓
[Quest Event] QUEST_REMOVED → 1477
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] UNIT_QUEST_LOG_CHANGED → player
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] QUEST_LOG_UPDATE
```

**Note:** When NPC has another quest available, it shows automatically before `QUEST_REMOVED` fires

---

### 9. Loot Quest Item from Mob

```
[Quest Event] QUEST_WATCH_UPDATE → 587
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] UNIT_QUEST_LOG_CHANGED → player
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] QUEST_LOG_UPDATE (×2)
```

---

### 10. Kill Quest Mob (Progress: 1/10)

```
[Quest Event] QUEST_WATCH_UPDATE → 604
  ↓
[Quest Hook] QuestLog_Update (×3)
  ↓
[Quest Event] UNIT_QUEST_LOG_CHANGED → player
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] QUEST_LOG_UPDATE
  ↓
[Quest Hook] QuestLog_Update
```

---

### 11. Kill Quest Mob (Progress: 2/10)

```
[Quest Event] QUEST_WATCH_UPDATE → 604
  ↓
[Quest Hook] QuestLog_Update (×3)
  ↓
[Quest Event] UNIT_QUEST_LOG_CHANGED → player
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] QUEST_LOG_UPDATE
  ↓
[Quest Hook] QuestLog_Update
```

**Pattern:** `QUEST_WATCH_UPDATE` fires every kill with same questId

---

### 12. Split Quest Item Stack

```
[Quest Hook] QuestLog_Update
  ↓
[QuestObjective] Event: QUEST_LOG_UPDATE
[Quest Event] QUEST_LOG_UPDATE (×2)
```

**Action:** Split stack of 3 Snuff into 2+1

**Note:** No `QUEST_WATCH_UPDATE` - only `QUEST_LOG_UPDATE`

---

### 13. Delete Quest Item

```
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] UNIT_QUEST_LOG_CHANGED → player
  ↓
[Quest Hook] QuestLog_Update
  ↓
[QuestObjective] Event: QUEST_LOG_UPDATE
[Quest Event] QUEST_LOG_UPDATE
```

**Action:** Delete 1 Snuff from bag

**Note:** No `QUEST_WATCH_UPDATE` - triggers `UNIT_QUEST_LOG_CHANGED` and `QUEST_LOG_UPDATE`

---

## Key Observations

### Event Timing

| Action | First Event | Key Event | Last Event |
|--------|-------------|-----------|------------|
| Accept Quest | `QUEST_ACCEPTED` | - | `QUEST_LOG_UPDATE` |
| Abandon Quest | `QUEST_REMOVED` | - | `QUEST_LOG_UPDATE` |
| Turn In Quest | `QUEST_COMPLETE` | `QUEST_REMOVED` | `QUEST_LOG_UPDATE` |
| Loot Quest Item | `QUEST_WATCH_UPDATE` | - | `QUEST_LOG_UPDATE` |
| Kill Quest Mob | `QUEST_WATCH_UPDATE` | - | `QUEST_LOG_UPDATE` |
| Split Quest Item | `QUEST_LOG_UPDATE` | - | `QUEST_LOG_UPDATE` |
| Delete Quest Item | `UNIT_QUEST_LOG_CHANGED` | - | `QUEST_LOG_UPDATE` |

### Quest Removal Timing

**Turn-in sequence:**
```
QUEST_COMPLETE → QUEST_TURNED_IN → QUEST_FINISHED → QUEST_REMOVED
```

**Critical:** `QUEST_REMOVED` fires AFTER `QUEST_TURNED_IN`

### Quest Progress Events

**`QUEST_WATCH_UPDATE` fires on:**
- Looting quest items from mobs
- Killing quest mobs
- Any quest objective progress update

**Pattern for progress updates:**
```
QUEST_WATCH_UPDATE (questId)
  ↓
UNIT_QUEST_LOG_CHANGED (player)
  ↓
QUEST_LOG_UPDATE (×1-2)
```

### Event Frequency

| Event | Occurrences Per Action | Notes |
|-------|------------------------|-------|
| `QUEST_ACCEPTED` | 1× | Once per accept |
| `QUEST_REMOVED` | 1× | Once per removal |
| `QUEST_TURNED_IN` | 1× | Once per turn-in |
| `QUEST_WATCH_UPDATE` | 1× | Once per progress update |
| `QUEST_LOG_UPDATE` | 1-3× | Multiple times per action |
| `UNIT_QUEST_LOG_CHANGED` | 1× | Once per action |
| `QuestLog_Update` hook | Many | Every UI update |

### Hook Behavior

**`QuestLog_Update` hook fires very frequently:**
- Quest log opened/closed
- Quest selected in log
- Quest progress updates (kill count, quest item looted)
- Quest accepted/turned in/abandoned
- Login/reload (4× on initial load)

---

## Untested Scenarios

1. **Complete quest objective (final kill)** - May fire `QUEST_COMPLETE` event
2. **Loot quest item from world object (clickable)** - May differ from mob loot
3. **Multi-quest NPC greeting** - May fire `QUEST_GREETING` event
4. **Shared/escort quest prompt** - May fire `QUEST_ACCEPT_CONFIRM` event
5. **Click different reward choices before accepting** - Likely no events (UI only)
6. **Share quest with party member** - Not critical for quest lifecycle
7. **Accept quest from item (vs NPC)** - Likely same flow as NPC accept
8. **Quest auto-complete (if exists in Classic Era)** - Rare scenario

---

## Summary

### Event Categories

**Quest Lifecycle (quest added/removed from log):**
- `QUEST_ACCEPTED` - Quest added to log
- `QUEST_REMOVED` - Quest removed from log
- `PLAYER_ENTERING_WORLD` - Login/reload

**Quest Progress (quest remains in log):**
- `QUEST_WATCH_UPDATE` - Objective progress updated
- `QUEST_COMPLETE` - All objectives finished
- `QUEST_TURNED_IN` - Quest completed (but not removed yet)

**Quest UI (display only, no data changes):**
- `QUEST_DETAIL` - Viewing quest details
- `QUEST_PROGRESS` - Checking incomplete quest
- `QUEST_FINISHED` - Dialog closed

**Generic Changes:**
- `QUEST_LOG_UPDATE` - Any quest-related change (fires 1-3× per action)
- `UNIT_QUEST_LOG_CHANGED` - Quest log changed (fires 1× per action)

### Events Not Triggered During Testing

- `QUEST_POI_UPDATE` - Quest marker updates
- `QUEST_ITEM_UPDATE` - Quest item changes (doesn't exist or doesn't fire in Classic Era)
- `QUEST_GREETING` - Multi-quest NPC menu (scenario not tested)
- `QUEST_ACCEPT_CONFIRM` - Shared/escort quest (scenario not tested)

**Note:** `QUEST_ITEM_UPDATE` never fired even when looting quest items - `QUEST_WATCH_UPDATE` handles quest item looting instead.
