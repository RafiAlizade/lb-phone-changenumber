Config = {}

-- Framework Detection: 'auto', 'qbox', 'qb', 'esx'
Config.Framework = 'auto'

-- Command Configuration
Config.Command = 'changenumber' -- Main command name
Config.Aliases = { 'setphonenumber', 'setnumber', 'nomredeyisdir' } -- Alternative command aliases

-- Permissions
-- Players with this group (or console) can execute the command
Config.Permission = 'god' -- 'god', 'admin', or any framework rank
Config.UseAcePermission = true -- Also check ACE permission (e.g., group.god or command.changenumber)

-- Notification System: 'auto', 'ox_lib', 'qb', 'esx', 'chat'
Config.Notify = 'auto'

-- Database & Sync Options
Config.SyncFrameworkData = true -- Sync PlayerData & players/users database tables
Config.SendPhoneNotification = true -- Send LB-Phone push notification to target player

-- Language: 'en' (English), 'tr' (Turkish), 'az' (Azerbaijani)
Config.Locale = 'en'

Config.Locales = {
    ['en'] = {
        no_permission = 'You do not have permission to use this command.',
        usage = 'Usage: /%s [player_id] [new_phone_number]',
        player_offline = 'Player is offline or invalid ID.',
        phone_not_found = 'No registered phone found for this player.',
        number_taken = 'Phone number (%s) is already in use.',
        same_number = 'Target player already has this phone number (%s).',
        invalid_number = 'Phone number must contain digits only.',
        admin_success = 'Successfully changed phone number for %s (ID: %d) to %s.',
        target_notify = 'Your phone number has been updated to: %s',
        phone_notif_title = 'Network Carrier',
        phone_notif_desc = 'Your SIM card has been updated. New number: %s'
    },
    ['tr'] = {
        no_permission = 'Bu komutu kullanmak için yetkiniz yok.',
        usage = 'Kullanım: /%s [oyuncu_id] [yeni_numara]',
        player_offline = 'Oyuncu çevrimdışı veya geçersiz ID.',
        phone_not_found = 'Bu oyuncuya ait kayıtlı telefon bulunamadı.',
        number_taken = 'Bu telefon numarası (%s) zaten kullanımda.',
        same_number = 'Oyuncu zaten bu numarayı (%s) kullanıyor.',
        invalid_number = 'Numara yalnızca rakamlardan oluşmalıdır.',
        admin_success = '%s (ID: %d) adlı oyuncunun numarası başarıyla %s olarak güncellendi.',
        target_notify = 'Telefon numaranız güncellendi: %s',
        phone_notif_title = 'Hücresel Servis',
        phone_notif_desc = 'Hattınız yenilendi. Yeni numaranız: %s'
    },
    ['az'] = {
        no_permission = 'Bu komandadan istifadə etmək üçün yetkiniz yoxdur.',
        usage = 'İstifadə qaydası: /%s [oyunçu_id] [yeni_nömrə]',
        player_offline = 'Oyunçu oyunda deyil və ya ID yanlışdır.',
        phone_not_found = 'Bu oyunçuya aid qeydiyyatlı telefon tapılmadı.',
        number_taken = 'Bu telefon nömrəsi (%s) artıq istifadədədir.',
        same_number = 'Oyunçu onsuz da bu nömrədən (%s) istifadə edir.',
        invalid_number = 'Nömrə yalnız rəqəmlərdən ibarət olmalıdır.',
        admin_success = '%s (ID: %d) adlı oyunçunun nömrəsi uğurla %s olaraq dəyişdirildi.',
        target_notify = 'Telefon nömrəniz yeniləndi: %s',
        phone_notif_title = 'Mobil Operator',
        phone_notif_desc = 'Nömrəniz uğurla yeniləndi: %s'
    }
}
