<!-- Developed by rafializade -->
# lb-phone-changenumber

A lightweight, production-ready admin tool built with **ox_lib** to change player phone numbers live for **LB-Phone** across **Qbox**, **QBCore**, and **ESX Legacy** frameworks.

---

## Features

- **ox_lib Command (`lib.addCommand`)**: Uses `ox_lib` parameter validation and permission restriction (`restricted = 'group.god'`).
- **Direct LB-Phone Integration**: Updates the `phone_phones` table, preserving all user data (messages, photos, contacts, notes) through MySQL foreign key cascades.
- **Client Live Reload**: Triggers `exports["lb-phone"]:ReloadPhone()` on the target player's client immediately. No reconnects or relogs required.
- **Multi-Framework Sync**: Updates player metadata and persistent database records:
  - **Qbox / QBCore**: Updates `PlayerData.charinfo.phone` and the `charinfo` JSON column in the `players` table.
  - **ESX**: Updates `users.phone_number`.
- **Conflict Prevention**: Validates target numbers against the database before applying changes to prevent `UNIQUE KEY` duplication errors.
- **Multi-Language Support**: English by default (`en`), with built-in Azerbaijani (`az`) and Turkish (`tr`) locales.

---

## Requirements

- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)
- [lb-phone](https://lbscripts.com/)
- One of the supported frameworks:
  - [Qbox](https://github.com/Qbox-project/qbx_core)
  - [QBCore](https://github.com/qbcore-framework/qb-core)
  - [ESX Legacy](https://github.com/esx-framework/esx-legacy)

---

## Installation

1. Place the `lb-phone-changenumber` folder into your server's `resources/` directory.
2. Add the following to your `server.cfg` (ensure it starts **after** `ox_lib`, `oxmysql`, and `lb-phone`):
   ```cfg
   ensure ox_lib
   ensure oxmysql
   ensure lb-phone
   ensure lb-phone-changenumber
   ```
3. Restart your server or run `refresh` and `ensure lb-phone-changenumber` in the server console.

---

## Usage

```
/nomredeyisdir [player_id] [new_phone_number]
```

*(You can also use `/changenumber` or `/setnumber`)*

### Example:
- `/nomredeyisdir 1 5209876543`

---

## Configuration (`config.lua`)

```lua
Config = {}

-- Framework: 'auto', 'qbox', 'qb', 'esx'
Config.Framework = 'auto'

-- Command name (ox_lib addCommand)
Config.Command = 'nomredeyisdir'
Config.Aliases = { 'changenumber', 'setnumber', 'setphonenumber' }
Config.Restricted = 'group.god' -- Permission group

-- Notifications: 'auto', 'ox_lib', 'qb', 'esx', 'chat'
Config.Notify = 'auto'

-- In-Phone Push Notification (LB-Phone)
Config.SendPhoneNotification = true

-- Active Language: 'en' (default), 'az', 'tr'
Config.Locale = 'en'
```

---

## Database Maintenance (`fix_phone_ids.sql`)

If your server previously used unique phones with random phone IDs (e.g. `11W47`), you can align all phone records to use `id = owner_id` (CitizenID/Identifier) as expected by LB-Phone in non-unique mode.

Run the queries provided in `fix_phone_ids.sql` in HeidiSQL:

```sql
-- 1. Remove older duplicate phones for the same owner (preserves the most recent one):
DELETE p1 FROM `phone_phones` p1
INNER JOIN `phone_phones` p2 
WHERE p1.`owner_id` = p2.`owner_id` 
  AND (p1.`last_seen` < p2.`last_seen` OR (p1.`last_seen` = p2.`last_seen` AND p1.`id` < p2.`id`));

-- 2. Align id to owner_id:
UPDATE `phone_phones` SET `id` = `owner_id`;
```

---

## Exports

### Server-side
```lua
local success, result = exports['lb-phone-changenumber']:ChangePhoneNumber(targetId, '5209876543')
```
