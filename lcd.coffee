module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  class LCDPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      env.logger.info("Hello World")

  # ###Finally
  # Create a instance of my plugin
  lcdPlugin = new LCDPlugin
  # and return it to the framework.
  return lcdPlugin