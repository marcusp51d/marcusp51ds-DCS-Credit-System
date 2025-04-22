# DCS Credit-Based Weapon Purchase System

This script adds a credit-based economy system to **DCS World**, allowing mission makers to assign credit prices to player weapons and reward players with credits for kills. Players can view and manage their balance and loadout cost through the F10 menu.

---

## Features

- Assigns a **credit value** to each weapon (via `weaponCosts.lua`).
- Tracks **credits per player** using their UCID (via `credSave.lua`).
- Players are **charged** when they take off with weapons.
- Players are **refunded** for any unused weapons when they land.
- Credit balance and loadout cost can be checked from the **F10 radio menu**.
- Reward players for:
  - Killing AI units (`base_score`)
  - Killing other players (`kill_player_score`)
  - Destroying specific units using `vehicle_kill_values`.

---

## How It Works

1. **When a player enters an aircraft**:
   - Their UCID is tracked.
   - A menu is created under F10 to check loadout cost and credit balance.

2. **At takeoff**:
   - Weapon prices are checked.
   - If the player has enough credits, they're charged.
   - If not, their aircraft is destroyed.

3. **On landing**:
   - Remaining weapons are refunded based on their original value.

---

## Files Used

### `credSave.lua`

Stores the credits each player has by UCID.

Example:
```lua
scores = {
  ["123456789"] = 500,
  ["987654321"] = 250
}
```

### `weaponCosts.lua`

Specifies the price of each weapon. Any weapon not listed costs 0 credits.

Example:
```lua
sale_weapons = {
  ["FAB-100"] = 200,
  ["FAB-250"] = 250
}
```

Both files are stored in the **Documents** folder under a subfolder named as specified in the script (via `folderName`).

---

## Configuration

### Variables in the script:
| Variable             | Description                                        |
|----------------------|----------------------------------------------------|
| `folderName`         | Folder in your Documents directory to store data.  |
| `save_interval`      | How often (in seconds) to save credits.            |
| `base_score`         | Credits gained for killing an AI unit.             |
| `kill_player_score`  | Credits gained for killing another player.         |

### Special Rewards for Unit Kills
You can reward specific kills with custom credit values:

```lua
vehicle_kill_values = {
  ["unit name"] = 5
}
```

---

## Dependencies

This script **requires [MOOSE](https://flightcontrol-master.github.io/MOOSE_DOCS/)**. MOOSE **must be loaded before this script** in the mission.

---

## Player Menu (F10 Radio)

Players will see a menu called **"Credit System"** with the following options:

- **Current loadout cost**: View how much their current loadout will cost.
- **Credit balance**: View how many credits they currently have.

---

## Persistence

Credits are automatically saved and loaded from the disk, allowing players to retain their progress between missions or server sessions.

---

## Example Directory Structure

```
C:\Users\<YourUsername>\Documents\
└── mission1Scores\
    ├── credSave.lua
    └── weaponCosts.lua
```

Replace `mission1Scores` with your custom `folderName`.

---

## Notes

- The script is optimized for performance and saves credits regularly using the `save_interval`.
- Players who try to take off with unaffordable weapons will be automatically despawned (exploded).
- Players are encouraged to check their loadout **before takeoff** using the F10 menu.

---

## Example Setup in Mission

1. Place the MOOSE framework at the top of your mission script list.
2. Add this credit script below MOOSE.
3. Modify `weaponCosts.lua` and `credSave.lua` as needed for your scenario.
