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
      @framework.ruleManager.addActionProvider(
        new LCDDisplayActionProvider @framework, lcd, @config
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
        if simulate
          # just return a promise fulfilled with a description about what we would do.
          return __("would display \"%s\" on lcd line %s", text, line)
        else
          rows = @pluginConfig.rows
          cols = @pluginConfig.cols
          unless 1 <= line <= rows
            throw new Error("line must be between 1 and #{rows}")

          if line.length > cols
            line = line.substring(0, cols-1)
          else if line.length < cols
            line = line + " ".repeat(line.length - cols)

          return @lcd.pendingOperation = @lcd.pendingOperation
            .then( => @lcd.setCursor(0, line-1) )
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