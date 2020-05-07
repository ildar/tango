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
          local var = self.functab
          if request[1] ~= "" then
            var = d.refs[request[1]]
          end
          local var_name = request[2]
          local last_part
          local last_var
          for part in var_name:gmatch('[%w_]+') do
            last_part = part
            last_var = var
            if type(var) == 'table' or type(var) == 'romtable' then
              var = var[part]
            else
              return {false,error_msg(var_name,'no such variable')}
            end
          end
          -- replace ref-tables with real objects
          for i=3,#request do
            if type(request[i]) == 'table' and request[i].__ref_id then
              request[i] = d.refs[request[i].__ref_id]
            end
          end
          if type(var) == 'function' or type(var) == 'lightfunction' then
            local res = {self.pcall(var,unpack(request,3))}
            -- replace ref-tables with real objects
            for i=1,#res do
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
          else
            local val = request[3]
            if val then
              if not self.write_access then
                return {false,error_msg(var_name,'no write_access')}
              else
                return {self.pcall(
                              function()
                                 last_var[last_part] = val
                              end)}
              end
            else
              if not self.read_access then
                 return {false,error_msg(var_name,'no read_access')}
              else
                 return {true,var}
              end
             end
          end        
          
        end    
    }

    d.refs = {}
    d.functab.tango = d.functab.tango or {}
    
    function d.functab.tango.__mkref(obj)
      if type(obj) == 'table' or
        type(obj) == 'romtable' or
        type(obj) == 'userdata' or
        type(obj) == 'function' or
        type(obj) == 'lightfunction'
        then
        local id = tostring(obj)
        d.refs[id] = obj
        return id
      else
        error('tango.dispatcher cannot ref not a non-ref value')
      end
    end
    
    d.functab.tango.ref_create = 
      function(create_method,...)
        local result = d:dispatch({"", create_method,...})
        if result[1] == true then
          return d.functab.tango.__mkref(result[2])
        else
          error(result[2])
        end
      end

    d.functab.tango.ref_release = 
      function(refid)
        d.refs[refid] = nil
      end
    
    d.functab.tango.ref_call = 
      function(refid,method_name,...)
        local obj = d.refs[refid]
        if obj then
          return obj[method_name](obj,...)
        else
          error('tango.ref invalid id' .. refid)
        end          
      end    

    return d
  end

return {
  new = new
}
