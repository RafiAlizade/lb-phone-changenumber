# cfx-crp-changephonenumber

A lightweight, production-ready admin tool to change player phone numbers for **LB-Phone** across **Qbox**, **QBCore**, and **ESX Legacy** frameworks.

---

## Features

- **Direct LB-Phone Integration**: Updates the `phone_phones` table, preserving all user data (messages, photos, contacts, notes) through MySQL foreign key cascades.
- **Client Live Reload**: Triggers `exports["lb-phone"]:ReloadPhone()` on the target player's client immediately. No reconnects or relogs required.
- **Multi-Framework Sync**: Updates player metadata and persistent database records:
  - **Qbox / QBCore**: Updates `PlayerData.charinfo.phone` and the `charinfo` JSON column in the `players` table.
  - **ESX**: Updates `users.phone_number`.
- **Permission-Protected**: Restricted to high-tier administrative ranks (configurable, default: `god`). Supports both framework group checks and FiveM ACE permissions (`group.god`).
- **Conflict Prevention**: Validates target numbers against the database before applying changes to prevent `UNIQUE KEY` duplication errors.
- **Multi-Language Support**: Comes with built-in English, Turkish, and Azerbaijani locale dictionaries.

---

## Requirements

- [lb-phone](https://lbscripts.com/)
- [oxmysql](https://github.com/overextended/oxmysql)
- One of the supported frameworks:
  - [Qbox](https://github.com/Qbox-project/qbx_core)
  - [QBCore](https://github.com/qbcore-framework/qb-core)
  - [ESX Legacy](https://github.com/esx-framework/esx-legacy)

---

## Installation

1. Copy the `cfx-crp-changephonenumber` folder into your server's `resources/` directory.
2. Add the following to your `server.cfg` (ensure it starts **after** `lb-phone` and `oxmysql`):
   ```cfg
   ensure oxmysql
   ensure lb-phone
   ensure cfx-crp-changephonenumber
   ```
3. Restart your server or run `refresh` and `ensure cfx-crp-changephonenumber` in server console.

---

## Usage

```
/changenumber [player_id] [new_phone_number]
```

### Examples:
- `/changenumber 1 5209876543`
- `/setphonenumber 1 4801234567` (using alias)
- `/nomredeyisdir 1 2051234567` (using alias)

---

## Configuration (`config.lua`)

```lua
Config = {}

-- Framework: 'auto', 'qbox', 'qb', 'esx'
Config.Framework = 'auto'

-- Command name and aliases
Config.Command = 'changenumber'
Config.Aliases = { 'setphonenumber', 'setnumber', 'nomredeyisdir' }

-- Permissions (e.g., 'god', 'admin', 'superadmin')
Config.Permission = 'god'
Config.UseAcePermission = true -- Also check group.god or command.changenumber

-- Notifications: 'auto', 'ox_lib', 'qb', 'esx', 'chat'
Config.Notify = 'auto'

-- Database & sync options
Config.SyncFrameworkData = true     -- Sync PlayerData & players/users tables
Config.SendPhoneNotification = true -- Send push notification to target player's phone

-- Language: 'en', 'tr', 'az'
Config.Locale = 'en'
```

---

## Database Maintenance (`fix_phone_ids.sql`)

If your server previously used unique phones with random phone IDs (e.g. `11W47`), you can align all phone records to use `id = owner_id` (CitizenID/Identifier) as expected by LB-Phone in non-unique mode.

Run the queries provided in `fix_phone_ids.sql` in HeidiSQL or your database management tool:

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
local success, result = exports['cfx-crp-changephonenumber']:ChangePhoneNumber(targetId, '5209876543')
```
