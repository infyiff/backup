-- domain is gone so this doesn't work

if gravityController then
    pcall(loadstring(gravityController.Loader))
    return
end

local cloneref = cloneref or function(o) return o end
local HttpService = cloneref(game:GetService("HttpService"))

local rawUrl = "https://ixss.keybase.pub/rblx/gravityController/"
local baseUrl = "https://keybase.pub/ixss/rblx/gravityController/"
local htmlparser = loadstring(game:HttpGet("https://raw.githubusercontent.com/msva/lua-htmlparser/master/src/htmlparser.lua"))()

local hasToUpdate = true
local gravityController = nil

if pcall(function() readfile("gravityController.json") end) then
    local json = readfile("gravityController.json")
    if json then
        gravityController = HttpService:JSONDecode(json)
        hasToUpdate = gravityController.Version ~= game:HttpGet(rawUrl .. "Version.txt")
    end
end

if hasToUpdate then
    local getScripts = function()
        local ret = {}
        local text = game:HttpGet(baseUrl, false)

        local root = htmlparser.parse(text)
        local files = root:select(".file")

        for i, v in pairs(files) do
            if string.sub(v.attributes.href, string.len(v.attributes.href) - 3) == ".lua" then
                local name = string.sub(v.attributes.href, string.len(baseUrl) + 1, string.len(v.attributes.href) - 4)
                ret[name] = game:HttpGet(rawUrl .. name .. ".lua")
            elseif string.sub(v.attributes.href, string.len(v.attributes.href) - 3) == ".txt" then
                local name = string.sub(v.attributes.href, string.len(baseUrl) + 1, string.len(v.attributes.href) - 4)
                ret[name] = game:HttpGet(rawUrl .. name .. ".txt")
            end
        end

        return ret
    end

    gravityController = getScripts()
    writefile("gravityController.json", HttpService:JSONEncode(gravityController))
end

pcall(loadstring(gravityController.Loader))
pcall(function() getgenv().gravityController = gravityController end)
