-- This is intended to be run on a NodeMCU in a very constrained environment
--   one instance per system

-- require "net" -- which is the NodeMCU core `net` module

local print = print
local tonumber = tonumber
local dispatcher = require "tango.dispatcher"
local default_cfg = require "tango.config".server_default

module('tango.server.nodemcu.net')

--   one instance per system
local tango_conf

--   one instance per system
local buf -- accumulating received bytes
local msg_len=0 -- if 0 then we're in header phase, otherwise in msg phase
onreceive =
  function(conn, chunk)
    if not buf then
      buf = chunk
    else
      buf = buf .. chunk
    end
    
    while #buf > 0 do
      if msg_len == 0 then -- in header
        local e = buf:find("\n", 1, true)
        if not e then return end -- incomplete, go wait for the rest of it
        msg_len = tonumber( buf:sub(1,e-1) )
        if not msg_len then
          print("PANIC! broken message!")
          buf = buf:sub(e+1)
        end
        buf = buf:sub(e+1)
      else -- in message
        if #buf < msg_len then return end -- incomplete
        local msg = buf:sub(1, msg_len)
        buf = buf:sub(msg_len+1)
        msg_len = 0
        -- process the incoming message and send the response
        local message = tango_conf.unserialize(msg)
        local response = dispatcher:dispatch(message)
        local rsp = tango_conf.serialize(response)
        conn:send(rsp)
        -- msg = nil
      end
      -- TODO: maybe postpone the watchdog?
      -- TODO: collect some garbage?
    end
  end
  
new = 
  function(config)
    tango_conf = default_cfg(config)
    tango_conf.port = (config and config.port) or 12345
    -- TODO create server here
  end

local srv
loop = 
  function(config)
    -- TODO
    local server = new(config)
  end

return {
  loop = loop,
  onreceive = onreceive,
  new = new,
  -- tango_conf = tango_conf
}

