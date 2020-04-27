local rawget = rawget
local rawset = rawset
local type = type
local error = error
local unpack = unpack
local setmetatable = setmetatable
local print = print

module('tango.proxy')

function new(send_request,recv_response,root_object,method_name)
    return setmetatable(
      {
        __tango_root_object = root_object or "",
        __tango_method_name = method_name,
        __tango_send_request = send_request,
        __tango_recv_response = recv_response
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
            return new(send_request,recv_response,root_object,new_method_name)
          end,        
        __call=
          function(self,...)
            send_request({root_object or "",method_name,...})
            local response = recv_response()
            for i=2,#response do
              if type(response[i]) == 'table' and response[i].__ref_id then
                response[i] = new(send_request,recv_response,response[i].__ref_id)
              end
            end
            if response[1] == true then
              return unpack(response,2)
            else
              error(response[2],2)
            end
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
    local send_request = rawget(proxy,'__tango_send_request')
    local rproxy
    if not rproxies[send_request] then
      local recv_response = rawget(proxy,'__tango_recv_response')
      rproxy = new(send_request,recv_response,root_object)
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
