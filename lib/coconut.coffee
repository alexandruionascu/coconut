window.$ = window.jQuery = require('../node_modules/jquery')
NodeRsa = require('../node_modules/node-rsa')
io = require('../node_modules/socket.io-client')
#Connect to the node server
socket = io.connect('http://localhost:3000')
newGuid = require './aux_tools/guid'

#Views
JoinSessionView = require('./joinsession-view')
StartSessionView = require('./startsession-view')
CoconutView = require './coconut-view'
{CompositeDisposable} = require 'atom'


guid = null
#Public and private key pair
key = null
#Server public key
serverKey = null
#Client's public key
clientKey= null


module.exports = Coconut =

  #TODO: remove toggle view
  coconuttestView: null
  modalPanel: null
  subscriptions: null
  joinSessionView: null
  startSessionView: null

  activate: (state) ->
    #Add toggle panel
    #TODO: remove unnecesary view
    #@coconuttestView = new CoconuttestView(state.coconuttestViewState)
    #@modalPanel = atom.workspace.addModalPanel(item: @coconuttestView.getElement, visible: false)

    guid = newGuid()

    #Add join session panel
    @joinSessionView = new JoinSessionView()
    @joinSessionPanel = atom.workspace.addModalPanel(item: @joinSessionView.element, visible: false)

    #Add start session panel
    @startSessionView = new StartSessionView(guid)
    @startSessionPanel = atom.workspace.addModalPanel(item: @startSessionView.element, visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'coconut:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'coconut:startSession': => @startSession()
    @subscriptions.add atom.commands.add 'atom-workspace', 'coconut:joinSession': => @joinSession()

    #Generate a pair of keys for RSA
    @generateKeys()
    #Get server's key
    @getServerKey()

    #Start session event
    @addStartSessionEvent()

    #Join session event
    @addJoinSessionEvent()

    #Text buffer change event
    #Add text buffer change events
    buffer = atom.workspace.getActiveTextEditor().buffer
    @subscriptions.add buffer.onDidChange (event) =>
      console.log event
      #Import server's public key into the key pair
      key.importKey serverKey, 'public'
      data =
        sessionId : guid
        message : key.encrypt(event.newText, 'base64')
        range: event.newRange
      socket.emit('message', data)

    #Socket listen event
    #Add socket change event
    socket.on 'message', (data) ->
      key.importKey clientKey, 'public'
      console.log('received: ' + key.decrypt(data.message, 'utf8'))
      #TODO: infinite loop
      atom.workspace.getActiveTextEditor().setTextInBufferRange(data.range, key.decrypt(data.message, 'utf8'))


  generateKeys: ->
    #Set key's length to 512 bits
    bufferObject =
      b : 512
    #Generate a pair of keys
    key = new NodeRsa bufferObject
    #Store client public key because the server's public key has to be imported at one point or another
    clientKey = key.exportKey 'public'
    console.log 'this is my public key ' + clientKey


  getServerKey: ->
    #Gets server public key for RSA Encryption
    $.ajax
      url: "http://localhost:3000/key"
      dataType: "html"
      async : false
      error: (jqXHR, textStatus, errorThrown) ->
        console.log "error: #{textStatus}"
      success: (data, textStatus, jqXHR) ->
        console.log "the key is #{data}"
        #Set the variable value according to the server's response
        serverKey = data

  #Start session and copy to clipboard event
  addStartSessionEvent: ->
    #Button click event
    $('.copy').click ->
      console.log guid
      #Copy to clipboard the session ID
      atom.clipboard.write(guid)
      #Join the room
      dataObject =
        sessionId : guid
        publicKey: clientKey
      socket.emit('join room', dataObject)

  #Join the room typed by the user
  addJoinSessionEvent: ->
    #Join button click event
    $('.button').click ->
      #Join the room coresponding to the Session ID
      guid = $('textarea').val()
      console.log guid
      dataObject =
        sessionId : guid
        publicKey: clientKey
      socket.emit('join room', dataObject)
      #Hide modal
      $('.button').parent().parent().hide()


  #Coconut activation commands
  toggle: ->
    console.log 'Coconut was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()

  startSession: ->
    console.log "Session started"
    if @startSessionPanel.isVisible()
      @startSessionPanel.hide()
    else
      #Edit panel value
      @guid = newGuid()
      $('.value').val(guid)
      @startSessionPanel.show()

  joinSession: ->
    console.log "Joined session"
    if @joinSessionPanel.isVisible()
      @joinSessionPanel.hide()
    else
      @joinSessionPanel.show()

  #Serializations and disposals
  deactivate: ->
    #destroy modals and views
    @modalPanel.destroy()
    @joinSessionPanel.destroy()
    @startSessionPanel.destroy()
    @subscriptions.dispose()
    @coconutView.destroy()
    @joinSessionView.destroy()
    @startSessionView.destroy()

  serialize: ->
    coconutViewState: @coconutView.serialize()
    joinSessionViewState : @joinSessionView.serialize()
    startSessionViewState: @startSessionView.serialize()
