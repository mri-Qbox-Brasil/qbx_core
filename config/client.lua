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

        richPresence = 'Players {currentPlayers}/{maxPlayers}', -- Rich presence text. Placeholders: {id}, {charName}, {playerName}, {currentPlayers}, {maxPlayers}, {streetName}

        updateInterval = 15000, -- How often (ms) to refresh rich presence. Minimum 5000; Discord throttles faster updates.

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
    hasKeys = function(plate, vehicle)
        if GetResourceState('mri_Qcarkeys') == 'started' then
            return exports.mri_Qcarkeys:HaveTemporaryKey(plate) or exports.mri_Qcarkeys:HavePermanentKey(plate)
        end

        return GetResourceState('qbx_vehiclekeys') ~= 'started' or exports.qbx_vehiclekeys:HasKeys(vehicle)
    end,

    teleport = {
        fadeDuration = 650, -- Screen fade duration in milliseconds when teleporting
        groundSearchMaxZ = 850.0, -- Maximum Z height to search for ground when teleporting
        groundSearchStartZ = 950.0, -- Starting Z height for ground search loop
        groundSearchStep = -25.0, -- Z increment step for ground search loop
        loadSceneRadius = 50.0, -- Radius to load the scene around the teleport destination
        timeout = 1000, -- Timeout in milliseconds for scene loading and collision checks
    },

    getVehiclesInRadius = {
        defaultRadius = 5, -- Default search radius when retrieving nearby vehicles
    },

    meCommand = {
        distance = 25, -- Maximum distance at which players can see each other's /me text
        displayTime = 5000, -- Duration in milliseconds the /me text remains visible
    },

    setVehicleProperties = {
        timeout = 1000, -- Timeout in milliseconds when attempting to set vehicle properties
        waitInterval = 50, -- Wait time in milliseconds between property set attempts
    },

    initVehicle = {
        seats = {-1, 0}, -- List of seat indices to clear when initializing a vehicle
    },
}
