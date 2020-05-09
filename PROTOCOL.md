Network protocol
================
is fairly simple. Client sends a request and server sends response (message).
The data is traveled on top of the TCP connection initiated by client.

Message format
--------------
is ruled by serialization methods; by default the `serialization` module
implementation is used. The following is the default message protocol.

Every message (back and forth) is:

1. a message body length in text format followed by the '\n' character;
2. message body of exactly the declared length in text format.

The message body is the Lua table declaration in array form. The array can have
elements of the following types:

1. strings in double quotes
2. numbers
3. booleans (false, true)
4. tables in a declaration form.

Generally the message body is ready for `loadstring()`

Request message (body)
----------------------
is an array table:

* `[1]` object reference
* `[...]` args

The object reference may be:

1. a table reference
2. a function reference
3. any other reference (see details below)
4. tango API function name (starting with `tango.`)

In case it is a table field then:

1. [...] == nil -> get the value
2. [...] ~= nil -> set the value to [2]

In case it is a function it is called with [...] as arguments.

With other Lua objects which (besides tables and functions) are userdata and
thread the behavior is currently undefined.

All object references match the pattern `TYPE: iD`

Tango API names are simple symbolic `tango.APIFUNC`. Functions called
with [...] as arguments.

Response message (body)
-----------------------
is also an array table:

* `[1]` is the boolean indicating if the request succeeded or not
* `[...]` either the return value of the request or the error message

Example
-------
Client:

```
25
{"function: 0x98765",1,2}
```

Server:

```
8
{true,3}
```

This is how the client asks server to call the function `add(1,2)` on the
server side and receives the response `3`

