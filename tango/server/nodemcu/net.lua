-- This is intended to be run on a NodeMCU in a very constrained environment
--   one instance per system

-- require "net" -- which is the NodeMCU core `net` module
local net = net

local print = print
local tonumber = tonumber
local tostring = tostring
local _TEST = _TEST
local dispatcher_mod = require "tango.dispatcher"
local default_cfg = require "tango.config".server_default

module('tango.server.nodemcu.net')

--   one instance per system
local tango_conf

--   one instance per system
local buf -- accumulating received bytes
local msg_len=0 -- if 0 then we're in header phase, otherwise in msg phase
local function check_input_data(conn, chunk)
    local dispatcher = tango_conf.dispatcher
    if not chunk or #chunk < 1 then return end
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
        rsp = tostring(#rsp) .. "\n" .. rsp
        conn:send(rsp)
        -- msg = nil
        return -- one send per iteration allowed
      end
      -- TODO: maybe postpone the watchdog?
      -- TODO: collect some garbage?
    end
end
  
local function on_newclient(conn)
      conn:on("receive", check_input_data)
      conn:on("sent", check_input_data)
      conn:on("disconnection", nil)     
end
  
--   one instance per system
local srv
local function new(config, dont_start_server)
    tango_conf = default_cfg(config)
    tango_conf.port = (config and config.port) or 12345
    tango_conf.dispatcher = dispatcher_mod.new(tango_conf)        
    
    if not dont_start_server then
      -- NB: only one server at a time
      if srv then srv:close() end
      srv = net.createServer(net.TCP, 15)
      srv:listen(tango_conf.port, on_newclient)
    end
    return tango_conf
  end

local _check_input_data
if _TEST then
  _check_input_data = check_input_data
  -- _tango_conf = tango_conf
end

return {
  loop = new, -- NodeMCU has its own loop
  new = new,
  -- private
  _check_input_data = _check_input_data,
  -- tango_conf = tango_conf
}

