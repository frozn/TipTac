# LibSerialize

LibSerialize is a Lua library for efficiently serializing/deserializing arbitrary values.
It supports serializing nils, numbers, booleans, strings, and tables containing these types.

It is best paired with [LibDeflate](https://github.com/safeteeWow/LibDeflate), to compress
the serialized output and optionally encode it for World of Warcraft addon or chat channels.
IMPORTANT: if you decide not to compress the output and plan on transmitting over an addon
channel, it still needs to be encoded, but encoding via `LibDeflate:EncodeForWoWAddonChannel()`
or `LibCompress:GetAddonEncodeTable()` will likely inflate the size of the serialization
by a considerable amount. See the usage below for an alternative.

Note that serialization and compression are sensitive to the specifics of your data set.
You should experiment with the available libraries (LibSerialize, AceSerializer, LibDeflate,
LibCompress, etc.) to determine which combination works best for you.


## Usage

```lua
-- Dependencies: AceAddon-3.0, AceComm-3.0, LibSerialize, LibDeflate
MyAddon = LibStub("AceAddon-3.0"):NewAddon("MyAddon", "AceComm-3.0")
local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

function MyAddon:OnEnable()
    self:RegisterComm("MyPrefix")
end

-- With compression (recommended):
function MyAddon:Transmit(data)
    local serialized = LibSerialize:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
    self:SendCommMessage("MyPrefix", encoded, "WHISPER", UnitName("player"))
end

function MyAddon:OnCommReceived(prefix, payload, distribution, sender)
    local decoded = LibDeflate:DecodeForWoWAddonChannel(payload)
    if not decoded then return end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return end
    local success, data = LibSerialize:Deserialize(decompressed)
    if not success then return end

    -- Handle `data`
end

-- Without compression (custom codec):
MyAddon._codec = LibDeflate:CreateCodec("\000", "\255", "")
function MyAddon:Transmit(data)
    local serialized = LibSerialize:Serialize(data)
    local encoded = self._codec:Encode(serialized)
    self:SendCommMessage("MyPrefix", encoded, "WHISPER", UnitName("player"))
end
function MyAddon:OnCommReceived(prefix, payload, distribution, sender)
    local decoded = self._codec:Decode(payload)
    if not decoded then return end
    local success, data = LibSerialize:Deserialize(decoded)
    if not success then return end

    -- Handle `data`
end

-- Async Mode - Used in WoW to prevent locking the game while processing.
-- Serialize data:
local processing = CreateFrame("Frame")
local handler = LibSerialize:SerializeAsync(data_to_serialize)
processing:SetScript("OnUpdate", function()
    local completed, serialized = handler()
    if completed then
        processing:SetScript("OnUpdate", nil)
        -- Do something with `serialized`
    end
end)

-- Deserialize data:
local handler = LibSerialize:DeserializeAsync(serialized)
processing:SetScript("OnUpdate", function()
    local completed, success, deserialized = handler()
    if completed then
        processing:SetScript("OnUpdate", nil)
        -- Do something with `deserialized`
    end
end)
```


## API
* **`LibSerialize:SerializeEx(opts, ...)`**

    Arguments:
    * `opts`: options (see [Serialization Options])
    * `...`: a variable number of serializable values

    Returns:
    * result: `...` serialized as a string

* **`LibSerialize:Serialize(...)`**

    Arguments:
    * `...`: a variable number of serializable values

    Returns:
    * `result`: `...` serialized as a string

    Calls `SerializeEx(opts, ...)` with the default options (see [Serialization Options])

* **`LibSerialize:Deserialize(input)`**

    Arguments:
    * `input`: a string previously returned from a LibSerialize serialization API,
      or an object that implements the [Reader protocol]

    Returns:
    * `success`: a boolean indicating if deserialization was successful
    * `...`: the deserialized value(s) if successful, or a string containing the encountered
      Lua error

* **`LibSerialize:DeserializeValue(input, opts)`**

    Arguments:
    * `input`: a string previously returned from a LibSerialize serialization API,
      or an object that implements the [Reader protocol]
    * `opts`: options (see [Deserialization Options])

    Returns:
    * `...`: the deserialized value(s)

* **`LibSerialize:IsSerializableType(...)`**

    Arguments:
    * `...`: a variable number of values

    Returns:
    * `result`: true if all of the values' types are serializable.

    Note that if you pass a table, it will be considered serializable
    even if it contains unserializable keys or values. Only the types
    of the arguments are checked.

`Serialize()` will raise a Lua error if the input cannot be serialized.
This will occur if any of the following exceed 16777215: any string length,
any table key count, number of unique strings, number of unique tables.
It will also occur by default if any unserializable types are encountered,
though that behavior may be disabled (see [Serialization Options]).

`Deserialize()` and `DeserializeValue()` are equivalent, except the latter
returns the deserialization result directly and will not catch any Lua
errors that may occur when deserializing invalid input.

As of recent releases, the library supports reentrancy and concurrent usage
from multiple threads (coroutines) through the public API. Modifying tables
during the serialization process is unspecified and should be avoided.
Table serialization is multi-phased and assumes a consistent state for the
key/value pairs across the phases.

It is permitted for any user-supplied functions to suspend the current
thread during the serialization or deserialization process. It is however
not possible to yield the current thread if the `Deserialize()` API is used,
as this function inserts a C call boundary onto the call stack. This issue
does not affect the `DeserializeValue()` function.


## Asynchronous API

* **`LibSerialize:SerializeAsyncEx(opts, ...)`**

    Arguments:
    * `opts`: options (optional, see [Serialization Options])
    * `...`: a variable number of serializable values

    Returns:
    * `handler`: function that performs the serialization. This should be called with
      no arguments until the  first returned value is false.
      `handler` returns:
      * `completed`: a boolean indicating whether serialization is finished
      * `result`: once complete, `...` serialized as a string

    Calls `SerializeEx(opts, ...)` with the specified options, as well as setting
    the `async` option to true (see [Serialization Options]). Note that the passed-in
    table is written to when doing so.

* **`LibSerialize:SerializeAsync(...)`**

    Arguments:
    * `...`: a variable number of serializable values

    Returns:
    * `handler`: function that performs the serialization. This should be called with
      no arguments until the  first returned value is false.
      `handler` returns:
      * `completed`: a boolean indicating whether serialization is finished
      * `result`: once complete, `...` serialized as a string

    Calls `SerializeEx(opts, ...)` with the default options, as well as setting
    the `async` option to true (see [Serialization Options]). Note that the passed-in
    table is written to when doing so.

* **`LibSerialize:DeserializeAsync(input, opts)`**

    Arguments:
    * `input`: a string previously returned from a LibSerialize serialization API
    * `opts`: options (optional, see [Deserialization Options])

    Returns:
    * `handler`: function that performs the deserialization. This should be called with
      no arguments until the  first returned value is false.
      `handler` returns:
      * `completed`: a boolean indicating whether deserialization is finished
      * `success`: once complete, a boolean indicating if deserialization was successful
      * `...`: once complete, the deserialized value(s) if successful, or a string containing
        the encountered Lua error

    Calls `DeserializeValue(opts, ...)` with the specified options, as well as setting
    the `async` option to true (see [Deserialization Options]). Note that the passed-in
    table is written to when doing so.

Errors encountered when serializing behave the same way as the synchronous APIs.
Errors encountered when deserializing will always be caught and returned via the
handler's return values, even if `DeserializeValue()` is called directly. This is
different than when calling `DeserializeValue()` in synchronous mode.


## Serialization Options
The following serialization options are supported:
* `errorOnUnserializableType`: `boolean` (default true)
  * `true`: unserializable types will raise a Lua error
  * `false`: unserializable types will be ignored. If it's a table key or value,
     the key/value pair will be skipped. If it's one of the arguments to the
     call to SerializeEx(), it will be replaced with `nil`.
* `stable`: `boolean` (default false)
  * `true`: the resulting string will be stable, even if the input includes
     maps. This option comes with an extra memory usage and CPU time cost.
  * `false`: the resulting string will be unstable and will potentially differ
     between invocations if the input includes maps
* `filter`: `function(t, k, v) => boolean` (default nil)
  * If specified, the function will be called on every key/value pair in every
    table encountered during serialization. The function must return true for
    the pair to be serialized. It may be called multiple times on a table for
    the same key/value pair. See notes on reeentrancy and table modification.
* `async`: `boolean` (default false)
  * `true`: the API returns a coroutine that performs the serialization
  * `false`: the API performs the serialization directly
* `yieldCheck`: `function(t) => boolean` (default impl yields after 4096 items)
  * Only applicable when serializing asynchronously. If specified, the function
    will be called every time an item is about to be serialized. If the function
    returns true, the coroutine will yield. The function is passed a "scratch"
    table into which it can persist state.
* `writer`: `any` (default nil)
  * If specified, the object referenced by this field will be checked to see
    if it implements the [Writer protocol]. If so, the functions it defines
    will be used to control how serialized data is written.


## Deserialization Options
The following deserialization options are supported:
* `async`: `boolean` (default false)
  * `true`: the API returns a coroutine that performs the deserialization
  * `false`: the API performs the deserialization directly
* `yieldCheck`: `function(t) => boolean` (default impl yields after 4096 items)
  * Only applicable when deserializing asynchronously. If specified, the function
    will be called every time an item is about to be deserialized. If the function
    returns true, the coroutine will yield. The function is passed a "scratch"
    table into which it can persist state.

If an option is unspecified in the table, then its default will be used.
This means that if an option `foo` defaults to true, then:
* `myOpts.foo = false`: option `foo` is false
* `myOpts.foo = nil`: option `foo` is true


## Reader Protocol
The library supports customizing how serialized data is provided to the
deserialization functions through the use of the "Reader" protocol. This
enables advanced use cases such as batched or throttled deserialization via
coroutines, or processing serialized data of an unknown-length in a streamed
manner.

Any value supplied as the `input` to any deserialization function will be
inspected and indexed to search for the following keys. If provided, these
will override default behaviors otherwise implemented by the library.

* `ReadBytes`: `function(input, i, j) => string` (optional)
  * If specified, this function will be called every time the library needs
    to read a sequence of bytes as a string from the supplied input. The range
    of bytes is passed in the `i` and `j` parameters, with similar semantics
    to standard Lua functions such as `string.sub` and `table.concat`. This
    function must return a string whose length is equal to the requested range
    of bytes.

    It is permitted for this function to error if the range of bytes would
    exceed the available bytes; if an error is raised it will pass through
    the library back to the caller of Deserialize/DeserializeValue.

    If not supplied, the default implementation will access the contents of
    `input` as if it were a string and call `string.sub(input, i, j)`.

* `AtEnd`: `function(input, i) => boolean` (optional)
  * If specified, this function will be called whenever the library needs to
    test if the end of the input has been reached. The `i` parameter will be
    supplied a byte offset from the start of the input, and should typically
    return `true` if `i` is greater than the length of `input`.

    If this function returns true, the stream is considered ended and further
    values will not be deserialized. If this function returns false,
    deserialization of further values will continue until it returns true.

    If not supplied, the default implementation will compare the offset `i`
    against the length of `input` as obtained through the `#` operator.


## Writer Protocol
The library supports customizing how byte strings are written during the
serialization process through the use of an object that implements the
"Writer" protocol. This enables advanced use cases such as batched or throttled
serialization via coroutines, or streaming the data to a target instead of
processing it all in one giant chunk.

Any value stored on the `writer` key of the options table passed to the
`SerializeEx()` function will be inspected and indexed to search for the
following keys. If the required keys are all found, all operations provided
by the writer will override the default behaviors otherwise implemented by
the library. Otherwise, the writer is ignored and not used for any operations.

* `WriteString`: `function(writer, str)` (required)
  * This function will be called each time the library submits a byte string
    that was created as result of serializing data.

    If this function is not supplied, the supplied `writer` is considered
    incomplete and will be ignored for all operations.

* `Flush`: `function(writer)` (optional)
  * If specified, this function will be called at the end of the serialization
    process. It may return any number of values - including zero - all of
    which will be passed through to the caller of `SerializeEx()` verbatim.

    The default behavior if this function is not specified - and if the writer
    is otherwise valid - is a no-op that returns no values.


## Customizing table serialization
For any serialized table, LibSerialize will check for the presence of a
metatable key `__LibSerialize`. It will be interpreted as a table with
the following possible keys:
* `filter`: `function(t, k, v) => boolean`
  * If specified, the function will be called on every key/value pair in that
    table. The function must return true for the pair to be serialized. It may
    be called multiple times on a table for the same key/value pair. See notes
    on reeentrancy and table modification. If combined with the `filter` option,
    both functions must return true.


## Examples
1. `LibSerialize:Serialize()` supports variadic arguments and arbitrary key types,
   maintaining a consistent internal table identity.
    ```lua
    local t = { "test", [false] = {} }
    t[ t[false] ] = "hello"
    local serialized = LibSerialize:Serialize(t, "extra")
    local success, tab, str = LibSerialize:Deserialize(serialized)
    assert(success)
    assert(tab[1] == "test")
    assert(tab[ tab[false] ] == "hello")
    assert(str == "extra")
    ```

2. Normally, unserializable types raise an error when encountered during serialization,
   but that behavior can be disabled in order to silently ignore them instead.
    ```lua
    local serialized = LibSerialize:SerializeEx(
        { errorOnUnserializableType = false },
        print, { a = 1, b = print })
    local success, fn, tab = LibSerialize:Deserialize(serialized)
    assert(success)
    assert(fn == nil)
    assert(tab.a == 1)
    assert(tab.b == nil)
    ```

3. Tables may reference themselves recursively and will still be serialized properly.
    ```lua
    local t = { a = 1 }
    t.t = t
    t[t] = "test"
    local serialized = LibSerialize:Serialize(t)
    local success, tab = LibSerialize:Deserialize(serialized)
    assert(success)
    assert(tab.t.t.t.t.t.t.a == 1)
    assert(tab[tab.t] == "test")
    ```

4. You may specify a global filter that applies to all tables encountered during
   serialization, and to individual tables via their metatable.
    ```lua
    local t = { a = 1, b = print, c = 3 }
    local nested = { a = 1, b = print, c = 3 }
    t.nested = nested
    setmetatable(nested, { __LibSerialize = {
        filter = function(t, k, v) return k ~= "c" end
    }})
    local opts = {
        filter = function(t, k, v) return LibSerialize:IsSerializableType(k, v) end
    }
    local serialized = LibSerialize:SerializeEx(opts, t)
    local success, tab = LibSerialize:Deserialize(serialized)
    assert(success)
    assert(tab.a == 1)
    assert(tab.b == nil)
    assert(tab.c == 3)
    assert(tab.nested.a == 1)
    assert(tab.nested.b == nil)
    assert(tab.nested.c == nil)
    ```

5. You may perform the serialization and deserialization operations asynchronously,
   to avoid blocking for excessive durations when handling large amounts of data.
   Note that you wouldn't call the handlers in a repeat-until loop like below, because
   then you're still effectively performing the operations synchronously.
    ```lua
    local t = { "test", [false] = {} }
    t[ t[false] ] = "hello"
    local co_handler = LibSerialize:SerializeAsync(t, "extra")
    local completed, serialized
    repeat
        completed, serialized = co_handler()
    until completed

    local completed, success, tab, str
    local co_handler = LibSerialize:DeserializeAsync(serialized)
    repeat
        completed, success, tab, str = co_handler()
    until completed

    assert(success)
    assert(tab[1] == "test")
    assert(tab[ tab[false] ] == "hello")
    assert(str == "extra")
    ```

6. You may use the Reader and Writer protocols to have more control over writing the
   results of serialization, or how those results are read when deserializing. The below
   example implements the default behavior of the library using these protocols.
    ```lua
    local t = { a = 1, b = 2, c = 3 }

    local StandardWriter = {}
    function StandardWriter:Initialize()
        self.buffer = {}
        self.bufferSize = 0
    end
    function StandardWriter:WriteString(str)
        self.bufferSize = self.bufferSize + 1
        self.buffer[self.bufferSize] = str
    end
    function StandardWriter:Flush()
        local flushed = table.concat(self.buffer, "", 1, self.bufferSize)
        self.bufferSize = 0
        return flushed
    end

    local StandardReader = {}
    function StandardReader:Initialize(input)
        self.input = input
    end
    function StandardReader:ReadBytes(startOffset, endOffset)
        return string.sub(self.input, startOffset, endOffset)
    end
    function StandardReader:AtEnd(offset)
        return offset > #self.input
    end

    StandardWriter:Initialize()
    local serialized = LibSerialize:SerializeEx({ writer = StandardWriter }, t)

    StandardReader:Initialize(serialized)
    local success, tab = LibSerialize:Deserialize(StandardReader)

    assert(success)
    assert(tab.a == 1)
    assert(tab.b == 2)
    assert(tab.c == 3)
    ```


## Encoding format
Every object is encoded as a type byte followed by type-dependent payload.

For numbers, the payload is the number itself, using a number of bytes
appropriate for the number. Small numbers can be embedded directly into
the type byte, optionally with an additional byte following for more
possible values. Negative numbers are encoded as their absolute value,
with the type byte indicating that it is negative. Floats are decomposed
into their eight bytes, unless serializing as a string is shorter.

For strings and tables, the length/count is also encoded so that the
payload doesn't need a special terminator. Small counts can be embedded
directly into the type byte, whereas larger counts are encoded directly
following the type byte, before the payload.

Strings are stored directly, with no transformations. Tables are stored
in one of three ways, depending on their layout:
* Array-like: all keys are numbers starting from 1 and increasing by 1.
    Only the table's values are encoded.
* Map-like: the table has no array-like keys.
    The table is encoded as key-value pairs.
* Mixed: the table has both map-like and array-like keys.
    The table is encoded first with the values of the array-like keys,
    followed by key-value pairs for the map-like keys. For this version,
    two counts are encoded, one each for the two different portions.

Strings and tables are also tracked as they are encountered, to detect reuse.
If a string or table is reused, it is encoded instead as an index into the
tracking table for that type. Strings must be >2 bytes in length to be tracked.
Tables may reference themselves recursively.


#### Type byte:
The type byte uses the following formats to implement the above:

* `NNNN NNN1`: a 7 bit non-negative int
* `CCCC TT10`: a 2 bit type index and 4 bit count (strlen, #tab, etc.)
    * Followed by the type-dependent payload
* `NNNN S100`: the lower four bits of a 12 bit int and 1 bit for its sign
    * Followed by a byte for the upper bits
* `TTTT T000`: a 5 bit type index
    * Followed by the type-dependent payload, including count(s) if needed

[Serialization Options]: #serialization-options
[Deserialization Options]: #deserialization-options
[Reader protocol]: #reader-protocol
[Writer protocol]: #writer-protocol
