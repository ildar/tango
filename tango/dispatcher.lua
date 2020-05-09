local type = type
local error = error
local unpack = unpack
local tostring = tostring
local print = print

module('tango.dispatcher')

local error_msg = 
   function(var_name,err)
      local msg = 'tango server error "%s": %s' 
      return msg:format(var_name,err)
   end

local new = 
  function(config)
    local d
    d = {
      functab = config.functab,
      pcall = config.pcall,
      read_access = config.read_access,
      write_access = config.write_access,
      dispatch = 
        function(self,request)    
          local obj
          if type(request[1]) ~= 'string' then
            return {false,error_msg(request[1],'should be an object encoded in string')}
          end
          -- replace refs with real objects
          if request[1]:find(':') then
            obj = d.refs[request[1]]
          end
          if request[1]:sub(1,6) == 'tango.' then
            obj = self.functab
            for part in request[1]:gmatch('[%w_]+') do
              if type(obj) == 'table' or type(obj) == 'romtable' then
                obj = obj[part]
              else
                return {false,error_msg(request[1],'no such variable')}
              end
            end
          end
          -- replace ref-tables with real objects
          for i=2,#request do
            if type(request[i]) == 'table' and request[i].__ref_id then
              request[i] = d.refs[request[i].__ref_id]
            end
          end
          -- do
          local res
          if type(obj) == 'function' or
              type(obj) == 'lightfunction' or
              (type(obj) == 'userdata' and tostring(obj):sub(1,7) == 'lgi.fun')
            then
            res = {self.pcall(obj,unpack(request,2))}
          else -- a table
            local val = request[3]
            if val then -- writing a value
              if not self.write_access then
                return {false,error_msg(obj,'no write_access')}
              else
                res = {self.pcall(
                              function()
                                 obj[request[2]] = val
                              end)}
              end
            else -- reading a value
              if not self.read_access then
                 return {false,error_msg(obj,'no read_access')}
              else
                 res = {true,obj[request[2]]}
              end
             end
          end
          -- replace real objects with ref-tables
          for i=2,#res do
            if type(res[i]) == 'table' or
                type(res[i]) == 'romtable' or
                type(res[i]) == 'userdata' or
                type(res[i]) == 'function' or
                type(res[i]) == 'lightfunction'
              then
              res[i] = { __ref_id = d.functab.tango.__mkref(res[i]) }
            end
          end
          return res
        end
    }

    d.refs = { ["tango:env"] = d.functab }
    d.functab.tango = d.functab.tango or {}
    
    -- Tango server API
    function d.functab.tango.__mkref(obj)
      if type(obj) == 'table' or
          type(obj) == 'romtable' or
          type(obj) == 'userdata' or
          type(obj) == 'function' or
          type(obj) == 'lightfunction'
        then
        local id = tostring(obj)
        if type(obj) == 'userdata' then
          id = 'userdata:' .. id
        end
        d.refs[id] = obj
        return id
      else
        error('tango.dispatcher cannot ref not a non-ref value')
      end
    end
    
    d.functab.tango.ref_release = 
      function(refid)
        d.refs[refid] = nil
      end

    return d
  end

return {
  new = new
}
