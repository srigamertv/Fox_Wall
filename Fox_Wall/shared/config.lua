Config = {}

-- auto = detecta VORP/RSG automaticamente.
-- Também aceita: 'vorp', 'rsg' ou 'standalone'.
Config.Framework = 'auto'

Config.Command = 'wall'
Config.DrawDistance = 50.0
Config.RefreshInterval = 5000
Config.RenderInterval = 5
Config.MinimumRequestInterval = 1000
Config.HideCrouchedPlayers = true
Config.ShowLocalPlayer = true
Config.ShowTalkingStatus = true
Config.ServerDistanceFilter = true
Config.ServerDistanceBuffer = 15.0

Config.Permission = {
    Enabled = true,
    Ace = 'fox.wall',

    VORP = {
        -- O VORP pode ter permissão no grupo da conta (users.group)
        -- ou no grupo do personagem (characters.group). O script verifica os dois.
        CheckUserGroup = true,
        CheckCharacterGroup = true,
        Groups = {
            admin = true,
            administrador = true,
            superadmin = true,
            moderator = true,
            mod = true,
            god = true
        }
    },

    RSG = {
        -- Permissão nativa do RSG Core (ACE / RSGCore.Functions.HasPermission).
        CheckCorePermission = true,
        Permissions = {
            god = true,
            developer = true,
            headadmin = true,
            admin = true,
            mod = true
        },

        -- Compatibilidade opcional com a tabela admin_roles da base enviada.
        -- Ative somente se quiser que o Wall também aceite o role salvo no banco.
        CheckAdminRolesTable = false,
        AdminRolesTable = 'admin_roles',
        Roles = {
            admin = true,
            administrator = true,
            administrador = true,
            superadmin = true,
            god = true
        }
    }
}

Config.Messages = {
    NoPermission = 'Você não tem permissão para usar o wall.',
    Enabled = 'Wall ativado.',
    Disabled = 'Wall desativado.'
}

Config.Debug = false
