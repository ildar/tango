local require = require
local pcall = pcall

module('tango')

local try_require = 
  function(module)
     local ok,mod = pcall(require,module)
     if ok then
        return mod
     else
        return nil
     end
  end

return {
  client = {
     socket = try_require('tango.client.socket'),
     zmq = try_require('tango.client.zmq')
  },
  server = {
     copas_socket = try_require('tango.server.copas_socket'),
     ev_socket = try_require('tango.server.ev_socket'),
     lgi_async = try_require('tango.server.lgi_async'),
     zmq = try_require('tango.server.zmq')
  }  
}

