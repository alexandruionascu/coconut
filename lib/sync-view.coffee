{View} = require '../node_modules/atom-space-pen-views'

module.exports =
class SyncView extends View
  @content: ->
    @div class:'sync' , =>
      @div class:'qr-text','Scan the QR Code:'


  initialize: (serializeState) ->

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()
