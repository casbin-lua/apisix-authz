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
local CasbinEnforcer

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
    priority = 2560,
    type = 'auth',
    name = plugin_name,
    schema = schema
}

function _M.rewrite(conf)
    -- creates an enforcer when request sent for the first time
    if not CasbinEnforcer then
        CasbinEnforcer = Enforcer:new(conf.model_path, conf.policy_path)
    end

    local path = ngx.var.request_uri
    local method = ngx.var.request_method
    local username = get_headers()[conf.username]
    if not username then username = "anonymous" end

    if path and method and username then
        if not CasbinEnforcer:enforce(username, path, method) then
            return 403, {message = "Access Denied"}
        end
    else
        return 403, {message = "Access Denied"}
    end
end

-- subject, object, action
local function addPolicy()
    local headers = get_headers()
    local type = headers["type"]

    if type == "p" then
        local subject = headers["subject"]
        local object = headers["object"]
        local action = headers["action"]

        if not subject or not object or not action then
            return 400, {message = "Invalid policy request."}
        end

        if CasbinEnforcer:AddPolicy(subject, object, action) then
            return 200, {message = "Successfully added policy."}
        else
            return 400, {message = "Invalid policy request."}
        end
    elseif type == "g" then
        local user = headers["user"]
        local role = headers["role"]

        if not user or not role then
            return 400, {message = "Invalid policy request."}
        end

        if CasbinEnforcer:AddGroupingPolicy(user, role) then
            return 200, {message = "Successfully added grouping policy."}
        else
            return 400, {message = "Invalid policy request."}
        end
    else
        return 400, {message = "Invalid policy type."}
    end
end

local function removePolicy()
    local headers = get_headers()
    local type = headers["type"]

    if type == "p" then
        local subject = headers["subject"]
        local object = headers["object"]
        local action = headers["action"]

        if not subject or not object or not action then
            return 400, {message = "Invalid policy request."}
        end

        if CasbinEnforcer:RemovePolicy(subject, object, action) then
            return 200, {message = "Successfully removed policy."}
        else
            return 400, {message = "Invalid policy request."}
        end
    elseif type == "g" then
        local user = headers["user"]
        local role = headers["role"]

        if not user or not role then
            return 400, {message = "Invalid policy request."}
        end

        if CasbinEnforcer:RemoveGroupingPolicy(user, role) then
            return 200, {message = "Successfully removed grouping policy."}
        else
            return 400, {message = "Invalid policy request."}
        end
    else
        return 400, {message = "Invalid policy type."}
    end
end

-- subject, object, action
local function hasPolicy()
    local headers = get_headers()
    local type = headers["type"]

    if type == "p" then
        local subject = headers["subject"]
        local object = headers["object"]
        local action = headers["action"]

        if not subject or not object or not action then
            return 400, {message = "Invalid policy request."}
        end

        if CasbinEnforcer:HasPolicy(subject, object, action) then
            return 200, {data = "true"}
        else
            return 200, {data = "false"}
        end
    elseif type == "g" then
        local user = headers["user"]
        local role = headers["role"]

        if not user or not role then
            return 400, {message = "Invalid policy request."}
        end

        if CasbinEnforcer:HasGroupingPolicy(user, role) then
            return 200, {data = "true"}
        else
            return 200, {data = "false"}
        end
    else
        return 400, {message = "Invalid policy type."}
    end
end

local function getPolicy()
    local headers = get_headers()
    local type = headers["type"]

    if type == "p" then
        local policy = CasbinEnforcer:GetPolicy()
        if policy then
            return 200, {data = policy}
        else
            return 400
        end
    elseif type == "g" then
        local groupingPolicy = CasbinEnforcer:GetGroupingPolicy()
        if groupingPolicy then
            return 200, {data = groupingPolicy}
        else
            return 400
        end
    else
        return 400, {message = "Invalid policy type."}
    end
end

local function savePolicy()
    local _, err = pcall(function ()
        CasbinEnforcer:savePolicy()
    end)
    if not err then
        return 200, {message = "Successfully saved policy."}
    else
        core.log.error("Save Policy error: " .. err)
        return 400, {message = "Failed to save policy, see logs."}
    end
end

function _M.api()
    return {
        {
            methods = {"POST"},
            uri = "/apisix/plugin/casbin/add",
            handler = addPolicy,
        },
        {
            methods = {"POST"},
            uri = "/apisix/plugin/casbin/remove",
            handler = removePolicy,
        },
        {
            methods = {"GET"},
            uri = "/apisix/plugin/casbin/has",
            handler = hasPolicy,
        },
        {
            methods = {"GET"},
            uri = "/apisix/plugin/casbin/get",
            handler = getPolicy,
        },
        {
            methods = {"POST"},
            uri = "/apisix/plugin/casbin/save",
            handler = savePolicy,
        },
        }
end

function _M.check_schema(conf)
    return core.schema.check(schema, conf)
end

return _M