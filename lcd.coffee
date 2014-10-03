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
      lcd.afterInit = lcd.init()
      @framework.ruleManager.addActionProvider(new LCDDisplayActionProvider @framework, lcd)

  class LCDDisplayActionProvider extends env.actions.ActionProvider
  
    constructor: (@framework, @lcd) ->
      return

    parseAction: (input, context) =>

      textTokens = null
      setText = (m, tokens) => textTokens = tokens

      m = M(input, context)
        .match('display ')
        .match('text ', optional: yes)
        .matchStringWithVars(setText)
        .match(" on lcd")

      if m.hadMatch()
        match = m.getFullMatch()
        assert Array.isArray(textTokens)
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new LCDDisplayActionHandler(
            @framework, textTokens, @lcd
          )
        }
            

  class LCDDisplayActionHandler extends env.actions.ActionHandler 

    constructor: (@framework, @textTokens, @lcd) ->

    executeAction: (simulate, context) ->
      Promise.all( [
        @framework.variableManager.evaluateStringExpression(@textTokens)
      ]).then( ([text]) =>
        if simulate
          # just return a promise fulfilled with a description about what we would do.
          return __("would display \"%s\" on lcd", text)
        else
          return @lcd.afterInit
            .then( => @lcd.setCursor(0, 0) )
            .then( => @lcd.print(text) ).then( => 
              return __("displaying \"%s\" on lcd", text) 
            )
      )

  module.exports.LCDDisplayActionHandler = LCDDisplayActionHandler

  # ###Finally
  # Create a instance of my plugin
  lcdPlugin = new LCDPlugin
  # and return it to the framework.
  return lcdPlugin