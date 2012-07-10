###
WebsocketRails JavaScript Client

Setting up the dispatcher:
  var dispatcher = new WebSocketRails('localhost:3000');
  dispatcher.on_open = function() {
    // trigger a server event immediately after opening connection
    dispatcher.trigger('new_user',{user_name: 'guest'});
  })

Triggering a new event on the server
  dispatcherer.trigger('event_name',object_to_be_serialized_to_json);

Listening for new events from the server
  dispatcher.bind('event_name', function(data) {
    console.log(data.user_name);
  });
###
class window.WebSocketRails
  constructor: (@url, @use_websockets = true) ->
    @state     = 'connecting'
    @callbacks = {}
    @channels  = {}
    @queue     = {}

    unless @supports_websockets() and @use_websockets
      @_conn = new WebSocketRails.HttpConnection url, @
    else
      @_conn = new WebSocketRails.WebSocketConnection url, @

    @_conn.new_message = @new_message

  new_message: (data) =>
    for socket_message in data
      event = new WebSocketRails.Event socket_message
      @queue[event.id] = event

      if event.is_channel()
        @dispatch_channel event
      else
        @dispatch event

      if @state == 'connecting' and event.name == 'client_connected'
        @connection_established event.data

  connection_established: (data) =>
    @state         = 'connected'
    @connection_id = data.connection_id
    if @on_open?
      @on_open(data)

  bind: (event_name, callback) =>
    @callbacks[event_name] ?= []
    @callbacks[event_name].push callback

  trigger: (event_name, data) =>
    @_conn.trigger event_name, data, @connection_id

  dispatch: (event) =>
    return unless @callbacks[event.name]?
    for callback in @callbacks[event.name]
      callback event.data

  subscribe: (channel_name) =>
    unless @channels[channel_name]?
      channel = new WebSocketRails.Channel channel_name, @
      @channels[channel_name] = channel
      channel
    else
      @channels[channel_name]

  trigger_channel: (channel, event_name, data) =>
    @_conn.trigger_channel channel, event_name, data, @connection_id

  dispatch_channel: (event) =>
    return unless @channels[event.channel]?
    @channels[event.channel].dispatch event.name, event.data

  supports_websockets: =>
    (typeof(WebSocket) == "function" or typeof(WebSocket) == "object")

