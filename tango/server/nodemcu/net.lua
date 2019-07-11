-- require "net" -- which is the NodeMCU core `net` module

local print = print
local tonumber = tonumber
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

local buf -- accumulating received bytes
local msg_len=0 -- if 0 then we're in header phase, otherwise in msg phase
onreceive =
  function(conn, chunk)
    if not buf then
      buf = chunk
    else
      buf = buf .. chunk
    end
    
    -- consume buffer line by line
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
        dispatcher:dispatch(msg)
        -- msg = nil
      end
      -- TODO: collect some garbage?
    end
  end
  
return {
  loop = loop,
  onreceive = onreceive,
  new = new
}

