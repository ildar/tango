local rawget = rawget
local rawset = rawset
local type = type
local error = error
local unpack = unpack
local setmetatable = setmetatable
local print = print

module('tango.proxy')

function new(send_request,recv_response,method_name)
    return setmetatable(
      {
        __tango_method_name = method_name,
        __tango_send_request = send_request,
        __tango_recv_response = recv_response
      },
      {
        __index= 
          function(self,sub_method_name)
            -- look up if proxy already exists
            local proxy = rawget(self,sub_method_name)
            if not proxy then 
              local new_method_name
              if not method_name then
                new_method_name = sub_method_name
              else
                new_method_name = method_name..'.'..sub_method_name
              end
              -- create new call proxy
              proxy = new(send_request,recv_response,new_method_name)
              -- store for subsequent access
              rawset(self,sub_method_name,proxy)
            end                            
            return proxy
          end,        
        __call=
          function(self,...)
            send_request({method_name,...})
            local response = recv_response()
            if response[1] == true then
              return unpack(response,2)
            else
              error(response[2],2)
            end
          end
      })
  end

local rproxies = {}

local function root(proxy)
    local method_name = rawget(proxy,'__tango_method_name')
    local send_request = rawget(proxy,'__tango_send_request')
    local rproxy
    if not rproxies[send_request] then
      local recv_response = rawget(proxy,'__tango_recv_response')
      rproxy = new(send_request,recv_response)
      rproxies[send_request] = rproxy
    end
    return rproxies[send_request],method_name
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
