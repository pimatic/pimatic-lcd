module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'
  M = env.matcher
  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  LCD = require 'i2c-lcd'

  class LCDPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      lcd = new LCD(@config.bus, @config.address)
      lcd.pendingOperation = lcd.init()
      @framework.ruleManager.addActionProvider(new LCDDisplayActionProvider @framework, lcd)

  class LCDDisplayActionProvider extends env.actions.ActionProvider
  
    constructor: (@framework, @lcd) ->
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
        .match(" line ", (next) =>
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
            @framework, @lcd, textTokens, lineNumber
          )
        }
            

  class LCDDisplayActionHandler extends env.actions.ActionHandler 

    constructor: (@framework, @lcd, @textTokens, @lineNumber) ->

    executeAction: (simulate, context) ->
      Promise.all( [
        @framework.variableManager.evaluateStringExpression(@textTokens)
        @framework.variableManager.evaluateNumericExpression(@lineNumber)
      ]).then( ([text, line]) =>
        if simulate
          # just return a promise fulfilled with a description about what we would do.
          return __("would display \"%s\" on lcd line %s", text, line)
        else
          return @lcd.pendingOperation = @lcd.pendingOperation
            .then( => @lcd.setCursor(0, line) )
            .then( => @lcd.print(text) ).then( => 
              return __("displaying \"%s\" on lcd line %s", text, line) 
            )
      )

  module.exports.LCDDisplayActionHandler = LCDDisplayActionHandler

  # ###Finally
  # Create a instance of my plugin
  lcdPlugin = new LCDPlugin
  # and return it to the framework.
  return lcdPlugin