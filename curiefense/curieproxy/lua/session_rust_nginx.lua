module(..., package.seeall)

local cjson       = require "cjson"

local curiefense  = require "curiefense"
local grasshopper = require "grasshopper"

local accesslog   = require "lua.accesslog"
local utils       = require "lua.utils"

local sfmt = string.format

local log_request = accesslog.nginx_log_request
local map_request = utils.nginx_map_request
local custom_response = utils.nginx_custom_response


function inspect(handle)

    local request_map = map_request(handle)

    local request_map_as_json = cjson.encode({
        headers = request_map.headers,
        cookies = request_map.cookies,
        attrs = request_map.attrs,
        args = request_map.args,
        geo = request_map.geo
    })

    local response, err = curiefense.inspect_request_map(request_map_as_json, grasshopper)

    if err then
        for _, r in ipairs(err) do
            handle:logErr(sfmt("curiefense.inspect_request_map error %s", r))
        end
    end

    if response then
        local response_table = cjson.decode(response)
        handle:logDebug("decision " .. response)
        request_map = response_table["request_map"]
        request_map.handle = handle
        if response_table["action"] == "custom_response" then
            custom_response(request_map, response_table["response"])
        end
    end

    log_request(request_map)

end