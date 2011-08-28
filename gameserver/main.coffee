io = require('socket.io')
Player = require './player'
utils = require './shared/utils.coffee'
constants = require './shared/constants.coffee'
states = require './shared/states.coffee'

class exports.Server
  constructor: (app) ->
    @io = io.listen app,
      'transports': ['websocket']
      'log level': 2
    @io.sockets.on 'connection', (s) => @player_connect(s)

    stateCount = Math.round(constants.ROLLBACK_TIME * constants.TICKS_PER_SECOND) + 1
    @states = new utils.StatePool(states.WorldState, stateCount)
    @states.new(timestamp: +new Date / 1000)
    @players = []
    @playerIds = 0

    @tickTimer = setInterval @tick, 1000 / constants.TICKS_PER_SECOND

  player_connect: (socket) ->
    console.log "Player connected..."
    state = new states.PlayerState x: 0, y: 0, id: @playerIds++, seed: (+new Date + @playerIds)
    # console.log state
    player = new Player(socket, state)
    @players.push player
    @states.head().players.push state

    socket.on 'input', (inputs) => @player_input player, inputs
    socket.on 'disconnect', => @player_disconnect player
    socket.emit "welcome", player: state, clock: +new Date / 1000

  player_disconnect: (player) ->
    index = @players.indexOf player
    if index != -1
      @players.splice index, 1

  player_input: (player, data) ->
    player.inputs.concat data
    Array::push.apply player.inputs, data

  # The main "Game Loop"
  tick: =>
    time = +new Date / 1000
    world = @states.new(timestamp: time)

    # Process player inputs
    for p in @players
      newState = p.state.clone()
      for i in p.inputs
        newState.applyInput i
      p.inputs.length = 0
      world.players.push p.state = newState

    # Send updates to due players
    for p in @players
      if p.lastUpdate + constants.TIME_BETWEEN_UPDATES <= time
        p.lastUpdate = Math.max time, p.lastUpdate + constants.TIME_BETWEEN_UPDATES
        p.socket.emit 'world', world

