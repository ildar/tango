_G._TEST = true
local tsnn_module = require "tango.server.nodemcu.net"

local serialization = require'tango.utils.serialization'
local dispatcher = require "tango.dispatcher"

local fakeconn = {send=function() end}
describe("tango.server.nodemcu.net module", function ()
  describe("check_input_data()", function ()
    setup( function()
          local tango_conf = tsnn_module.new({
              serialize = function(...) return serialization.serialize(...) or "" end,
              unserialize = function(...) return serialization.unserialize(...) end
            }, true)
          stub(tango_conf.dispatcher, "dispatch")
          stub(serialization, "serialize")
        end)
    it("should be able to process some trivial input data", function ()
        local testchunk = "10\n0123456789"
        stub(serialization, "unserialize")
        
        tsnn_module._check_input_data(fakeconn, testchunk)
        assert.stub(serialization.unserialize).was.called_with("0123456789")
        serialization.unserialize:revert()
      end)
    it("should be able to process chuncked input data", function ()
        local testchunk1, testchunk2 = "10\n012", "3456789"
        stub(serialization, "unserialize")
        
        tsnn_module._check_input_data(fakeconn, testchunk1)
        assert.stub(serialization.unserialize).was_not.called()
        tsnn_module._check_input_data(fakeconn, testchunk2)
        assert.stub(serialization.unserialize).was.called_with("0123456789")
        serialization.unserialize:revert()
        
        testchunk1, testchunk2 = "1", "0\n0123456789"
        stub(serialization, "unserialize")
        
        tsnn_module._check_input_data(fakeconn, testchunk1)
        assert.stub(serialization.unserialize).was_not.called()
        tsnn_module._check_input_data(fakeconn, testchunk2)
        assert.stub(serialization.unserialize).was.called_with("0123456789")
        serialization.unserialize:revert()
      end)
    it("should be tested on random data", function ()
        pending("add random data tests like of libdbus")
      end)
  end)
end)
