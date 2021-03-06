-- -*- coding: utf-8 -*-
-- @Date    : 2016-12-12 15:56:46
-- @Author  : yuzukwok (AlexaZhou@163.com)
-- @Link    : 
-- @Disc    : basicauth

local _M = {}

local VeryNginxConfig = require "VeryNginxConfig"
local request_tester = require "request_tester"
local responses = require "tools.responses"
local realm = 'Basic realm=request_credentials '
local utils = require "tools.utils"
local constants = require "constants"


local function retrieve_credentials(request, header_name, conf)
  local username, password
  local authorization_header = request.get_headers()[header_name]

  if authorization_header then
    local iterator, iter_err = ngx.re.gmatch(authorization_header, "\\s*[Bb]asic\\s*(.+)")
    if not iterator then
      ngx.log(ngx.ERR, iter_err)
      return
    end

    local m, err = iterator()
    if err then
      ngx.log(ngx.ERR, err)
      return
    end

    if m and table.getn(m) > 0 then
      local decoded_basic = ngx.decode_base64(m[1])
      if decoded_basic then
        local basic_parts = utils.split(decoded_basic, ":")
        username = basic_parts[1]
        password = basic_parts[2]
      end
    end
  end

  --if conf.hide_credentials then
  --  request.clear_header(header_name)
  --end

  return username, password
end


--- Validate a credential in the Authorization header against one fetched from the database.
-- @param credential The retrieved credential from the username passed in the request
-- @param given_password The password as given in the Authorization header
-- @return Success of authentication
local function validate_credentials(credential, given_password)
  return credential.password == given_password
end

local function load_credential_from_config(username,users)
  local credential={}
  credential.username=username
  credential.password=users[username]
  return credential
end

function _M.filter()

    if VeryNginxConfig.configs["basic_auth_enable"] ~= true and VeryNginxConfig.configs["basic_auth_rule"]  ~= nil then
        return
    end

    local matcher_list = VeryNginxConfig.configs['matcher']
        
    for i, rule in ipairs( VeryNginxConfig.configs["basic_auth_rule"] ) do
        local enable = rule['enable']
        local matcher = matcher_list[ rule['matcher'] ] 
        if enable == true and request_tester.test( matcher ) == true then
            --找到配置

            --当前请求没有验证头
              -- If both headers are missing, return 401
            if not (ngx.req.get_headers()["authorization"] or ngx.req.get_headers()["proxy-authorization"]) then
                    --TODO 提示文本可以输入
                    ngx.header["WWW-Authenticate"] = realm
                    return responses.send_HTTP_UNAUTHORIZED()
            end

            --浏览器已发送认证信息，验证一下
            local credential
            local given_username, given_password = retrieve_credentials(ngx.req, "proxy-authorization", conf)
            if given_username then                 
                   credential = load_credential_from_config(given_username,rule['users'])               
            end

             -- Try with the authorization header
            if not credential then
                given_username, given_password = retrieve_credentials(ngx.req, "authorization", conf)
                credential = load_credential_from_config(given_username,rule['users'])                 
            end
            --验证密码
             if not credential or not validate_credentials(credential, given_password) then
                  --TODO 返回响应可以设置
                  return responses.send_HTTP_FORBIDDEN("Invalid authentication credentials")
             end

             --标识
             ngx.req.set_header(constants.HEADERS.CREDENTIAL_USERNAME, credential.username)
        end
    end

    
    

   


end

return _M
