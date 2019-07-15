local config = {}
-- config.write_access = mode:find('w') ~= nil
-- config.read_access = mode:find('r') ~= nil

add = 
  function(a,b)
    return a+b
  end

echo = 
  function(...)
    return ...
  end

strerror = 
  function()
    error('testmessage')
  end

customerror = 
  function(err)
    error(err)
  end

nested = {
  method = {
    name = function()return true end
  }
}

person = 
  function(name)
    local p = {
      _name = name
    }
    
    function p:name(name)
      if name then
        self._name = name
      else
        return self._name
      end
    end
    
    return p
 end

double_x = 
  function()
     return 2*x
  end

data = {
  x = 0,
  y = 3
}

require "tango.server.nodemcu.net".new()
