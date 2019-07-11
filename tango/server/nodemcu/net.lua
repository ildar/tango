-- require "net" -- which is the NodeMCU core `net` module

local print = print
local dispatcher = require "tango.dispatcher"
local default = require "tango.config".server_default

module('tango.server.nodemcu.net')

new = 
  function(config)
    config = default(config)
    config.port = config.port or 12345
    
    -- TODO
  end

loop = 
  function(config)
    local server = new(config)
    -- TODO
  end

onreceive =
  function(conn, chunk)
    dispatcher:dispatch("0123456789")
  end
  
return {
  loop = loop,
  onreceive = onreceive,
  new = new
}

