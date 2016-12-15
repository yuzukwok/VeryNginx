-- -*- coding: utf-8 -*-
-- @Date    : 2016-12-12 15:56:46
-- @Author  : yuzukwok (AlexaZhou@163.com)
-- @Link    : 
-- @Disc    : basicauth

local _M = {}

local VeryNginxConfig = require "VeryNginxConfig"
local request_tester = require "request_tester"
local req_set_header = ngx.req.set_header
local req_get_headers = ngx.req.get_headers
local uuid = require("tools.utils").uuid
local worker_uuid
local worker_counter

local fmt = string.format
local now = ngx.now
local worker_pid = ngx.worker.pid()

local generators = setmetatable({
  ["uuid"] = function()
    return uuid()
  end,
  ["uuid#counter"] = function()
    worker_counter = worker_counter + 1
    return worker_uuid.."#"..worker_counter
  end,
  ["tracker"] = function()
    local var = ngx.var
    return fmt("%s-%s-%d-%s-%s-%0.3f",
      var.server_addr,
      var.server_port,
      worker_pid,
      var.connection, -- connection serial number
      var.connection_requests, -- current number of requests made through a connection
      now() -- the current time stamp from the nginx cached time.
    )
  end,
}, { __index = function(self, generator)
    ngx.log(ngx.ERR, "Invalid generator: "..generator)
end
})

function _M.init()
  worker_uuid = uuid()
  worker_counter = 0
end


function _M.filter()

    if VeryNginxConfig.configs["correlation_id_enable"] ~= true and VeryNginxConfig.configs["correlation_id_rule"]  ~= nil then
        return
    end

    local matcher_list = VeryNginxConfig.configs['matcher']
        
    for i, rule in ipairs( VeryNginxConfig.configs["correlation_id_rule"] ) do
        local enable = rule['enable']
        local matcher = matcher_list[ rule['matcher'] ] 
        if enable == true and request_tester.test( matcher ) == true then
            --找到配置
             -- Set header for upstream
                    local header_value = req_get_headers()[rule['header_name']]
                    if not header_value then
                    -- Generate the header value
                    header_value = generators[rulep['generator']]()
                    req_set_header(rule['header_name'], header_value)
                    end
            
        end
    end



end

return _M
