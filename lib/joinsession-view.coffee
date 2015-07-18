{View} = require '../node_modules/atom-space-pen-views'

module.exports =
class JoinCoconutView extends View
  @content: ->
    @div class:'styleguide padded pane-item native-key-bindings' , =>
      @div 'Enter the session ID:'
      @textarea 'fuego'
      @span class:'button', 'ok'

  initialize: (serializeState) ->

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()
