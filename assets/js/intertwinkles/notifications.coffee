notification_menu_template = _.template("""
  <a href='#'
     class='dropdown-toggle notification-trigger<%= notices.length > 0 ? " unread" : "" %>'
     data-toggle='dropdown'
     role='button'><%= notices.length > 50 ? "50+" : notices.length %></a>
  <ul class='notifications dropdown-menu' role='menu'>
    <li class='linkless'><h3>Your Action Needed</h3></li>
    <% for (var i = 0; i < notices.length; i++) { %>
      <% var notice = notices[i]; %>
      <li class='notification <%= notice.read ? "read" : "" %>'>
        <a href='<%= notice.url %>' data-notification-id='<%= notice._id %>'>
          <span class='image'>
            <% var sender = intertwinkles.users[notice.sender]; %>
            <% if (sender) { %>
              <img src='<%= sender.icon.small %>' />
            <% } %>
          </span>
          <div class='message'>
            <div class='body'><%= notice.formats.web %></div>
            <div class='byline'><span class='date' data-date='<%= notice.date %>'></span></div>
          </div>
        </a>
      </li>
    <% } %>
    <li class='linkless'></li>
  </ul>
""")

class intertwinkles.NotificationMenu extends Backbone.View
  tagName: 'li'
  template: notification_menu_template
  events:
    'click .notification-trigger': 'openMenu'

  initialize: ->
    @notices = []
    @dateViews = []
    @open = false
    interval = setInterval =>
      if intertwinkles.socket?
        intertwinkles.socket.on "notifications", @handleNotifications
        @fetchNotifications()
        clearInterval(interval)
    , 100
     
    #XXX This will fire unnecessarily on name changes etc., but properly on
    # login/logout.
    intertwinkles.user.on "change", @fetchNotifications

  remove: =>
    intertwinkles.socket.removeListener "notifications", @handleNotifications
    intertwinkles.user.off "change", @fetchNotifications
    view.remove() for view in @dateViews
    super()

  fetchNotifications: (data) =>
    if intertwinkles.is_authenticated()
      console.log "fetch notifications"
      intertwinkles.socket.emit "get_notifications" # should result in 'render'
    else
      @notices = []
      @render() # just nuke 'em!

  handleNotifications: (data) =>
    console.log "handle notifications", data
    @notices = data.notifications
    @render()

  render: =>
    view.remove() for view in @dateViews
    if intertwinkles.is_authenticated() and @notices.length > 0
      @$el.addClass("notification-menu dropdown").html(@template {
        open: @open
        notices: @notices
      })

      @dateViews = []
      @$(".date").each (el) =>
        view = new intertwinkles.AutoUpdatingDate($(el).attr("data-date"))
        @dateViews.push(view)
        $(el).html view.render().el
    else
      @$el.html("")
    this

  openMenu: =>
    #@open = not @open
    #@render()
    #return false
