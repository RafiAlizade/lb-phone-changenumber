Config = {}

-- Framework: 'auto', 'qbox', 'qb', 'esx'
Config.Framework = 'auto'

-- Command Configuration (ox_lib addCommand)
Config.Command = 'nomredeyisdir'
Config.Restricted = 'group.god' -- Permission group (e.g. 'group.god', 'group.admin')

-- Notification Mode: 'auto', 'ox_lib', 'qb', 'esx', 'chat'
Config.Notify = 'auto'

-- In-Phone Push Notification (LB-Phone)
Config.SendPhoneNotification = true

-- Active Language: 'az' (Azerbaijani), 'tr' (Turkish), 'en' (English)
Config.Locale = 'az'

Config.Messages = {
    ['az'] = {
        command_help = 'Oyuncunun telefon nömrəsini dəyiş',
        param_id_help = 'Oyunçu ID',
        param_nomre_help = 'Yeni telefon nömrəsi',
        no_permission = 'Bu komandadan yalnız group.god istifadə edə bilər!',
        player_not_found = 'Qeyd olunan ID tapılmadı və ya oyunçu oyunda deyil!',
        invalid_number = 'Nömrə yalnız rəqəmlərdən ibarət olmalıdır!',
        phone_not_found = 'Bu oyunçunun sistemdə qeydiyyatlı telefonu tapılmadı!',
        same_number = 'Oyunçu onsuz da bu nömrədən (%s) istifadə edir!',
        number_taken = 'Bu telefon nömrəsi (%s) artıq başqa bir istifadəçi tərəfindən istifadə olunur!',
        admin_success = '[UĞURLU] %s (ID: %d) adlı oyunçunun nömrəsi dəyişdirildi. Yeni nömrə: %s',
        target_success = 'Admin tərəfindən telefon nömrəniz dəyişdirildi! Yeni nömrəniz: %s',
        phone_title = 'Mobil Operator',
        phone_notif = 'Nömrəniz uğurla yeniləndi: %s'
    },
    ['tr'] = {
        command_help = 'Oyuncunun telefon numarasını değiştir',
        param_id_help = 'Oyuncu ID',
        param_nomre_help = 'Yeni telefon numarası',
        no_permission = 'Bu komutu yalnızca group.god yetkisine sahip kişiler kullanabilir!',
        player_not_found = 'Belirtilen ID bulunamadı veya oyuncu çevrimdışı!',
        invalid_number = 'Numara yalnızca rakamlardan oluşmalıdır!',
        phone_not_found = 'Bu oyuncuya ait kayıtlı telefon bulunamadı!',
        same_number = 'Oyuncu zaten bu numarayı (%s) kullanıyor!',
        number_taken = 'Bu telefon numarası (%s) zaten kullanımda!',
        admin_success = '[BAŞARILI] %s (ID: %d) adlı oyuncunun numarası güncellendi. Yeni numara: %s',
        target_notify = 'Yetkili tarafından telefon numaranız güncellendi! Yeni numaranız: %s',
        phone_title = 'Hücresel Servis',
        phone_notif = 'Hattınız yenilendi. Yeni numaranız: %s'
    },
    ['en'] = {
        command_help = 'Change player phone number',
        param_id_help = 'Player ID',
        param_nomre_help = 'New phone number',
        no_permission = 'Only group.god can execute this command!',
        player_not_found = 'Target player is offline or invalid ID!',
        invalid_number = 'Phone number must contain digits only!',
        phone_not_found = 'No registered phone found for this player!',
        same_number = 'Player is already using this phone number (%s)!',
        number_taken = 'Phone number (%s) is already in use!',
        admin_success = '[SUCCESS] Changed phone number for %s (ID: %d). New number: %s',
        target_success = 'Your phone number has been updated by an admin! New number: %s',
        phone_title = 'Network Carrier',
        phone_notif = 'Your phone number has been updated: %s'
    }
}
