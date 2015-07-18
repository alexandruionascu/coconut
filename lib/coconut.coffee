CoconutView = require './coconut-view'
{CompositeDisposable} = require 'atom'

module.exports = Coconut =
  coconutView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @coconutView = new CoconutView(state.coconutViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @coconutView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'coconut:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @coconutView.destroy()

  serialize: ->
    coconutViewState: @coconutView.serialize()

  toggle: ->
    console.log 'Coconut was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
