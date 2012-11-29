intertwinkles.get_events = (query, callback) ->
  intertwinkles.socket.once "events", (data) ->
    if data.error? then return flash "error", data.error
    coll = new EventCollection()
    console.log(query, coll)
    for event in data.events
      event.date = new Date(event.date)
      coll.add(new Event(event))
    callback(coll)
    
  intertwinkles.socket.emit "get_events", { callback: "events", query: query }

intertwinkles.build_timeline = (selector, collection, formatter) ->
  timeline = new TimelineView({ collection: collection, formatter: formatter })
  $(selector).html(timeline.el)
  timeline.render()
  return timeline

class Event extends Backbone.Model
class EventCollection extends Backbone.Collection
  model: Event
  comparator: (r) -> return new Date(r.get("date")).getTime()

ruled_timeline_template = "
  <div class='container timeline'>
    <% for (var i = 0; i < rows.length; i++) { %>
      <div class='row-fluid ruled'>
        <div class='span2' style='text-align: right;'><%= rows[i].label %></div>
        <div class='span8' style='position: relative;'>
          <% for (var j = 0; j < rows[i].length; j++) { %>
            <% var point = rows[i][j]; %>
            <span class='timeline-bump' style='left: <%= point.left %>%'>
              <%- point.formatted %>
            </span>
          <% } %>
        </div>
      </div>
    <% } %>
    <div class='row-fluid'>
      <div class='span2'></div>
      <div class='span8 ruled' style='position: relative;'>
        <% for (var i = 0; i < ticks.length; i++) { %>
          <span class='date-legend'
                style='left: <%= ticks[i].left %>%'
                ><%= ticks[i].label %></span>
        <% } %>
      </div>
  </div>
"

#constant_timeline_template = "
#  <div class='container constline'>
#    <div class='line'>
#      <% for (var i = 0; i < points.length; i++) { %>
#            <a
#              style='left: <%= points[i].left %>%;'
#              class='point <%= points[i].type %>'
#              rel='popover'
#              data-trigger='hover'
#              data-placement='top'
#              title='<%= points[i].type %>'
#              data-content='<%= points[i].type %>'
#              ><%- points[i].icon %></a>
#      <% } %>
#      <% for (var i = 0; i < ticks.length; i++) { %>
#        <span class='tick'
#              title='<%= ticks[i].label %>'
#              style='left: <%= ticks[i].left %>%'
#            ></span>
#
#      <% } %>
#    </div>
#    <div class='hist'>
#      <% for (var i = 0; i < points.length; i++) { %>
#        <span class='bar'
#              style='height: <%= points[i].slope %>%; left: <%= points[i].left %>%; width: <%= 100 / points.length %>%;'></span>
#      <% } %>
#    </div>
#  </div>
#"

#class ConstantTimelineView extends Backbone.View
#  template: _.template(constant_timeline_template)
#  initialize: (options) ->
#    @coll = options.collection
#
#  render: =>
#    min_date = @coll.at(0).get("date")
#    min_time = min_date.getTime()
#    max_date = @coll.at(@coll.length - 1).get("date")
#    max_time = max_date.getTime()
#    time_span = Math.max(max_time - min_time, 1)
#    prev = null
#    for entry in @coll.models
#      entry.delta = entry.get("date").getTime() - min_time
#      if prev
#        entry.slope = entry.delta - prev.delta
#      else
#        entry.slope = 0
#      prev = entry
#    max_slope = Math.max.apply(null, (entry.slope for entry in @coll.models))
#
#    ideal_spacing = time_span / @coll.length
#    ticks = []
#    num_ticks = @coll.length * 64
#    pos = 0
#    for i in [0...num_ticks]
#      tick_delta = time_span / num_ticks * i
#      for j in [0...@coll.models.length]
#        cur = @coll.at(j)
#        if cur.delta >= tick_delta
#          if j == 0
#            left = 0
#          else
#            prev = @coll.at(j - 1)
#            left = 100 / @coll.length * (j - 1 +
#              (tick_delta - prev.delta) / (cur.delta - prev.delta)
#            )
#          ticks.push({left, label: new Date(tick_delta + min_time).toString("ddd M-d") + " (#{i + ", " + j})"})
#          break
#
#    points = []
#    i = 0
#    for entry in @coll.models
#      entry_json = entry.toJSON()
#      user = intertwinkles.users[entry_json.user_id]
#      if user?
#        entry_json.icon = "<img src='#{user.icon.tiny}' />"
#      else
#        entry_json.icon = "<i class='icon-user'></i>"
#      entry_json.left = (100 / @coll.length) * i++
#      entry_json.slope = 100 * (entry.slope / max_slope)
#      points.push(entry_json)
#
#    @$el.html(@template({points, ticks}))
#    @$("[rel=popover]").popover()
#    @$(".tick").tooltip()
#
#clumpy_timeline_template = "
#  <div class='container clumpline'>
#  </div>
#"
#
#class ClumpyTimelineView extends Backbone.View
#  template: _.template(clumpy_timeline_template)
#  initialize: (options) ->
#    @coll = options.collection
#
#  render: =>
#    min_time = @coll.at(0).get("date").getTime()
#    max_time = @coll.at(@coll.length - 1).get("date").getTime() + 1
#    time_span = max_time - min_time
#
#    min_diff = 0
#    max_diff = 10000000000000000
#    prev = null
#    for entry in @coll.models
#      entry.delta = entry.get("date").getTime() - min_time
#      if prev
#        entry.prev = prev
#        entry.prev.next = entry
#        entry.diff = entry.delta - prev.delta
#        min_diff = Math.min(min_diff, entry.diff)
#        max_diff = Math.max(max_diff, entry.diff)
#      else
#        entry.diff = 0
#
#    # Build a histogram of timeline densities
#    num_bins = 12
#    bin_width = time_span / num_bins
#    hist = ([] for i in [0...num_bins])
#    for entry in @coll.models
#      bin = Math.floor(entry.delta / bin_width)
#      hist[bin].push(entry)
#
#    console.log (h.length for h in hist)
#    return
#
#    largest_bin_size = Math.max.apply((h.length for h in hist))
#
#    # Identify the top 2 clusters by density
#    for i in [0...largest_bin_size]
#      thresh = largest_bin_size - i
#      breaks = []
#      sign = hist[0] < thresh
#      for bin, i in hist
#        bin = hist[i]
#        if bin.length < thresh != sign
#          sign = bin.length < thresh
#          breaks.push(i)
#          if breaks.length > 4
#            break
#      if breaks.length > 4
#        continue
#      if breaks.length > 2
#        break
#    console.log breaks

class RuledTimelineView extends Backbone.View
  template:  _.template(ruled_timeline_template)

  initialize: (options) ->
    @coll = options.collection
    @formatter = options.formatter

  render: =>
    if @coll.length == 0
      @$el.html("")
      return this
    rows = []
    ticks = []
    min_date = @coll.at(0).get("date")
    min_time = min_date.getTime()
    max_date = @coll.at(@coll.length - 1).get("date")
    max_time = max_date.getTime()
    time_span = Math.max(max_time - min_time, 1)
    @coll.each (entry) =>
      type = entry.get("type")
      unless rows[type]?
        rows[type] = []
        rows[type].label = entry.get("type")
        rows.push(rows[type])
      point = {
        formatted: @formatter(entry.toJSON())
        left: 100 * (entry.get("date").getTime() - min_time) / time_span
      }
      rows[type].push(point)

    # Build timeline scale
    if time_span < 1000 * 60
      date_fmt = "h:mm:s"
      step = 1000
    else if time_span < 1000 * 60 * 60
      date_fmt = "h:mm tt"
      step = 1000 * 60
    else if time_span < 1000 * 60 * 60 * 24
      date_fmt = "h tt"
      step = 1000 * 60 * 60
    else if time_span < 1000 * 60 * 60 * 24 * 7
      date_fmt = "ddd M-d"
      step = 1000 * 60 * 60 * 24
    else if time_span < 1000 * 60 * 60 * 24 * 14
      date_fmt = "M-d"
      step = 1000 * 60 * 60 * 24
    else if time_span < 1000 * 60 * 60 * 24 * 7 * 12
      date_fmt = "MMM d"
      step = 1000 * 60 * 60 * 24 * 31
    else if time_span < 1000 * 60 * 60 * 24 * 7 * 52
      date_fmt = "MMM"
      step = 1000 * 60 * 60 * 24 * 31
    else
      date_fmt = "yyyy"
      step = 1000 * 60 * 60 * 24 * 365

    # Adjust scale. #FIXME
    while time_span / step < 2
      step /= 2
    while time_span / step > 10
      step *= 2

    ticks = []
    i = 0
    while true
      next = step * i++
      if next < time_span
        ticks.push({
          label: new Date(min_time + next).toString(date_fmt)
          left: parseInt(next / time_span * 100)
        })
      else
        break

    @$el.html @template({ rows, ticks })
    @$("[rel=popover]").popover()

TimelineView = RuledTimelineView

#"
#            <a
#              style='left: <%= point.left %>%;'
#              class='<%= point.type %>'
#              rel='popover'
#              data-placement='top'
#              data-trigger='hover'
#              title='<%= point.type %>'
#              data-content='<%= point.type %>'
#              ><%- point.icon %></a>
#      user = intertwinkles.users[entry_json.user]
#      if user?
#        entry_json.icon = "<img src='#{user.icon.tiny}' />"
#      else
#        entry_json.icon = "<i class='icon-user'></i>"
#"
