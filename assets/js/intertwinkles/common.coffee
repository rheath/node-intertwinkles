unless window.console?.log? and window.console?.error? and window.console?.debug? and window.console?.info?
  window.console = {log: (->), error: (->), debug: (->), info: (->)}
unless window.intertwinkles?
  window.intertwinkles = intertwinkles = {}
