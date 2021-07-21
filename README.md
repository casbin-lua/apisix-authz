# apisix-authz

apisix-authz is an authorization plugin for APISIX based on [lua-casbin](https://github.com/casbin/lua-casbin/).

## Installation

Ensure you have Casbin's system dependencies installed by:
```
sudo apt install gcc libpcre3 libpcre3-dev
```

Install Casbin's latest release (currently v1.16.1) from LuaRocks by:
```
sudo luarocks install https://raw.githubusercontent.com/casbin/lua-casbin/master/casbin-1.16.1-1.rockspec
```

Then clone this repo and copy the `apisix-authz.lua` file to your plugin directory (modify the plugin according to your situation if you wish to):
```
git clone https://github.com/casbin-lua/apisix-authz
cp apisix-authz/apisix-authz.lua path_to_apisix/plugins/apisix-authz.lua
```

And finally append the plugins section of your `conf/config.yaml` with `apisix-authz` to something like this (more on this [here](https://github.com/apache/apisix/blob/master/docs/en/latest/plugin-develop.md#:~:text=To%20enable%20your%20plugin%2C%20copy%20this%20plugin%20list%20into%20conf/config.yaml%2C%20and%20add%20your%20plugin%20name.%20For%20instance%3A)):
```
plugins:                          # plugin list
...
  - apisix-authz
```

## Configuration

You can add this plugin globally or on any route/service by sending a request through the Admin API. For example, for adding it to some route:
```
curl http://127.0.0.1:9080/apisix/admin/routes/1 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
    "uri": "/*",
    "plugins": {
        "apisix-authz": {
            "model_path": "/path/to/model_path.conf",
            "policy_path": "/path/to/policy_path.csv",
            "username": "user"
        }
    },
    "upstream": {
        "type": "roundrobin",
        "nodes": {
            "example.com": 1
        }
    }
}'

```

For adding this globally:
```
curl -X PUT \
  https://127.0.0.1:9080/apisix/admin/global_rules/1 \
  -H 'Content-Type: application/json' \
  -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' \
  -d '{
        "plugins": {
            "apisix-authz": {
                "model_path": "/path/to/model_path.conf",
                "policy_path": "/path/to/policy_path.csv",
                "username": "user"
            }
        }
    }'
```

<table><thead>
<tr>
<th>Parameter</th>
<th>Description</th>
</tr>
</thead><tbody>
<tr>
<td><code>model_path</code><br><em>required</em></td>
<td>The system path of your Casbin model file</td>
</tr>
<tr>
<td><code>policy_path</code><br><em>required</em></td>
<td>The system path of your Casbin policy file</td>
</tr>
<td><code>username</code><br><em>required</em></td>
<td>The username field from your headers, this will be used as the subject in the policy enforcement</td>
</tr>
</tbody></table>

As per the current configuration, if the request is authorized, the execution will proceed normally. While if it is not authorized, it will return "Access Denied" message with the 403 exit code and stop any further execution.

## Development

If you wish to customize this according to your scenario, you can do so by customizing the apisix-authz.lua file from your plugins directory.

## Documentation

The authorization determines a request based on `{subject, object, action}`, which means what `subject` can perform what `action` on what `object`. In this plugin, the meanings are:
1. `subject`: the logged-in username as passed in the header
2. `object`: the URL path for the web resource like "dataset1/item1"
3. `action`: HTTP method like GET, POST, PUT, DELETE, or the high-level actions you defined like "read-file", "write-blog"
For how to write authorization policy and other details, please refer to the [Casbin's documentation](https://casbin.org/).

## Getting Help

- [Casbin](https://casbin.org/)
- [Lua Casbin](https://github.com/casbin/lua-casbin/)

## License

This project is under the Apache 2.0 License.