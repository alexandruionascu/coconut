window.$ = window.jQuery = require('../node_modules/jquery')
NodeRsa = require('../node_modules/node-rsa')
io = require('../node_modules/socket.io-client')
#Connect to the node server
socket = io.connect('http://localhost:3000')
newGuid = require './aux_tools/guid'


#Require QR Code generator
require('../node_modules/webcomponents.js/webcomponents')
require('../node_modules/webcomponent-qr-code/src/qr-code')


#Views
JoinSessionView = require('./joinsession-view')
StartSessionView = require('./startsession-view')
SyncView = require('./sync-view')
FacebookView = require('./facebook-view')
WhatsappView = require('./whatsapp-view')
SlackView = require('./slack-view')
{CompositeDisposable} = require 'atom'

startSessionView = null
startSessionPanel = null
joinSessionView = null
joinSessionPanel = null
syncPanel = null
facebookPanel = null
slackPanel = null
whatsappPanel = null

#Prevent infinite looping
triggerEvent = true


#Session ID
guid = null
#Pairing ID for companion app
pairId = null
#Public and private key pair
key = null
#Server public key
serverKey = null
#Client's public key
clientKey= null

#Hold events
subscriptions = null


module.exports = Coconut =

  subscriptions: null
  joinSessionView: null
  startSessionView: null
  syncView: null
  facebookView: null



  activate: (state) ->

    guid = newGuid()
    pairId = newGuid()



    #Add join session panel
    joinSessionView = new JoinSessionView()
    joinSessionPanel = atom.workspace.addModalPanel(item: joinSessionView.element, visible: false)

    #Add start session panel
    startSessionView = new StartSessionView(guid)
    startSessionPanel = atom.workspace.addModalPanel(item: startSessionView.element, visible: false)

    #Add sync panel
    syncView = new SyncView(pairId)
    syncPanel = atom.workspace.addModalPanel(item: syncView.element, visible: false)

    #Add Facebook panel
    facebookView = new FacebookView()
    facebookPanel = atom.workspace.addRightPanel(item: facebookView.element, visible: false)

    whatsappView = new WhatsappView()
    whatsappPanel = atom.workspace.addRightPanel(item: whatsappView.element, visible:false)

    slackView = new SlackView()
    slackPanel = atom.workspace.addRightPanel(item: slackView.element, visible: false)


    #Add qr code in modal
    $('.qr-text').append('<qr-code modulesize="10" data="' + pairId + '"></qr-code>')
    $('.qr-text').focus()
    #Hide sync panel at click
    $('.qr-text').click ->
      syncPanel.hide()

    $('.facebook').append('<webview id="foo" src="https://www.messenger.com/" style="display:inline-block; width:640px; height:100%"></webview>')
    $('.whatsapp').append('<webview id="foo" src="https://www.whatsapp.com/" style="display:inline-block; width:640px; height:100%"></webview>')
    $('.slack').append('<webview id="foo" src="https://www.slack.com/signin/" style="display:inline-block; width:640px; height:100%"></webview>')


    #Audio pair
    socket.emit('pair audio', pairId)
    socket.on 'pair id', ->
        console.log 'Audio paired!'

    #Receive audio note from companion
    socket.on 'receive audio' , (data) ->
      console.log data
      atom.workspace.getActiveTextEditor().insertText(':audio:' + data)


    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    subscriptions = new CompositeDisposable

    # Register command that toggles this view
    subscriptions.add atom.commands.add 'atom-workspace', 'coconut:toggle': => @toggle()
    subscriptions.add atom.commands.add '.editor', 'coconut:playAudioNote': => @playAudioNote()
    subscriptions.add atom.commands.add 'atom-workspace', 'coconut:startSession': => @startSession()
    subscriptions.add atom.commands.add 'atom-workspace', 'coconut:joinSession': => @joinSession()
    subscriptions.add atom.commands.add 'atom-workspace', 'coconut:sync': => @sync()
    subscriptions.add atom.commands.add 'atom-workspace', 'coconut:facebookToggle': => @facebookToggle()
    subscriptions.add atom.commands.add 'atom-workspace', 'coconut:whatsappToggle': => @whatsappToggle()
    subscriptions.add atom.commands.add 'atom-workspace', 'coconut:slackToggle': => @slackToggle()

    audioElement = document.createElement('audio')
    audioElement.setAttribute('src', 'https://coconutaudio.blob.core.windows.net/recordings/9b89b7f.mp4')
    audioElement.setAttribute('autoplay', 'autoplay')

    audioElement.play();


    #Generate a pair of keys for RSA
    @generateKeys()
    #Get server's key
    @getServerKey()

    #Audio sync
    socket.emit('audio sync', pairId)

    #Socket disconnect event
    socket.on 'disconnect', ->
      alert 'You have been disconnected, please reload the window.'

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
      #Hide the modal
      startSessionPanel.hide()

    #Join the room
    dataObject =
      sessionId : guid
      publicKey: clientKey
    socket.emit('join room', dataObject)
    #atom.workspace.getActiveTextEditor().insertText 'bai '
    @addReceiveChangeEvent(atom.workspace.getActiveTextEditor().buffer)
    @addEmitChangeEvent(atom.workspace.getActiveTextEditor().buffer)
    @addRequestInitEvent()



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
      #Get the current text of the session
      socket.on 'init' , (data) ->
        #  key.importKey clientKey, 'public'
        #  decrypted = key.decrypt(data, 'utf8')
        console.log 'synced : ' + data
        triggerEvent = false
        atom.workspace.getActiveTextEditor().insertText(data)
        triggerEvent = true
      #Hide modal
      joinSessionPanel.hide()

    @addEmitChangeEvent(atom.workspace.getActiveTextEditor().buffer)
    @addReceiveChangeEvent(atom.workspace.getActiveTextEditor().buffer)
    @addRequestInitEvent(atom.workspace.getActiveTextEditor().buffer)


  #Text buffer change event
  addEmitChangeEvent: (buffer) ->
    #Add text buffer change events
    subscriptions.add buffer.onDidChange (event) =>
      if triggerEvent == false
        return
      #Import server's public key into the key pair
      key.importKey serverKey, 'public'
      #Convert the event object to string
      data = JSON.stringify(event)
      #Encrypt the string
      encryptedData = key.encrypt(data, 'base64')
      #Emit to server
      socket.emit('message', encryptedData)


  #Socket listen event
  addReceiveChangeEvent: (buffer) ->
      #Add socket change event
      socket.on 'message', (data) ->
        console.log 'Received a message from a buddy'
        key.importKey clientKey, 'public'
        decrypted = key.decrypt(data, 'utf8')
        #Parse data into an object
        event = JSON.parse(decrypted)
        #Prevent triggering
        triggerEvent = false
        #Update the active text editor with no event triggering
        if event.newText.length == 0
          #Then delete
          buffer.delete event.oldRange
        else if event.oldRange
          #Then replace
          buffer.setTextInRange(event.oldRange, event.newText)
        else
          #Insert
          buffer.insert event.newRange.start, event.newText
        triggerEvent = true


  addRequestInitEvent: (buffer) ->
    #Socket event when someone asks to join the session and sync the text
    socket.on 'request init' , ->
      currentText = atom.workspace.getActiveTextEditor().getText()
      console.log currentText
      console.log 'requested--yes'
      key.importKey serverKey, 'public'
      #Encrypt the string
      encryptedData = key.encrypt(currentText, 'base64')
      #Emit to server
      socket.emit('init', encryptedData)


  facebookToggle: ->
    if facebookPanel.isVisible()
      facebookPanel.hide()
    else
      facebookPanel.show()

  whatsappToggle: ->
    if whatsappPanel.isVisible()
      whatsappPanel.hide()
    else whatsappPanel.show()

  slackToggle: ->
    if slackPanel.isVisible()
      slackPanel.hide()
    else
      slackPanel.show()


  startSession: ->
    console.log "Session started"
    if startSessionPanel.isVisible()
      startSessionPanel.hide()
    else
      #Edit panel value
      guid = newGuid()
      $('.value').val(guid)
      startSessionPanel.show()
      #Start session event
      @addStartSessionEvent()

  joinSession: ->
    console.log "Joined session"
    if joinSessionPanel.isVisible()
      joinSessionPanel.hide()
    else
      joinSessionPanel.show()
      #Join session event
      @addJoinSessionEvent()

  sync: ->
    if syncPanel.isVisible()
      syncPanel.hide()
    else
      syncPanel.show()

  playAudioNote: ->
    #Get cursor position
    lineIndex = atom.workspace.getActiveTextEditor().getCursorBufferPosition()
    #Get the text from current line
    line = atom.workspace.getActiveTextEditor().lineTextForScreenRow(lineIndex.row)
    #Get the beginning of the url
    noteStart = str.search(':audio:')



  #Serializations and disposals
  deactivate: ->
    #destroy modals and views
    joinSessionPanel.destroy()
    startSessionPanel.destroy()
    subscriptions.dispose()
    joinSessionView.destroy()
    startSessionView.destroy()

  serialize: ->
    joinSessionViewState : joinSessionView.serialize()
    startSessionViewState: startSessionView.serialize()
