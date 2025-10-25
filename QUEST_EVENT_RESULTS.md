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
| `QUEST_COMPLETE` | (none) | Quest objectives finished (fires at NPC only, never in field) |
| `QUEST_PROGRESS` | (none) | Quest progress dialog shown |
| `QUEST_WATCH_UPDATE` | questId | Quest objective progress updated |
| `QUEST_DETAIL` | ??? | Quest details displayed |
| `QUEST_FINISHED` | (none) | Quest dialog closed |
| `QUEST_LOG_UPDATE` | (none) | Generic quest log change |
| `UNIT_QUEST_LOG_CHANGED` | unitId | Quest log changed for unit |
| `QUEST_GREETING` | (none) | Multi-quest NPC greeting menu (confirmed) |
| `BAG_UPDATE` | bagId | Bag contents changed (fires when quest items removed) |
| `PLAYER_ENTERING_WORLD` | isLogin, isReload | World entry/reload |

### ⚠️ Events That Fire Unreliably

| Event | Args | Description |
|-------|------|-------------|
| `QUEST_ITEM_UPDATE` | (none) | Quest item changed - UNRELIABLE: Fired in 2 of 7 turn-in tests, then never again. Do not rely on this event. |

### ❌ Events That Don't Fire (Not Triggered)

- `QUEST_POI_UPDATE` - Never observed during testing
- `QUEST_ACCEPT_CONFIRM` - Shared/escort quest prompt (scenario not tested)

### 🎣 UI Hooks (hooksecurefunc)

| Hook | When It Fires |
|------|---------------|
| `QuestLog_Update` | Quest log UI updates |
| `QuestInfo_Display` | Quest info shown at NPC |
| `QuestFrameProgressItems_Update` | Quest progress dialog shown |
| `AcceptQuest` | Player accepts quest from NPC |
| `AbandonQuest` | Player abandons quest |
| `CompleteQuest` | Player clicks to complete quest at NPC |
| `GetQuestReward` | Player selects reward choice (if applicable) |

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
[Quest Event] QUEST_FINISHED
  ↓
[Quest Hook] AcceptQuest
[Quest UI] Quest NPC Dialog CLOSED
  ↓
[Quest Event] QUEST_ACCEPTED → 16, 621
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] UNIT_QUEST_LOG_CHANGED → player
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] QUEST_LOG_UPDATE
```

**Note:** `QUEST_FINISHED` fires while dialog is still open, then `AcceptQuest` hook fires as dialog closes

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

### 8a. Turn In Quest at Multi-Quest NPC (With Quest Chain)

```
[Quest Event] QUEST_GREETING
[Quest UI] Quest NPC Dialog OPENED (multi-quest menu)
  ↓
[Quest Hook] QuestFrameProgressItems_Update
[Quest Event] QUEST_PROGRESS
  ↓
[Quest Hook] CompleteQuest
  ↓
[Quest Event] QUEST_FINISHED (×2)
  ↓
[Quest Hook] QuestInfo_Display
[Quest Event] QUEST_COMPLETE
  ↓
[Quest Hook] GetQuestReward → Choice: 0
[Quest Hook] QuestLog_Update (×1-2, reputation changes)
  ↓
[Quest Event] QUEST_TURNED_IN → 233, 190, 0
  ↓
[Quest Event] QUEST_FINISHED (×2)
  ↓
[Quest Hook] QuestInfo_Display
[Quest Event] QUEST_DETAIL (new quest offered)
  ↓
[Quest Hook] AcceptQuest
[Quest Event] QUEST_ACCEPTED → 234 (new quest)
  ↓ (same timestamp)
[Quest Event] QUEST_REMOVED → 233 (old quest removed)
  ↓ (same timestamp)
[Quest Event] BAG_UPDATE (×4)
✓ Quest items REMOVED from bags
  ↓
[Quest Hook] QuestLog_Update
[Quest Event] QUEST_LOG_UPDATE
[Quest UI] Quest NPC Dialog CLOSED
```

**Key Observations:**
- `QUEST_GREETING` fires when interacting with NPC that has multiple quests/turn-ins available
- When NPC offers new quest after completion, events occur in rapid sequence at same timestamp:
  - New quest accepted (`QUEST_ACCEPTED`)
  - Old quest removed (`QUEST_REMOVED`)
  - Quest items removed from bags (`BAG_UPDATE`)
- `QUEST_ITEM_UPDATE` did NOT fire (consistent with Pattern C/D)
- This is a **quest chain turn-in** - completing one quest that leads directly to another

---

### 9. Quest Progress Updates (Loot Items / Kill Mobs)

```
[Quest Event] QUEST_WATCH_UPDATE → questId
  ↓
[Quest Hook] QuestLog_Update (×1-3)
  ↓
[Quest Event] UNIT_QUEST_LOG_CHANGED → player
  ↓
[Quest Hook] QuestLog_Update
  ↓
[Quest Event] QUEST_LOG_UPDATE
  ↓
[Quest Hook] QuestLog_Update (optional)
```

**⚠️ CRITICAL TIMING:** `QUEST_WATCH_UPDATE` fires **BEFORE** quest data updates:
- Event shows **OLD count** (before the change just made)
- Quest data is **STALE** when event fires
- Data updates by the time first or second `QUEST_LOG_UPDATE` fires (~100-300ms later)

**Examples:**
- Loot 3rd quest item → `QUEST_WATCH_UPDATE` shows "2/15" (OLD) → `QUEST_LOG_UPDATE` shows "3/15" (NEW)
- Kill 1st quest mob → `QUEST_WATCH_UPDATE` shows "0/10" (OLD) → `QUEST_LOG_UPDATE` shows "1/10" (NEW)

**Pattern applies to:**
- Looting quest items from mobs
- Killing quest mobs
- Any quest objective progress update

**Note:** Reputation changes from mob kills cause additional `QuestLog_Update` hooks to fire mid-sequence (visual noise only - does not affect quest event timing).

---

### 10. Quest Item Removal During Turn-In

**🚨 CRITICAL: Event order is HIGHLY INCONSISTENT - 5 different patterns observed across 7 turn-ins**

**Pattern A (Delivery Quest - Early Test):**
```
QUEST_TURNED_IN → QUEST_REMOVED → BAG_UPDATE → QUEST_ITEM_UPDATE
```
- Quest items removed at `BAG_UPDATE`
- `QUEST_ITEM_UPDATE` fired ~6ms after `BAG_UPDATE`

**Pattern B (Delivery Quest - Early Test):**
```
QUEST_REMOVED → BAG_UPDATE → QUEST_ITEM_UPDATE → QUEST_TURNED_IN
```
- Complete reversal of Pattern A
- Quest items removed at `BAG_UPDATE`
- `QUEST_ITEM_UPDATE` fired ~6ms after `BAG_UPDATE`

**Pattern C (Collection Quest - "Dwarven Outfitters" 8/8 Tough Wolf Meat):**
```
QUEST_COMPLETE → QUEST_REMOVED → BAG_UPDATE(×2) → QUEST_TURNED_IN → BAG_UPDATE(×4)
```
- ❌ `QUEST_ITEM_UPDATE` did NOT fire
- First `BAG_UPDATE` at same time as `QUEST_REMOVED`
- Second `BAG_UPDATE` group after receiving reward item
- Quest items removed at first or second `BAG_UPDATE` sequence

**Pattern D (Delivery Quest - "Encrypted Rune"):**
```
QUEST_COMPLETE → QUEST_TURNED_IN → QUEST_LOG_UPDATE → QUEST_REMOVED → BAG_UPDATE(×2)
```
- ❌ `QUEST_ITEM_UPDATE` did NOT fire
- `QUEST_TURNED_IN` fires BEFORE `QUEST_REMOVED`
- Quest item (Encrypted Rune) removed at `BAG_UPDATE`

**Pattern E (Quest Chain - "Coldridge Valley Mail Delivery" at Multi-Quest NPC):**
```
QUEST_COMPLETE → QUEST_TURNED_IN → QUEST_ACCEPTED(new) → QUEST_REMOVED(old) → BAG_UPDATE(×4)
```
- ❌ `QUEST_ITEM_UPDATE` did NOT fire
- New quest acceptance interleaved with old quest removal
- All events at same timestamp
- Quest item (A Stack of Letters) removed at `BAG_UPDATE`

**Key Findings:**
- **ZERO consistency** in event order across 7 turn-ins tested
- `QUEST_TURNED_IN` and `QUEST_REMOVED` fire in **completely random order**
- `QUEST_ITEM_UPDATE` is **UNRELIABLE**: Fired in first 2 tests, then never again (0 of 5 subsequent tests)
- `BAG_UPDATE` is the **ONLY consistent indicator** that quest items were physically removed from bags
- Quest item removal happens at turn-in dialog, NOT when final objective completes
- Quest can remain at max progress (8/8, 15/15) for extended time before turn-in

**For addon implementation:**
- ❌ **DO NOT rely on event order** - it's completely unpredictable
- ❌ **DO NOT use `QUEST_ITEM_UPDATE`** - fires sporadically (2 of 7 tests)
- ✅ **USE `BAG_UPDATE`** - only reliable indicator for item removal timing
- ✅ Monitor `BAG_UPDATE` during active quest turn-in to detect when items disappear
- Pattern suggests `BAG_UPDATE` may fire multiple times (sometimes ×2, sometimes ×4)

---

### 11. Split Quest Item Stack

```
[Quest Hook] QuestLog_Update
  ↓
[QuestObjective] Event: QUEST_LOG_UPDATE
[Quest Event] QUEST_LOG_UPDATE (×2)
```

**Action:** Split stack of 3 Snuff into 2+1

**Note:** No `QUEST_WATCH_UPDATE` - only `QUEST_LOG_UPDATE`

---

### 12. Delete Quest Item

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

### ⚠️ CRITICAL: Quest Data Update Timing

**`QUEST_WATCH_UPDATE` fires BEFORE quest data updates:**

- ❌ **At event fire:** Quest log data is **STALE** (shows OLD progress count)
- ✅ **After ~50-200ms:** Quest data is updated (by the time `QUEST_LOG_UPDATE` fires)

**Example Timeline:**
```
1. You loot the 3rd quest item
2. QUEST_WATCH_UPDATE fires → Quest log still shows "2/15" (OLD)
3. ~100ms passes...
4. QUEST_LOG_UPDATE fires → Quest log now shows "3/15" (NEW)
```

---

### Event Timing

| Action | Event Sequence |
|--------|----------------|
| **Accept Quest** | `QUEST_DETAIL` → `QUEST_FINISHED` → `AcceptQuest` hook → `QUEST_ACCEPTED` → `QuestLog_Update` hook → `UNIT_QUEST_LOG_CHANGED` → `QuestLog_Update` hook → `QUEST_LOG_UPDATE` |
| **Abandon Quest** | `QUEST_REMOVED` → `QuestLog_Update` hook → `UNIT_QUEST_LOG_CHANGED` → `QuestLog_Update` hook → `QUEST_LOG_UPDATE` |
| **Loot Quest Item** | `QUEST_WATCH_UPDATE` (stale data) → `QuestLog_Update` hook → `UNIT_QUEST_LOG_CHANGED` → `QuestLog_Update` hook → `QUEST_LOG_UPDATE` (data updates) |
| **Kill Quest Mob** | `QUEST_WATCH_UPDATE` (stale data) → `QuestLog_Update` hook → `UNIT_QUEST_LOG_CHANGED` → `QuestLog_Update` hook → `QUEST_LOG_UPDATE` (data updates) |
| **Turn In Quest** | `QUEST_COMPLETE` → `CompleteQuest` hook → `GetQuestReward` hook → `QuestLog_Update` hook → (unordered: `QUEST_TURNED_IN`, `QUEST_REMOVED`, `BAG_UPDATE`) → `QUEST_LOG_UPDATE` |
| **Quest Chain Turn-In** | `QUEST_GREETING` → `QUEST_COMPLETE` → `CompleteQuest` hook → `QUEST_TURNED_IN` → `QUEST_ACCEPTED` (new) → `QUEST_REMOVED` (old) → `BAG_UPDATE` → `QUEST_LOG_UPDATE` |
| **Split Quest Item** | `QuestLog_Update` hook → `QUEST_LOG_UPDATE` |
| **Delete Quest Item** | `QuestLog_Update` hook → `UNIT_QUEST_LOG_CHANGED` → `QuestLog_Update` hook → `QUEST_LOG_UPDATE` |

---

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

### High Priority (Critical for Quest Item Coloring)

These scenarios are essential for understanding when quest items change visual state:

1. **Complete multiple objectives simultaneously**
   - Quest with "Kill 10 mobs AND collect 2 items" - what if 10th kill drops the 2nd item?
   - Does `QUEST_COMPLETE` fire once or multiple times?
   - What's the event order when objectives complete at the same time?
   - **Why critical:** Complex timing that could affect item state updates

### Medium Priority (Common Quest Scenarios)

These affect common quest flows and should be documented:

5. **Loot quest item from world object/container**
   - Clickable chest, crate, or world object that gives quest items (not mob loot)
   - Does event timing differ from mob loot?
   - **Why important:** Different source might have different `QUEST_WATCH_UPDATE` timing

6. **Accept quest from item (quest starter item)**
   - Right-click an item in bags to start a quest (e.g., "A Sealed Letter")
   - Does the flow differ from NPC quest acceptance?
   - When does the quest starter item disappear?
   - **Why important:** Different acceptance flow might affect initial quest item handling

7. **Decline quest at NPC dialog**
   - View quest details but click "Decline" instead of "Accept"
   - Does `DeclineQuest` hook fire?
   - Are there any events besides `QUEST_FINISHED`?
   - **Why important:** Completes the quest dialog event flow documentation

### Lower Priority (Edge Cases & Rare Scenarios)

8. **Shared/escort quest prompts**
   - Does `QUEST_ACCEPT_CONFIRM` fire when accepting shared/escort quests?
   - Different flow from regular quest acceptance?

9. **Quest item used from inventory**
    - Use a quest item from bags (plant banner, activate item for quest progress)
    - Does this fire `QUEST_WATCH_UPDATE` or different events?

10. **Repeatable/daily quests**
    - Does the second acceptance of a repeatable quest differ from the first?
    - Do completed repeatables have different event patterns?

11. **Timed quest expiration/failure**
    - What events fire when a timed quest expires?
    - Does `QUEST_REMOVED` fire with isComplete=-1 (failed)?

12. **Click different reward choices before selecting**
    - Hover over different reward options - likely just UI, no events

13. **Quest progress from exploration**
    - Discovering a location that updates quest objectives
    - Event timing may differ from kill/loot objectives

14. **Quest auto-complete**
    - Rare scenario where quest completes without returning to NPC
    - May not exist in Classic Era

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

### Events Not Triggered or Scenario Not Tested

- `QUEST_POI_UPDATE` - Quest marker updates (never observed)
- `QUEST_ACCEPT_CONFIRM` - Shared/escort quest (scenario not tested)

**Note on `QUEST_ITEM_UPDATE`:** This event is **UNRELIABLE** in Classic Era 1.12. Across 7 quest turn-ins tested (collection and delivery quests), it fired in only 2 tests (~29%), then never again. When it did fire, it occurred ~6ms after `BAG_UPDATE`. Does NOT fire when looting quest items - `QUEST_WATCH_UPDATE` handles that instead. **Do not build addon logic around this event** - use `BAG_UPDATE` as the reliable indicator for quest item changes.
