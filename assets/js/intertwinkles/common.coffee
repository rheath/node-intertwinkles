unless window.console?.log?
  window.console = { log: (->), err: (->) }
unless window.intertwinkles?
  window.intertwinkles = intertwinkles = {}

