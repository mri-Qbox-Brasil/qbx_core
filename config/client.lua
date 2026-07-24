return {
    statusIntervalSeconds = 5, -- how often to check hunger/thirst status to remove health if 0.
    loadingModelsTimeout = 60000, -- Waiting time for ox_lib to load the models before throws an error, for low specs pc

    pauseMapText = 'mri Qbox Brasil', -- Text shown above the map when ESC is pressed. If left empty 'FiveM' will appear

    characters = {
        imageURL = 'https://cfx-nui-mri_Qbox/web-side/icones/logo24.png',
        iconAnimation = 'fade',

        useExternalCharacters = false, -- Whether you have an external character management resource. (If true, disables the character management inside the core)
        enableDeleteButton = true, -- Whether players should be able to delete characters themselves.
        startingApartment = false, -- If set to false, skips apartment choice in the beginning (requires qbx_spawn if true)

        dateFormat = 'DD/MM/YYYY',
        dateMin = '01/01/1900', -- Has to be in the same format as the dateFormat config
        dateMax = '31/12/2006', -- Has to be in the same format as the dateFormat config

        limitNationalities = true, -- Setting this to false will allow people to enter whatever they want in the nationality field (To edit the list of nationalities, head to data/nationalities.lua)

        profanityWords = {
            ['bad word'] = true
        },

        locations = { -- Spawn locations for multichar, these are chosen randomly
            {
                pedCoords = vec4(-1037.19, -2737.09, 20.17, 328.73),
            },
        },
    },

    discord = {
        enabled = true, -- This will enable or disable the built in discord rich presence.

        appId = '', -- This is the Application ID (Replace this with you own)

        largeIcon = { -- To set this up, visit https://forum.cfx.re/t/how-to-updated-discord-rich-presence-custom-image/157686
            icon = 'logo_name', -- Here you will have to put the image name for the 'large' icon.
            text = 'Este é um ícone grande com texto', -- Here you can add hover text for the 'large' icon.
        },

        smallIcon = {
            icon = 'logo_name', -- Here you will have to put the image name for the 'small' icon.
            text = 'Este é um pequeno ícone com texto', -- Here you can add hover text for the 'small' icon.
        },

        firstButton = {
            text = 'Primeiro botão!',
            link = 'fivem://connect/localhost:30120',
        },

        secondButton = {
            text = 'Segundo botão!',
            link = 'fivem://connect/localhost:30120',
        }
    },

    --- Only used by QB bridge
    hasKeys = function(plate)
        return exports.mri_Qcarkeys:HaveTemporaryKey(plate) or exports.mri_Qcarkeys:HavePermanentKey(plate)
    end,
}
