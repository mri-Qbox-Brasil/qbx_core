return {
    serverName = 'mri-Qbox BRASIL',
    defaultSpawn = vec4(-66.24, -822.09, 285.61 -1, 78.8),
    notifyPosition = 'center-left', -- 'top' | 'top-right' | 'top-left' | 'bottom' | 'bottom-right' | 'bottom-left'
    ---@type { name: string, amount: integer, metadata: fun(source: number): table }[]
    starterItems = { -- Character starting items
        { name = 'phone', amount = 1 },
        { name = 'id_card', amount = 1, metadata = function(source)
                assert(GetResourceState('qbx_idcard') == 'started', 'qbx_idcard resource not found. Required to give an id_card as a starting item')
                return exports.qbx_idcard:GetMetaLicense(source, {'id_card'})
            end
        },
        { name = 'driver_license', amount = 1, metadata = function(source)
                assert(GetResourceState('qbx_idcard') == 'started', 'qbx_idcard resource not found. Required to give an id_card as a starting item')
                return exports.qbx_idcard:GetMetaLicense(source, {'driver_license'})
            end
        },
    }
}
