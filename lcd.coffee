module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'
  S = env.require 'string'
  M = env.matcher
  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  LCD = require 'i2c-lcd'

  class LCDPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      lcd = new LCD(@config.bus, @config.address)
      lcd.pendingOperation = lcd.init()
      @lcd._printedLines = []
      @framework.ruleManager.addActionProvider(
        new LCDDisplayActionProvider @framework, lcd, @config
      )
      @framework.ruleManager.addActionProvider(
        new LCDBacklightActionProvider @framework, lcd, @config
      )

  class LCDDisplayActionProvider extends env.actions.ActionProvider
  
    constructor: (@framework, @lcd, @pluginConfig) ->
      return

    parseAction: (input, context) =>

      textTokens = null
      setText = (m, tokens) => textTokens = tokens
      lineNumber = [ 1 ]

      m = M(input, context)
        .match('display ')
        .match('text ', optional: yes)
        .matchStringWithVars(setText)
        .match(" on lcd")
      if m.hadMatch()
        m.match(" line ", (next) =>
          next.matchNumericExpression( (next, tokens) =>
            lineNumber = tokens
            m = next
          )
        )

      if m.hadMatch()
        match = m.getFullMatch()
        assert Array.isArray(textTokens)
        assert Array.isArray(lineNumber)
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new LCDDisplayActionHandler(
            @framework, @lcd, @pluginConfig, textTokens, lineNumber
          )
        }
            

  class LCDDisplayActionHandler extends env.actions.ActionHandler 

    constructor: (@framework, @lcd, @pluginConfig, @textTokens, @lineNumber) ->

    executeAction: (simulate, context) ->
      Promise.all( [
        @framework.variableManager.evaluateStringExpression(@textTokens)
        @framework.variableManager.evaluateNumericExpression(@lineNumber)
      ]).then( ([text, line]) =>
        @lastLine = line
        if simulate
          # just return a promise fulfilled with a description about what we would do.
          return __("would display \"%s\" on lcd line %s", text, line)
        else
          rows = @pluginConfig.rows
          cols = @pluginConfig.cols
          unless 1 <= line <= rows
            throw new Error("line must be between 1 and #{rows}")

          if text.length > cols
            printText = text.substring(0, cols)
          else if text.length < cols
            printText = S(text).padRight(cols).s

          return @lcd.pendingOperation = @lcd.pendingOperation
            .then( => @lcd.setCursor(0, line-1) )
            .then( =>
              @lastPrintText = printText
              @lcd._printedLines[line-1] = printText # remember new text
              return @lcd.print(printText)
            ).then( =>  __("displaying \"%s\" on lcd line %s", text, line) )
      )

    hasRestoreAction: -> yes
    # ### executeRestoreAction()
    executeRestoreAction: (simulate) -> 
      if simulate
        return Promise.resolve __("would clear LCD line %s", @lastLine)
      else
        # only clear if it not changed in between
        if @lastPrintText is @lcd._printedLines[@lastLine-1]
          return @lcd.pendingOperation = @lcd.pendingOperation
            .then( => @lcd.setCursor(0, @lastLine-1) )
            .then( =>
              printText = S(" ").repeat(@pluginConfig.rows).s
              @lcd._printedLines[@lastLine-1] = printText
              return @lcd.print(printText)
            ).then( =>  __("cleared LCD line %s", @lastLine) )
        else
          Promise.resolve  __("didn't clear LCD line %s because it changed", @lastLine)



  class LCDBacklightActionProvider extends env.actions.ActionProvider
  
    constructor: (@framework, @lcd, @pluginConfig) ->
      return

    parseAction: (input, context) =>

      state = null
      setState = (next, match) => state = (match.trim() is "on") 

      m = M(input, context)
        .match('turn ')
        .match('the ', optional: yes)
        .match('LCD')
        .match(' backlight', optional: yes)
        .match([' on', ' off'], setState)

      if m.hadMatch()
        match = m.getFullMatch()
        assert typeof state is "boolean"
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new LCDBacklightActionHandler(
            @framework, @lcd, @pluginConfig, state
          )
        }
            

  class LCDBacklightActionHandler extends env.actions.ActionHandler 

    constructor: (@framework, @lcd, @pluginConfig, @state) ->

    executeAction: (simulate, context) ->
      return Promise.resolve().then( =>
        if simulate
          # just return a promise fulfilled with a description about what we would do.
          return __("would turn LCD %s", (if @state then __("on") else __("off") ) )
        else
          return (
            if @state
              @lcd.pendingOperation = @lcd.pendingOperation.then( => @lcd.on() )
            else
              @lcd.pendingOperation = @lcd.pendingOperation.then( => @lcd.off() )
          ).then( =>
            return __("turned LCD backlight %s", (if @state then __("on") else __("off") ) )
          )
      )

  module.exports.LCDDisplayActionHandler = LCDDisplayActionHandler
  module.exports.LCDBacklightActionProvider = LCDBacklightActionProvider

  # ###Finally
  # Create a instance of my plugin
  lcdPlugin = new LCDPlugin
  # and return it to the framework.
  return lcdPlugin