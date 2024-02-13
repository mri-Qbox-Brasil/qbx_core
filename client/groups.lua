---@type table<string, Job>
local jobs = {}
---@type table<string, Job>
local gangs = {}

---@return table<string, Job>
function GetJobs()
    return jobs
end

exports('GetJobs', GetJobs)

---@return table<string, Gang>
function GetGangs()
    return gangs
end

exports('GetGangs', GetGangs)

RegisterNetEvent('qbx_core:client:onJobUpdate', function(jobName, job)
    jobs[jobName] = job
end)

RegisterNetEvent('qbx_core:client:onGangUpdate', function(gangName, gang)
    gangs[gangName] = gang
end)

local function openSpecificJobAdminMenu(name)
    local job = jobs[name]

    local options = {
        {
            title = 'Edit Job',
        }
    }

    lib.registerContext({
        id = 'group_admin_menu_job',
        title = 'Modify ' .. name,
        onBack = OpenJobAdminMenu,
        options = options,
    })
    lib.showContext('group_admin_menu_job')
end

function OpenJobAdminMenu()
    local options = {}
    for name in pairs(jobs) do
        options[#options+1] = {
            title = name,
            onSelect = function()
                openSpecificJobAdminMenu(name)
            end
        }
    end

    lib.registerContext({
        id = 'group_admin_menu_jobs',
        title = 'Modify Jobs',
        menu = 'group_admin_menu_main',
        options = options,
    })
    lib.showContext('group_admin_menu_jobs')
end

lib.registerContext({
    id = 'group_admin_menu_main',
    title = 'Modify Groups',
    options = {
        {
            title = 'Jobs',
            description = 'Modify jobs',
            arrow = true,
            icon = 'bars',
        },
        {
            title = 'Gangs',
            description = 'Modify gangs',
            arrow = true,
            icon = 'bars',
        }
    }
})