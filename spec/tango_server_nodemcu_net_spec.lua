local tsnn_module = require "tango.server.nodemcu.net"

local dispatcher = require "tango.dispatcher"

describe("tango.server.nodemcu.net module", function ()
    it("should be able to receive some trivial data", function ()
        local testchunk = "10\n0123456789"
        stub(dispatcher, "dispatch")
        
        tsnn_module.onreceive(conn, testchunk)
        assert.stub(dispatcher.dispatch).was.called_with(match._, "0123456789")
        dispatcher.dispatch:revert()
      end)
    it("should be able to receive chucked data", function ()
        local testchunk1, testchunk2 = "10\n012", "3456789"
        stub(dispatcher, "dispatch")
        
        tsnn_module.onreceive(conn, testchunk1)
        assert.stub(dispatcher.dispatch).was_not.called()
        tsnn_module.onreceive(conn, testchunk2)
        assert.stub(dispatcher.dispatch).was.called_with(match._, "0123456789")
        dispatcher.dispatch:revert()
        
        testchunk1, testchunk2 = "1", "0\n0123456789"
        stub(dispatcher, "dispatch")
        
        tsnn_module.onreceive(conn, testchunk1)
        assert.stub(dispatcher.dispatch).was_not.called()
        tsnn_module.onreceive(conn, testchunk2)
        assert.stub(dispatcher.dispatch).was.called_with(match._, "0123456789")
        dispatcher.dispatch:revert()
      end)
    it("should be tested on random data", function ()
        pending("add random data tests like of libdbus")
      end)
    
end)
