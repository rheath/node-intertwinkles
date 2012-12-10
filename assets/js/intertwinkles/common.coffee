unless window.console?.log? and window.console?.error? and window.console?.debug? and window.console?.info?
  window.console = {log: (->), error: (->), debug: (->), info: (->)}
unless window.intertwinkles?
  window.intertwinkles = intertwinkles = {}

class intertwinkles.BaseView extends Backbone.View
  softNav: (event) =>
    event.preventDefault()
    intertwinkles.app.navigate($(event.currentTarget).attr("href"), {
      trigger: true
    })
  initialize: ->
    @views = []

  remove: =>
    if @views?
      view.remove() for view in @views
    super()

  addView: (selector, view) =>
    @$(selector).html(view.el)
    view.render()
    @views.push(view)

  validateFields: (container, selectors) =>
    cleaned_data = {}
    dirty = false
    $(".error", container).removeClass("error")
    $(".error-msg", container).remove()
    for [selector, test, msg] in selectors
      el = @$(selector)
      if el.attr("type") == "checkbox"
        val = el.is(":checked")
      else
        val = el.val()

      clean = test(val)
      if clean?
        cleaned_data[el.attr("name")] = clean
      else
        dirty = true
        parent = el.closest(".control-group")
        parent.addClass("error")
        parent.find(".controls").prepend(
          "<span class='error-msg help-inline'>#{msg}</span>"
        )
    if dirty
      return false
    return cleaned_data

  renderUser: (user_id, name) ->
    if user_id? and intertwinkles.users?[user_id]? and intertwinkles.users[user_id].icon?
      user = intertwinkles.users[user_id]
      return "<span class='user'><img src='#{user.icon.tiny}' /> #{user.name}</span>"
    else
      return "<span class='user'><i class='icon-user'></i> #{name or "Anonymous"}</span>"

intertwinkles.BaseEvents = {
  'click .softnav': 'softNav'
}
