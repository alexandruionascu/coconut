{View} = require '../node_modules/atom-space-pen-views'

module.exports =
class StartSessionView extends View

  @content: (@sessionId) ->
    @div  =>
      @span 'Your session ID is: '
      @span class: 'value' , @sessionId
      @span class: 'copy', 'Copy to clipboard'

  initialize: (serializeState) ->

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()
