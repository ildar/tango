-- using GIO networking async API through LGI (https://github.com/pavouk/lgi)

local lgi = require 'lgi'
local GLib = lgi.GLib
local Gio = lgi.Gio

local print = print
local tonumber = tonumber
local tostring = tostring
local _TEST = _TEST
local dispatcher_mod = require "tango.dispatcher"
local default_cfg = require "tango.config".server_default

module('tango.server.lgi_async')

local function new(config, dont_start_server)
  config = config or {}
  local tango_conf = default_cfg(config)
  tango_conf.interface = config.interface or '0.0.0.0'
  tango_conf.port = (config and config.port) or 12345
  tango_conf.dispatcher = dispatcher_mod.new(tango_conf)        
  
  local function receive_and_process(conn, istream, ostream)
    local buf -- accumulating received bytes
    local msg_len=0 -- if 0 then we're in header phase, otherwise in msg phase
    local bytes

    bytes = istream:async_read_bytes(4096)
    if bytes:get_size() < 1 then conn:close() ; return end
    buf = bytes.data:sub(1, bytes:get_size())
    while true do
      if msg_len == 0 then -- in header
        while not buf:find("\n", 1, true) do
          bytes = istream:async_read_bytes(4096)
          if bytes:get_size() < 1 then conn:close() ; return end
          buf = buf .. bytes.data:sub(1, bytes:get_size())
        end
        local e = buf:find("\n", 1, true)
        msg_len = tonumber( buf:sub(1,e-1) )
        if not msg_len then
          print("PANIC! broken message!")
          buf = buf:sub(e+1)
        end
        buf = buf:sub(e+1)
      else -- in message
        while #buf < msg_len do
          bytes = istream:async_read_bytes(4096)
          if bytes:get_size() < 1 then conn:close() ; return end
          buf = buf .. bytes.data:sub(1, bytes:get_size())
        end
        local msg = buf:sub(1, msg_len)
        buf = buf:sub(msg_len+1)
        msg_len = 0
        -- process the incoming message and send the response
        local message = tango_conf.unserialize(msg)
        local response = tango_conf.dispatcher:dispatch(message)
        local rsp = tango_conf.serialize(response)
        rsp = tostring(#rsp) .. "\n" .. rsp
        ostream:async_write_bytes(GLib.Bytes.new(rsp, #rsp))
      end
    end
  end
  
  local function on_incoming(_, conn)
    local istream = conn:get_input_stream()
    local ostream = conn:get_output_stream()
    
    Gio.Async.start(receive_and_process)(conn, istream, ostream)
    return false
  end
  
  if not dont_start_server then
    tango_conf.service = Gio.SocketService.new()
    tango_conf.service:add_address(
      Gio.InetSocketAddress.new_from_string(tango_conf.interface, tango_conf.port),
      Gio.SocketType.STREAM, Gio.SocketProtocol.TCP)
    tango_conf.service.on_incoming = on_incoming
    tango_conf.service:start()
  end
  return tango_conf
end

local function loop(config)
  new(config)
  GLib.MainLoop():run()
end

local _receive_and_process
if _TEST then
  -- _receive_and_process = receive_and_process
  -- _tango_conf = tango_conf
end

return {
  loop = loop,
  new = new,
  -- private
  _receive_and_process = _receive_and_process,
  -- tango_conf = tango_conf
}

