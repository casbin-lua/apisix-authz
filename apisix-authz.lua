--Copyright 2021 The casbin Authors. All Rights Reserved.
--
--Licensed under the Apache License, Version 2.0 (the "License");
--you may not use this file except in compliance with the License.
--You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
--Unless required by applicable law or agreed to in writing, software
--distributed under the License is distributed on an "AS IS" BASIS,
--WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--See the License for the specific language governing permissions and
--limitations under the License.

local Enforcer = require("casbin")
local core = require("apisix.core")
local get_headers = ngx.req.get_headers

-- e is the Casbin Enforcer
local e

local plugin_name = "apisix-authz"

local schema = {
    type = "object",
    properties = {
        model_path = { type = "string" },
        policy_path = { type = "string" },
        username = { type = "string"}
    },
    required = {"model_path", "policy_path", "username"},
    additionalProperties = false
}

local _M = {
    version = 0.1,
    priority = 2555,
    type = 'auth',
    name = plugin_name,
    schema = schema
}

function _M.rewrite(conf)
    -- creates an enforcer when request sent for the first time
    if not e then
        e = Enforcer:new(conf.model_path, conf.policy_path)
    end

    local path = ngx.var.request_uri
    local method = ngx.var.request_method
    local username = get_headers()[conf.username]

    if path and method and username then
        if not e:enforce(username, path, method) then
            return 403, {message = "Access Denied"}
        end
    else
        return 403, {message = "Access Denied"}
    end
end

function _M.check_schema(conf)
    return core.schema.check(schema, conf)
end

return _M