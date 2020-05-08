local rawget = rawget
local rawset = rawset
local type = type
local error = error
local unpack = unpack
local setmetatable = setmetatable
local assert = assert
local print = print

module('tango.proxy')

local function new(proxy_conf,root_object,method_name)
  assert(proxy_conf)
  assert(proxy_conf.send_request)
  assert(proxy_conf.recv_response)
  
  local function rpc(...)
    local req = {...}
    for i=1,#req do
      if type(req[i]) == 'table' and req[i].__tango_root_object then
        req[i] = { __ref_id=req[i].__tango_root_object }
      end
    end
    proxy_conf.send_request(req)
    local response = proxy_conf.recv_response()
    for i=2,#response do
      if type(response[i]) == 'table' and response[i].__ref_id then
        response[i] = new(proxy_conf,response[i].__ref_id)
      end
    end
    return response
  end
    
    return setmetatable(
      {
        __tango_root_object = root_object or "",
        __tango_method_name = method_name,
        __tango_proxy_conf = proxy_conf
      },
      {
        __index= 
          function(self,sub_method_name)
            local new_method_name
            if not method_name then
              new_method_name = sub_method_name
            else
              new_method_name = method_name..'.'..sub_method_name
            end
            -- create new call proxy
            return new(proxy_conf,root_object,new_method_name)
          end,        
        __call=
          function(self,...)
            local response = rpc(root_object or "", method_name, ...)
            if response[1] ~= true then
              error(response[2],2)
            end
            return unpack(response,2)
          end,
        __newindex=
          function(self, elem, val)
            self[elem](val)
          end
      })
  end

local rproxies = {}

local function root(proxy)
    local root_object = rawget(proxy,'__tango_root_object')
    local method_name = rawget(proxy,'__tango_method_name')
    local proxy_conf = rawget(proxy,'__tango_proxy_conf')
    local rproxy
    if not rproxies[proxy_conf.send_request] then
      rproxy = new(proxy_conf,root_object)
      rproxies[proxy_conf.send_request] = rproxy
    end
    return rproxies[proxy_conf.send_request],method_name
  end

function ref(proxy,...)
    local rproxy,create_method = root(proxy)
    return setmetatable(
      {
        __tango_id = rproxy.tango.ref_create(create_method,...),
        __tango_proxy = rproxy
      },
      {
        __index = 
          function(self,method_name)
            return setmetatable(
              {                
              },
              {
                __call =
                  function(_,ref,...)
                    local proxy = rawget(ref,'__tango_proxy')
                    return proxy.tango.ref_call(rawget(self,'__tango_id'),method_name,...)
                  end
              })
          end
      })                      
  end

function unref(ref)
    local proxy = rawget(ref,'__tango_proxy')
    local id = rawget(ref,'__tango_id')
    proxy.tango.ref_release(id)
  end

return {
  new = new,
  ref = ref,
  unref = unref
}
