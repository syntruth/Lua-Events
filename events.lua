--[[
  Lua-based Event library to allow event emitting with attached callbacks.
  
  Usage:

    require "events"

    -- Create an event.
    Event.create("join")

    -- Observe the event with a callback.
    -- The callback function will receive the event name
    -- as the first parameter, and any arguments passed to
    -- Event.emit().
    -- There is an optional 3rd argument, which if true, will
    -- create the event if it does not already exist.
    function join_callback(event, ...)
      ...
    end

    Event.observe("join", join_callback)

    -- Emit the event!
    Event.emit("join", "foo", "bar")

    -- To no longer observe and event, pass in the callback
    -- function once again. Callbacks are matched based on
    -- the function you passed in. Remember, it HAS to be the
    -- same function; passing in anonymous functions won't work, 
    -- unless you save the return value from Event.observe(), 
    -- since it returns the callback function provided.
    Event.unobserve("join", join_callback)

    -- Silence an event if you wanted to prevent callbacks from 
    -- being called.
    Event.silence("join")

    -- any callbacks won't be called now.
    Event.emit("join", "foo", "bar")

    -- Allow callbacks to happen once more.
    Event.unsilence("join")

    -- You can also silence an event for a single call of a 
    -- function. The next argument after the event to silence
    -- is the name of the function to call after silencing the 
    -- event, and any additional arguments are passed to that
    -- function.
    function func(arg1, arg2)
      ...
    end

    Event.silence("join", func, "foo", "bar")

    -- Finally, you can remove events as well. This will remove
    -- the event and all of it's callbacks by setting the event
    -- to nil, allowing it to be garbage collected.
    Event.remove("join") 
]]

--  The Event object.
Event = {
  events   = {},
  silenced = {}
}

-- Create an event.
function Event.create(event)
  if not Event.events[event] then
    Event.events[event] = {}
  end
end

-- Remove an event.
function Event.remove(event)
  Event.events[event] = nil
end

-- Check to see if an event is known.
function Event.has_event(event)
  if Event.events[event] then
    return true
  end
  return false
end

-- Observe an event. A callback function is required.
-- If do_create is true, and the event does not exist,
-- it will be created before storing the callback.
-- The callback function will be returned if it was 
-- added, else nil is returned.
function Event.observe(event, callback, do_create)
  if not Event.has_event(event) and do_create then
    Event.create(event)
  else
    return nil
  end

  table.insert(Event.events[event], callback)

  return callback
end

-- No longer observe an event. The callback given to
-- original observe the event must be given. It HAS
-- to be the same function, matching the function's ID,
-- or else the callback won't be removed. Thus, be
-- careful passing in anonymous functions as callbacks,
-- unless you save the return value from Event.observe()
-- to later use to unobserve.
function Event.unobserve(event, callback)
  if Event.has_event(event) then
    local tmp = {}

    for _, cb in Event.events[event] do
      if not callback == cb then
        table.insert(tmp, cb)
      end
    end

    Event.events[event] = tmp
    return true
  end

  return false
end

-- Event an event. Any extra arguments will be passed
-- to each callback functions.
function Event.emit(event, ...)
  if Event.has_event(event) then
    for _, callback in Event.events[event] do
      callback(event, unpack(arg))
    end
  end
end

-- Silence an event's, causing any of it's callback
-- functions to not be called if the event is emitted.
-- You can pass a function as the second argument, which
-- will cause the event to be silenced only for the call
-- of that function. Any additional arguments after this
-- function will be passed to that function. After the 
-- function is called, the event will be unsilenced again.
-- This function will return true if the event is still
-- silenced at the end of this function, or nil if it
-- isn't (which will only happen if you pass in a callback
-- function.)
function Event.silence(event, ...)
  if not Event.silenced[event] then
    Event.silenced[event] = true
  end

  if type(arg[1]) == "function" then
    callback = table.remove(arg, 1)

    callback(unpack(arg))
    Event.silenced[event] = nil
  end
  
  return Event.silenced[event]
end

-- Remove the silencing of an event.
function Event.unsilence(event)
  Event.silenced[event] = nil
end

-- Checks to see if an event is silenced.
function Event.is_silenced(event)
  return Event.silenced[event]
end

