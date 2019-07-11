local tsnn_module = require "tango.server.nodemcu.net"

local dispatcher = require "tango.dispatcher"

describe("tango.server.nodemcu.net module", function ()
    it("should be able to receive some trivial data", function ()
        local testchunk = "10\n0123456789"
        stub(dispatcher, "dispatch")
        
        tsnn_module.onreceive(conn, testchunk)
        assert.stub(dispatcher.dispatch).was.called_with(match._, "0123456789")
      end)
end)
