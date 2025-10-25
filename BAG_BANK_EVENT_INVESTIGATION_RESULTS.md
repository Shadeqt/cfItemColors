# Bag and Bank Event Investigation Results
## Classic Era (1.12)

**Date:** October 25, 2025
**Purpose:** Document which bag/bank events fire and when in WoW Classic Era
**Method:** Live testing with event listeners, hooks, and detailed logging

---

## Events Available in Classic Era

### ✅ Events That Fire (Confirmed)

| Event | Args | Description |
|-------|------|-------------|
| `BAG_UPDATE` | bagId | Bag contents changed |
| `BAG_UPDATE_DELAYED` | (none) | All pending bag updates completed |
| `BAG_UPDATE_COOLDOWN` | bagId | Fires when consuming items (bagId=nil) |
| `ITEM_LOCK_CHANGED` | bagId, slotId | Item or equipment slot locked/unlocked |
| `ITEM_LOCKED` | bagId, slotId | Item locked (redundant with ITEM_LOCK_CHANGED) |
| `ITEM_UNLOCKED` | bagId, slotId | Item unlocked (redundant with ITEM_LOCK_CHANGED) |
| `BAG_CONTAINER_UPDATE` | (none) | Container-wide refresh (login, bank operations) |
| `UNIT_INVENTORY_CHANGED` | unitId | Player inventory changed (stack ops, deletion) |
| `PLAYER_EQUIPMENT_CHANGED` | equipmentSlot, hasCurrent | Equipment slot changed |
| `ITEM_PUSH` | bagId, iconFileID | NEW item entering bags |
| `BAG_NEW_ITEMS_UPDATED` | (none) | New item flags updated |
| `PLAYER_ENTERING_WORLD` | isLogin, isReload | World entry/reload |

### ❌ Events That Don't Fire (Not Triggered During Testing)

- `BAG_OPEN` - Registered but never fires
- `BAG_CLOSED` - Registered but never fires
- `BAG_SLOT_FLAGS_UPDATED` - Registered but never fires
- `PLAYERBANKBAGSLOTS_CHANGED` - Registered but never triggered during testing

### 🎣 UI Hooks (hooksecurefunc)

| Hook | When It Fires | Args |
|------|---------------|------|
| `ToggleBag` | Individual bag toggle (click icon) | bagId |
| `ToggleBackpack` | Backpack toggle (always fires with ToggleBag for bag 0) | (none) |
| `OpenBag` | Open specific bag (B key, vendor) | bagId, forceUpdate |
| `CloseBag` | Close specific bag (B key) | bagId |
| `OpenAllBags` | Open all bags (vendor, mailbox, bank UI) | forceUpdate (table) |
| `CloseAllBags` | Close all bags (closing vendor, etc.) | (none) |

---

## Bag ID Reference

| Bag ID | Type | Notes |
|--------|------|-------|
| `-2` | Keyring | Classic Era only (removed in later expansions) |
| `-1` | Bank | Standard bank container (24 slots in testing) |
| `0` | Backpack | Default bag, always present |
| `1-4` | Bags | Regular bag slots |
| `5-10` | Bank bags | Bank bag slots (6 total slots) |

## Equipment Slot Reference

| Slot ID | Equipment Slot |
|---------|----------------|
| `8` | Feet (boots) |
| `11` | Finger 1 (ring slot 1) |

**Note:** In `ITEM_LOCK_CHANGED`, equipment slots appear as `bagId=slotNumber, slotId=nil`

---

## Event Flows

### 1. Login / UI Reload

```
[BAG_UPDATE] Bag 1 (×1)
[BAG_UPDATE] Bag 2 (×1)
[BAG_UPDATE] Bag 3 (×1)
[BAG_UPDATE] Bag 4 (×1)
[BAG_UPDATE] Bank bag 5 (×1, 0/0 slots)
[BAG_UPDATE] Bank bag 6 (×1, 0/0 slots)
[BAG_UPDATE] Bank bag 7 (×1, 0/0 slots)
  ↓
[BAG_CONTAINER_UPDATE] → All containers refreshed
  ↓
[PLAYER_ENTERING_WORLD] → isInitialLogin: false, isReloadingUi: true
  ↓
[BAG_UPDATE_DELAYED] → All updates completed
```

**Note:** Backpack (bag 0) does NOT fire BAG_UPDATE on login

---

### 2. Open Individual Bags (Clicking Icons)

**Bag 0 (Backpack):**
```
[Hook] ToggleBag → bagId: 0 → OPENED
[Hook] ToggleBackpack → BACKPACK OPENED (1 bag open)
```

**Bags 1-4:**
```
[Hook] ToggleBag → bagId: X → OPENED
```

**No events fire** - only hooks

---

### 3. Close Individual Bags (Clicking Icons)

**Bags 1-4:**
```
[Hook] ToggleBag → bagId: X → CLOSED
```

**Bag 0 (Backpack):**
```
[Hook] ToggleBackpack → BACKPACK CLOSED (0 bags open)
```

**Note:** No `ToggleBag(0)` fires when closing backpack via click

---

### 4. Open All Bags (B Key)

```
[Hook] OpenBag → bagId: 1
[Hook] OpenBag → bagId: 2
[Hook] OpenBag → bagId: 3
[Hook] OpenBag → bagId: 4
  ↓
[Hook] ToggleBag → bagId: 0 → OPENED
[Hook] ToggleBackpack → BACKPACK OPENED (5 bags open)
```

**No events fire** - only hooks

---

### 5. Close All Bags (B Key)

```
[Hook] CloseBag → bagId: 1
[Hook] CloseBag → bagId: 2
[Hook] CloseBag → bagId: 3
[Hook] CloseBag → bagId: 4
(bag 0 closes silently - NO HOOK FIRES!)
```

**Critical:** Backpack (bag 0) closes without calling any hookable function

---

### 6. Open Bags via Vendor/Mailbox/Bank UI

```
[Hook] OpenBag → bagId: 1
[Hook] OpenBag → bagId: 2
[Hook] OpenBag → bagId: 3
[Hook] OpenBag → bagId: 4
  ↓
[Hook] OpenAllBags → forceUpdate: table
  ↓
[Hook] ToggleBag → bagId: 0 → OPENED
[Hook] ToggleBackpack → BACKPACK OPENED (5 bags open)
```

**Hybrid approach:** Both individual `OpenBag` calls AND `OpenAllBags`

---

### 7. Close Bags via Vendor/Mailbox/Bank UI

```
[Hook] CloseAllBags
```

**Note:** Uses `CloseAllBags` function (unlike B key which uses individual `CloseBag`)

---

### 8. Move Item Between Bags

**Example:** Silk Cloth from bag 2, slot 8 → bag 1, slot 1

```
[ITEM_LOCK_CHANGED] → Bag 2, Slot 8 (Silk Cloth picked up)
  ↓
[BAG_UPDATE] → Bag 2 (item removed, 3→2 items)
  ↓
[ITEM_LOCK_CHANGED] → Bag 1, Slot 1 (Silk Cloth placed)
  ↓
[BAG_UPDATE] → Bag 1 (item added, shows new contents)
  ↓
[BAG_UPDATE_DELAYED] → All updates completed
```

**Pattern:** `LOCK source → UPDATE source → LOCK destination → UPDATE destination → DELAYED`

---

### 9. Swap Items Between Bags

**Example:** Snuff ↔ Jaina's Signet Ring

```
[ITEM_LOCK_CHANGED] → Bag 2, Slot 4 (Jaina's Ring picked up)
  ↓
[ITEM_LOCK_CHANGED] → Bag 1, Slot 8 (Snuff picked up - swap initiated)
  ↓
[ITEM_LOCK_CHANGED] → Bag 2, Slot 4 (Snuff placed)
[BAG_UPDATE] → Bag 2 (shows Snuff in slot 4)
  ↓
[ITEM_LOCK_CHANGED] → Bag 1, Slot 8 (Jaina's Ring placed)
[BAG_UPDATE] → Bag 1 (shows Jaina's Ring in slot 8)
  ↓
[BAG_UPDATE_DELAYED] → All updates completed
```

**Pattern:** `LOCK item1 → LOCK item2 → LOCK + UPDATE new locations → DELAYED`

---

### 10. Split Stack (Same Bag)

**Example:** Mageweave x5 → x4 + x1 in bag 3

```
[ITEM_LOCK_CHANGED] → Bag 3, Slot 9 (Mageweave x5 - picking up)
  ↓
[ITEM_LOCK_CHANGED] → Bag 3, Slot 9 (Mageweave x4 - reduced stack)
  ↓
[BAG_UPDATE] → Bag 3 (shows x4 in slot 9, x1 in slot 10)
[UNIT_INVENTORY_CHANGED] → player
  ↓
[BAG_UPDATE] → Bag 3 (duplicate - same contents)
[BAG_UPDATE] → Bag 3 (duplicate - same contents)
[UNIT_INVENTORY_CHANGED] → player
  ↓
[BAG_UPDATE_DELAYED] → All updates completed
```

**Note:** Three `BAG_UPDATE` events with identical contents!

---

### 11. Split Stack (Cross-Bag)

**Example:** Mageweave x4 → x3 in bag 3, x1 to bag 2

```
[ITEM_LOCK_CHANGED] → Bag 3, Slot 9 (Mageweave x4 - picking up)
  ↓
[BAG_UPDATE] → Bag 2 (updates but item not visible yet)
  ↓
[ITEM_LOCK_CHANGED] → Bag 3, Slot 9 (Mageweave x3 - reduced)
[BAG_UPDATE] → Bag 3 (shows x3 in slot 9)
[UNIT_INVENTORY_CHANGED] → player
[BAG_UPDATE_DELAYED] → All updates completed
  ↓
[BAG_UPDATE] → Bag 2 (NOW shows x1 Mageweave in slot 1)
[UNIT_INVENTORY_CHANGED] → player
[BAG_UPDATE_DELAYED] → All updates completed (again!)
```

**Note:** Two separate `BAG_UPDATE_DELAYED` cycles - destination updates asynchronously!

---

### 12. Merge Stacks (Same Bag)

**Example:** Mageweave x1 + x3 → x4 in bag 3

```
[ITEM_LOCK_CHANGED] → Bag 3, Slot 10 (x1 Mageweave - picking up)
  ↓
[ITEM_LOCK_CHANGED] → Bag 3, Slot 9 (x3 Mageweave - target stack)
  ↓
[UNIT_INVENTORY_CHANGED] → player
[BAG_UPDATE] → Bag 3 (x1 gone, x3→x4, items 4→3)
  ↓
[ITEM_LOCK_CHANGED] → Bag 3, Slot 9 (x4 Mageweave - unlocking)
[BAG_UPDATE] → Bag 3 (duplicate - same contents)
[UNIT_INVENTORY_CHANGED] → player
[BAG_UPDATE_DELAYED] → All updates completed
```

---

### 13. Merge Stacks (Cross-Bag)

**Example:** Mageweave x1 from bag 2 + x4 in bag 3 → x5

```
[ITEM_LOCK_CHANGED] → Bag 2, Slot 1 (x1 Mageweave - picking up)
  ↓
[ITEM_LOCK_CHANGED] → Bag 3, Slot 9 (x4 Mageweave - target)
  ↓
[UNIT_INVENTORY_CHANGED] → player
[BAG_UPDATE] → Bag 2 (x1 gone, items 3→2)
  ↓
[ITEM_LOCK_CHANGED] → Bag 3, Slot 9 (x5 Mageweave - unlocking)
[BAG_UPDATE] → Bag 3 (x4→x5 combined)
[UNIT_INVENTORY_CHANGED] → player
[BAG_UPDATE_DELAYED] → All updates completed
```

**Note:** Merges are synchronous (unlike splits which are async for cross-bag)

---

### 14. Delete Item

**Example:** Delete Silk Cloth x1 from bag 1, slot 2

```
[ITEM_LOCK_CHANGED] → Bag 1, Slot 2 (Silk Cloth x1 - picked up)
  ↓
[ITEM_LOCK_CHANGED] → Bag 1, Slot 2 (Silk Cloth x1 - still locked)
  ↓
[ITEM_LOCK_CHANGED] → Bag 1, Slot 2 (Silk Cloth x1 - still locked)
  ↓
[UNIT_INVENTORY_CHANGED] → player
[BAG_UPDATE] → Bag 1 (item gone, 3→2 items)
[BAG_UPDATE_DELAYED] → All updates completed
```

**Note:** Triple `ITEM_LOCK_CHANGED` on same slot - unique to deletion!

---

### 15. Unequip Item to Bag

**Example:** Excelsior Boots from equipment slot 8 → bag 1, slot 9

```
[UNIT_INVENTORY_CHANGED] → player
  ↓
[PLAYER_EQUIPMENT_CHANGED] → Slot 8, Has Item: true
  ↓
[ITEM_LOCK_CHANGED] → Bag 1, Slot 9 (boots appear in bag)
[BAG_UPDATE] → Bag 1 (shows boots in slot 9)
[BAG_UPDATE_DELAYED] → All updates completed
```

**Note:** `PLAYER_EQUIPMENT_CHANGED` shows "Has Item: true" even though we're REMOVING it (shows state BEFORE change)

---

### 16. Equip Item from Bag

**Example:** Excelsior Boots from bag 1, slot 9 → equipment slot 8

```
[ITEM_LOCK_CHANGED] → Bag 1, Slot 9 (boots picked up from bag)
  ↓
[UNIT_INVENTORY_CHANGED] → player
  ↓
[ITEM_LOCK_CHANGED] → Equipment Lock: bagId=8, slotId=nil
[PLAYER_EQUIPMENT_CHANGED] → Slot 8, Has Item: false
  ↓
[BAG_UPDATE] → Bag 1 (boots removed, 3→2 items)
[BAG_UPDATE_DELAYED] → All updates completed
```

**Note:** Equipment slot lock appears as `bagId=slotNumber, slotId=nil`

---

### 17. Swap Equipped Items

**Example:** Seal of Wrynn → Jaina's Signet Ring (equipment slot 11)

```
[ITEM_LOCK_CHANGED] → Backpack, Slot 13 (Seal picked up)
  ↓
[ITEM_LOCK_CHANGED] → Equipment Lock: bagId=11 (ring slot)
  ↓
[UNIT_INVENTORY_CHANGED] → player
  ↓
[ITEM_LOCK_CHANGED] → Equipment Lock: bagId=11 (unlocking)
[PLAYER_EQUIPMENT_CHANGED] → Slot 11, Has Item: false
  ↓
[ITEM_LOCK_CHANGED] → Backpack, Slot 13 (Jaina's Ring in bag)
[BAG_UPDATE] → Backpack (shows Jaina's Ring)
[BAG_UPDATE] → Keyring (ID:-2, always updates at vendor)
[BAG_UPDATE_DELAYED] → All updates completed
```

---

### 18. Sell Item to Vendor

**Example:** Sell Greater Healing Potion x3

```
[Hook] OpenAllBags → forceUpdate: table
  ↓
[ITEM_LOCK_CHANGED] → Backpack, Slot 5 (potion locked)
  ↓
[BAG_UPDATE] → Backpack (item removed, 18→17 items)
[BAG_UPDATE] → Keyring (ID:-2)
[BAG_UPDATE_DELAYED] → All updates completed
```

**Note:** Keyring always updates on vendor transactions even though contents don't change

---

### 19. Buyback Item from Vendor

**Example:** Buyback Greater Healing Potion x3

```
[ITEM_LOCK_CHANGED] → Backpack, Slot 5 (potion locked)
[ITEM_UNLOCKED] → Backpack, Slot 5 (item placed)
  ↓
[BAG_UPDATE] → Backpack (item returned, fills empty slot)
[BAG_UPDATE] → Keyring (ID:-2)
[BAG_UPDATE_DELAYED] → All updates completed
```

**Notes:**
- No `ITEM_PUSH` event - buyback is NOT a "new" item
- Only `ITEM_UNLOCKED` fires (no `ITEM_LOCKED` since no pickup action)

---

### 20. Buy New Item from Vendor

**Example:** Buy Bottle of Dalaran Noir

```
[Hook] OpenBag → bagId: 1, 2, 3, 4
[Hook] OpenAllBags → forceUpdate: table
[Hook] ToggleBag → bagId: 0 → OPENED
[Hook] ToggleBackpack → BACKPACK OPENED (5 bags open)
  ↓
[ITEM_PUSH] → Backpack [ID:0], Icon: 132797
  ↓
[BAG_NEW_ITEMS_UPDATED] → New items flags updated
  ↓
[BAG_UPDATE] → Backpack (18→19 items, but item NOT shown yet!)
[BAG_UPDATE] → Keyring (ID:-2)
[BAG_UPDATE_DELAYED] → All updates completed
  ↓
[BAG_UPDATE] → Backpack (NOW shows Bottle in slot 15!)
[BAG_UPDATE] → Keyring (ID:-2)
[UNIT_INVENTORY_CHANGED] → player
[BAG_UPDATE_DELAYED] → All updates completed (again!)
```

**Critical:** Two `BAG_UPDATE_DELAYED` cycles - item appears ~400ms later in second cycle!

---

### 21. Consume Item (Use Potion/Food)

**Example:** Drink Bottle of Dalaran Noir

```
[BAG_UPDATE_COOLDOWN] → bagId: nil
  ↓
[BAG_UPDATE] → Backpack (item consumed, stack reduced or removed)
[BAG_UPDATE] → Keyring (ID:-2)
[BAG_UPDATE_DELAYED] → All updates completed
```

**Note:** No `ITEM_LOCK_CHANGED` events - item is consumed directly without locking

---

### 22. Open/Close Bank

**Opening bank:**

```
[Hook] OpenBag → bagId: 1, 2, 3, 4
[Hook] OpenAllBags → forceUpdate: table
  ↓
[BANKFRAME_OPENED]
  ↓
[Hook] ToggleBag → bagId: 0 → OPENED
[Hook] ToggleBackpack → BACKPACK OPENED (5 bags open)
```

**Closing bank:**

```
[Hook] CloseBag → bagId: 1, 2, 3, 4
[Hook] CloseAllBags
[Hook] CloseBag → bagId: 5, 6, 7, 8, 9, 10
  ↓
[BANKFRAME_CLOSED]
```

**Notes:**
- Opening bank auto-opens regular bags (1-4), same as vendor
- Closing bank closes regular bags (1-4) AND bank bags (5-10)
- No `BAG_UPDATE` events fire - only hooks and `BANKFRAME_OPENED`/`CLOSED`

---

### 23. Swap Items Within Bank Bags

**Example:** Swap Silkstream Cuffs ↔ Kingsblood in bank bag 7

```
[ITEM_LOCK_CHANGED] → Bank Bag 7, Slot 5 (Silkstream picked up)
[ITEM_LOCKED]
  ↓
[ITEM_LOCK_CHANGED] → Bank Bag 7, Slot 4 (Kingsblood picked up - swap)
[ITEM_LOCKED]
  ↓
[ITEM_LOCK_CHANGED] → Bank Bag 7, Slot 4 (Silkstream placed)
[ITEM_UNLOCKED]
[BAG_UPDATE] → Bank Bag 7 (shows swapped contents)
  ↓
[ITEM_LOCK_CHANGED] → Bank Bag 7, Slot 5 (Kingsblood placed)
[ITEM_UNLOCKED]
[BAG_UPDATE] → Bank Bag 7 (final state)
[BAG_UPDATE_DELAYED]
```

**Note:** Bank bags (5-10) use `BAG_UPDATE` like regular bags (not `PLAYERBANKSLOTS_CHANGED`)

---

### 24. Swap Items: Bag ↔ Bank

**Example:** Swap Robe (backpack) ↔ Jaina's Ring (bank)

```
[ITEM_LOCK_CHANGED] → Backpack, Slot 13 (Robe picked up)
[ITEM_LOCKED]
  ↓
[ITEM_LOCK_CHANGED] → Bank, Slot 18 (Jaina's Ring picked up - swap)
[ITEM_LOCKED]
  ↓
[ITEM_LOCK_CHANGED] → Backpack, Slot 13 (Jaina's Ring placed)
[ITEM_UNLOCKED]
[BAG_UPDATE] → Backpack (shows Jaina's Ring)
[BAG_UPDATE] → Keyring (ID:-2)
  ↓
[ITEM_LOCK_CHANGED] → Bank, Slot 18 (Robe placed)
[ITEM_UNLOCKED]
[PLAYERBANKSLOTS_CHANGED] → Slot 18 (Robe)
[BAG_UPDATE] → Backpack (duplicate)
[BAG_UPDATE] → Keyring
[BAG_CONTAINER_UPDATE]
[BAG_UPDATE_DELAYED]
```

**Note:** Bank container (ID:-1) triggers `PLAYERBANKSLOTS_CHANGED` + `BAG_CONTAINER_UPDATE`

---

### 25. Swap Items: Bank ↔ Bank Bag

**Example:** Swap Silk (bank) ↔ Khadgar's Whisker (bank bag 7)

```
[ITEM_LOCK_CHANGED] → Bank, Slot 18 (Silk picked up)
[ITEM_LOCKED]
  ↓
[ITEM_LOCK_CHANGED] → Bank Bag 7, Slot 8 (Khadgar's picked up - swap)
[ITEM_LOCKED]
  ↓
[ITEM_LOCK_CHANGED] → Bank, Slot 18 (Khadgar's placed)
[ITEM_UNLOCKED]
[PLAYERBANKSLOTS_CHANGED] → Slot 18 (Khadgar's)
[BAG_UPDATE] → Backpack (unchanged)
[BAG_UPDATE] → Keyring
[BAG_CONTAINER_UPDATE]
  ↓
[ITEM_LOCK_CHANGED] → Bank Bag 7, Slot 8 (Silk placed)
[ITEM_UNLOCKED]
[BAG_UPDATE] → Bank Bag 7 (shows Silk)
[BAG_UPDATE_DELAYED]
```

**Note:** Combines both bank event types - `PLAYERBANKSLOTS_CHANGED` for bank + `BAG_UPDATE` for bank bag

---

### 26. Move Item: Bank → Bag

**Example:** Move Goldthorn from bank slot 24 to bag 1 slot 1

```
[ITEM_LOCK_CHANGED] → Bank, Slot 24 (Goldthorn picked up)
[ITEM_LOCKED]
  ↓
[PLAYERBANKSLOTS_CHANGED] → Slot 24 (empty!)
[BAG_UPDATE] → Backpack (no change yet)
[BAG_UPDATE] → Keyring
[BAG_CONTAINER_UPDATE]
  ↓
[ITEM_LOCK_CHANGED] → Bag 1, Slot 1 (Goldthorn placed)
[ITEM_UNLOCKED]
[BAG_UPDATE] → Bag 1 (shows Goldthorn)
[BAG_UPDATE_DELAYED]
```

**Note:** Bank empties first (`PLAYERBANKSLOTS_CHANGED`), then destination bag updates

---

### 27. Move Item: Bag → Bank

**Example:** Move Silk from backpack slot 20 to bank slot 24

```
[ITEM_LOCK_CHANGED] → Backpack, Slot 20 (Silk picked up)
[ITEM_LOCKED]
  ↓
[BAG_UPDATE] → Backpack (item removed)
[BAG_UPDATE] → Keyring
  ↓
[ITEM_LOCK_CHANGED] → Bank, Slot 24 (Silk placed)
[ITEM_UNLOCKED]
[PLAYERBANKSLOTS_CHANGED] → Slot 24 (Silk)
[BAG_UPDATE] → Backpack (duplicate)
[BAG_UPDATE] → Keyring
[BAG_CONTAINER_UPDATE]
[BAG_UPDATE_DELAYED]
```

**Note:** Source bag empties first, then bank updates with `PLAYERBANKSLOTS_CHANGED`

---

## Key Observations

### Event Timing Patterns

| Action | First Event | Key Event | Last Event |
|--------|-------------|-----------|------------|
| Open/close bags | Hook | - | Hook |
| Open/close bank | Hook | `BANKFRAME_OPENED/CLOSED` | Hook |
| Move item | `ITEM_LOCK_CHANGED` | - | `BAG_UPDATE_DELAYED` |
| Swap items | `ITEM_LOCK_CHANGED` | - | `BAG_UPDATE_DELAYED` |
| Swap bag ↔ bank | `ITEM_LOCK_CHANGED` | `PLAYERBANKSLOTS_CHANGED` | `BAG_UPDATE_DELAYED` |
| Move bank ↔ bag | `ITEM_LOCK_CHANGED` | `PLAYERBANKSLOTS_CHANGED` | `BAG_UPDATE_DELAYED` |
| Split stack | `ITEM_LOCK_CHANGED` | `UNIT_INVENTORY_CHANGED` | `BAG_UPDATE_DELAYED` |
| Merge stack | `ITEM_LOCK_CHANGED` | `UNIT_INVENTORY_CHANGED` | `BAG_UPDATE_DELAYED` |
| Delete item | `ITEM_LOCK_CHANGED` (3×) | `UNIT_INVENTORY_CHANGED` | `BAG_UPDATE_DELAYED` |
| Equip/unequip | `ITEM_LOCK_CHANGED` or `UNIT_INVENTORY_CHANGED` | `PLAYER_EQUIPMENT_CHANGED` | `BAG_UPDATE_DELAYED` |
| Vendor sell/buyback | `ITEM_LOCK_CHANGED` | - | `BAG_UPDATE_DELAYED` |
| Buy new item | `ITEM_PUSH` | `BAG_NEW_ITEMS_UPDATED` | `BAG_UPDATE_DELAYED` (2×) |
| Consume item | `BAG_UPDATE_COOLDOWN` | - | `BAG_UPDATE_DELAYED` |

### Event Frequency by Operation

| Operation | ITEM_LOCK_CHG | ITEM_LOCK | ITEM_UNLOCK | BAG_UPDATE | PLAYERBANKSLOTS | BAG_CONTAINER | UNIT_INV | PLAYER_EQUIP | ITEM_PUSH | BAG_NEW | BAG_DELAYED |
|-----------|---------------|-----------|-------------|------------|-----------------|---------------|----------|--------------|-----------|---------|-------------|
| Move item | 2 | 2 | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| Swap items (bag) | 4 | 4 | 4 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| Swap items (bank bags) | 4 | 4 | 4 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| Swap bag ↔ bank | 4 | 4 | 4 | 4 | 1 | 1 | 0 | 0 | 0 | 0 | 1 |
| Swap bank ↔ bank bag | 4 | 4 | 4 | 3 | 1 | 1 | 0 | 0 | 0 | 0 | 1 |
| Move bank → bag | 2 | 2 | 2 | 3 | 1 | 1 | 0 | 0 | 0 | 0 | 1 |
| Move bag → bank | 2 | 2 | 2 | 4 | 1 | 1 | 0 | 0 | 0 | 0 | 1 |
| Split same bag | 2 | 2 | 2 | 3 | 0 | 0 | 2 | 0 | 0 | 0 | 1 |
| Split cross bag | 2 | 2 | 2 | 3 | 0 | 0 | 2 | 0 | 0 | 0 | 2 |
| Merge same bag | 3 | 3 | 3 | 2 | 0 | 0 | 2 | 0 | 0 | 0 | 1 |
| Merge cross bag | 3 | 3 | 3 | 2 | 0 | 0 | 2 | 0 | 0 | 0 | 1 |
| Delete item | 3 | 3 | 0 | 1 | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| Unequip → bag | 1 | 1 | 1 | 1 | 0 | 0 | 1 | 1 | 0 | 0 | 1 |
| Equip from bag | 2 | 2 | 2 | 1 | 0 | 0 | 1 | 1 | 0 | 0 | 1 |
| Swap equipped | 4 | 4 | 4 | 2 | 0 | 0 | 1 | 1 | 0 | 0 | 1 |
| Sell item | 1 | 1 | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| Buyback item | 1 | 0 | 1 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| Buy new item | 0 | 0 | 0 | 4 | 0 | 0 | 1 | 0 | 1 | 1 | 2 |
| Consume item | 0 | 0 | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |

### Pattern Recognition

**`ITEM_LOCK_CHANGED` occurrence count indicates operation complexity:**
- **2 locks:** Simple operation (move, split)
- **3 locks:** Complex operation (merge, delete)
- **4 locks:** Swap operation (items or equipment)

**`UNIT_INVENTORY_CHANGED` occurrence count indicates change type:**
- **0 times:** Pure location change (move, swap)
- **1 time:** Item destroyed (delete) or equipment interaction
- **2 times:** Stack count changed (split, merge)

**`BAG_UPDATE_DELAYED` occurrence count:**
- **1 time:** Synchronous operation (most operations)
- **2 times:** Asynchronous operation (cross-bag split, buying new items)

**`ITEM_PUSH` indicates:**
- Truly NEW items entering inventory (not existing items moving around)
- Fires BEFORE item is visible in bag contents
- Provides bag ID and icon, but not slot/item details

**`BAG_NEW_ITEMS_UPDATED` always fires immediately after `ITEM_PUSH`:**
- Updates "new item" visual flags (glow effect)
- Does not fire for buyback or moved items

**`ITEM_LOCKED` and `ITEM_UNLOCKED` are redundant:**
- `ITEM_LOCKED` fires immediately after `ITEM_LOCK_CHANGED` when picking up items
- `ITEM_UNLOCKED` fires immediately after `ITEM_LOCK_CHANGED` when placing items
- They provide no additional information beyond what `ITEM_LOCK_CHANGED` already provides
- **For addon implementation:** Only need to listen to `ITEM_LOCK_CHANGED`

**`BAG_CONTAINER_UPDATE` fires rarely:**
- Fires on login/reload (after individual `BAG_UPDATE` events)
- Fires during bank operations (alongside `BAG_UPDATE`)
- Signals a container-wide refresh (all bags/bank)
- Much less frequent than `BAG_UPDATE`

**`BAG_UPDATE_COOLDOWN` fires for consuming items:**
- Only observed when using consumables (potions, food)
- Fires with `bagId=nil` (no specific bag targeted)
- Fires BEFORE `BAG_UPDATE`
- Very specific use case - rarely needed for bag coloring

**`PLAYERBANKSLOTS_CHANGED` vs `BAG_UPDATE` for bank:**
- **Bank container (ID:-1):** Uses `PLAYERBANKSLOTS_CHANGED` event
- **Bank bags (ID:5-10):** Use `BAG_UPDATE` event (like regular bags)
- **Cross-container operations:** Trigger `BAG_CONTAINER_UPDATE` in addition

**Pattern:** Bank container has its own event type, but bank bags behave like regular bags!

### Asymmetric Behaviors

**Bag 0 (Backpack) Close Behavior:**
- **When closing via "B" key:** No hook fires, closes silently
- **When closing via click:** Only `ToggleBackpack` fires (no `ToggleBag(0)`)
- **When opening (both methods):** Both `ToggleBag(0)` and `ToggleBackpack` fire

**Split vs Merge Timing:**
- **Cross-bag splits:** Asynchronous (2 `BAG_UPDATE_DELAYED` cycles)
- **Cross-bag merges:** Synchronous (1 `BAG_UPDATE_DELAYED` cycle)

**Buying vs Buyback:**
- **Buy new item:** `ITEM_PUSH` + `BAG_NEW_ITEMS_UPDATED` + 2 update cycles
- **Buyback:** No `ITEM_PUSH`, only 1 update cycle (treated as moving existing item)

### Opening Bags - Different Methods

**Method 1: "B" Key (Toggle all)**
```
OpenBag(1, 2, 3, 4) individually → ToggleBag(0) + ToggleBackpack()
```

**Method 2: Vendor/Mailbox/Bank UI**
```
OpenBag(1, 2, 3, 4) individually → OpenAllBags(forceUpdate) → ToggleBag(0) + ToggleBackpack()
```

**Method 3: Individual bag icon clicks**
```
ToggleBag(bagId) only
```

### Keyring (-2) Always Updates

Every vendor transaction (sell, buyback, buy) triggers a keyring update even though keyring contents never change. This suggests WoW checks all containers during vendor operations.

### Equipment Slot Identification

In `ITEM_LOCK_CHANGED` events, equipment slots appear as:
```
bagId = equipmentSlotNumber
slotId = nil
```

This distinguishes equipment locks from bag item locks (which have both bagId and slotId).

---

## Summary

### Events By Category

**Bag Content Changes:**
- `BAG_UPDATE` - Bag contents changed (provides full bag contents)
- `BAG_UPDATE_DELAYED` - All pending updates completed (batch signal)
- `BAG_UPDATE_COOLDOWN` - Consumable item used (bagId=nil)
- `BAG_CONTAINER_UPDATE` - Container-wide refresh (login, bank)
- `ITEM_LOCK_CHANGED` - Item picked up or placed
- `ITEM_LOCKED` - Item locked (redundant with ITEM_LOCK_CHANGED)
- `ITEM_UNLOCKED` - Item unlocked (redundant with ITEM_LOCK_CHANGED)
- `ITEM_PUSH` - NEW item entering bags (not moves)
- `BAG_NEW_ITEMS_UPDATED` - New item flags updated (visual glow)

**Inventory State Changes:**
- `UNIT_INVENTORY_CHANGED` - Stack operations, deletion, equipment changes
- `PLAYER_EQUIPMENT_CHANGED` - Equipment slot changed (shows BEFORE state)

**UI/System:**
- `PLAYER_ENTERING_WORLD` - Login/reload (triggers initial bag updates)

### Hooks By Category

**Direct Bag Operations:**
- `ToggleBag(bagId)` - Individual bag toggle (click icon)
- `ToggleBackpack()` - Always fires with ToggleBag(0)

**Programmatic Bag Operations:**
- `OpenBag(bagId, forceUpdate)` - Open specific bag
- `CloseBag(bagId)` - Close specific bag
- `OpenAllBags(forceUpdate)` - Open all bags (UI systems)
- `CloseAllBags()` - Close all bags (UI systems)

### Events That Never Fired

- `BAG_OPEN` - Registered but never triggered
- `BAG_CLOSED` - Registered but never triggered
- `BAG_SLOT_FLAGS_UPDATED` - Registered but never triggered

These events either don't exist in Classic Era, or only fire under specific untested conditions.

---

## Untested Scenarios

### High Priority (Affects Bag Coloring)

1. **Looting from corpses/containers**
   - Confirm `ITEM_PUSH` behavior
   - Check if timing differs from vendor purchases

2. **Quest rewards**
   - Likely triggers `ITEM_PUSH`
   - May have unique timing patterns

### Medium Priority

3. **Mail attachments** - Taking items from mail
4. **Crafting/creating items** - Profession outputs
5. **Stacking to existing stacks automatically** (auto-loot)

### Lower Priority (May Not Affect Bag Coloring)

6. **Quest item usage** - One-time use quest items
7. **Action bar interactions** - Dragging items to/from action bars
8. **Linking items in chat** - Right-click operations
9. **Item tooltips** - Hovering over items

---

## Implementation Notes for cfItemColors

### Critical Events for Bag Coloring

**Primary event:** `BAG_UPDATE`
- Provides full bag contents after every change
- Most reliable event for recoloring bag slots
- Fires for ALL bag content changes

**Secondary events for optimization:**
- `BAG_UPDATE_DELAYED` - Signal that batch operations completed
- `ITEM_LOCK_CHANGED` - Early warning that specific slot will change
- `ITEM_PUSH` - New items entering bags (may need special handling)

**Events to ignore/avoid:**
- `ITEM_LOCKED` / `ITEM_UNLOCKED` - Redundant with `ITEM_LOCK_CHANGED`
- `BAG_CONTAINER_UPDATE` - Too rare and broad (login, bank); `BAG_UPDATE` is more precise
- `BAG_UPDATE_COOLDOWN` - Too specific (consumables only); `BAG_UPDATE` is more reliable

### Hook Usage

**Current implementation uses:**
- `ToggleBag` - For individual bag opens
- `ToggleBackpack` - For backpack/all bags opens
- `BAG_UPDATE` event - For content changes

**Consider adding:**
- `OpenAllBags` - Vendor/bank UI opening (already handled by BAG_UPDATE)
- Hooks are supplementary - events are primary source of truth

### Bag 0 (Backpack) Special Handling

- Does NOT fire `BAG_UPDATE` on login (unlike bags 1-4)
- Closes silently when using "B" key (no hook fires)
- Always fires `ToggleBackpack` in addition to `ToggleBag(0)` when opening

### Keyring (-2) Handling

- Always updates during vendor transactions
- May need to be explicitly ignored or handled separately
- Classic Era specific (removed in later expansions)

### Bank Handling

**Bank container (ID:-1) uses different events:**
- Listen to `PLAYERBANKSLOTS_CHANGED` for bank container slots (1-24)
- Bank container does NOT fire `BAG_UPDATE` - only `PLAYERBANKSLOTS_CHANGED`
- `BANKFRAME_OPENED`/`CLOSED` indicate when bank is available

**Bank bags (ID:5-10) work like regular bags:**
- Use `BAG_UPDATE` event (same as bags 0-4)
- 6 bank bag slots total (5-10, not 5-7)
- Handle them identically to regular bags

**Cross-container operations:**
- `BAG_CONTAINER_UPDATE` fires when items move between bags and bank
- Can be used as additional signal but `BAG_UPDATE` + `PLAYERBANKSLOTS_CHANGED` are sufficient

### Performance Considerations

**Triple BAG_UPDATE for same-bag splits:**
- Same bag splits fire 3 `BAG_UPDATE` events with identical contents
- Consider throttling/debouncing to avoid redundant recoloring

**Async cross-bag operations:**
- Cross-bag splits have 2 `BAG_UPDATE_DELAYED` cycles
- Destination bag updates ~400ms after source
- May cause visual delay in recoloring

**Buying new items timing:**
- `ITEM_PUSH` fires before item is visible
- Item appears in second `BAG_UPDATE` cycle (~400ms later)
- Don't try to color based on `ITEM_PUSH` alone - wait for `BAG_UPDATE`

---

## Next Steps

1. **Test bank operations** - Complete the investigation
2. **Test looting** - Confirm `ITEM_PUSH` behavior patterns
3. **Document bank event flows** - Update this document
4. **Finalize event strategy** - Determine optimal events for addon
