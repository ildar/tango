local type = type
local error = error
local unpack = unpack
local setmetatable = setmetatable
local assert = assert
local print = print

module('tango.proxy')

local function new(proxy_conf,objid)
  assert(proxy_conf)
  assert(proxy_conf.send_request)
  assert(proxy_conf.recv_response)
  
  local function rpc(...)
    local req = {...}
    for i=1,#req do
      if type(req[i]) == 'table' and req[i].__tango_objid then
        req[i] = { __ref_id=req[i].__tango_objid }
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

  objid = objid or "tango:env"
    return setmetatable(
      {
        __tango_objid = objid,
        __tango_type = objid:sub(1, objid:find(':')),
        __tango_proxy_conf = proxy_conf
      },
      {
        __index= 
          function(self, elem)
            local response = rpc(objid, elem)
            if response[1] ~= true then
              error(response[2],2)
            end
            return response[2]
          end,        
        __call=
          function(self,...)
            local response = rpc(objid, ...)
            if response[1] ~= true then
              error(response[2],2)
            end
            return unpack(response,2)
          end,
        __newindex=
          function(self, elem, val)
            local response = rpc(objid, elem, val)
            if response[1] ~= true then
              error(response[2],2)
            end
          end
      })
end

return {
  new = new,
}
