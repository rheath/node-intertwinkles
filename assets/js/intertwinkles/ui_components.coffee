#
# User menu
#

user_menu_template = _.template("""
  <a class='user-menu dropdown-toggle' href='#' data-toggle='dropdown' role='button'>
    <% if (user.icon && user.icon.tiny) { %>
      <img src='<%= user.icon.tiny %>' alt='<%= user.icon.color %> <%= user.icon.name %>' />
    <% } else { %>
      <i class='icon-user'></i>
    <% } %>
    <span class='hidden-phone'>
      <%= user.name %>
    </span>
    <b class='caret'></b>
  </a>
  <ul class='dropdown-menu' role='menu'>
    <li><a tabindex='-1' href='<%= INTERTWINKLES_APPS.www.url %>/profiles/edit'><i class='icon icon-cog'></i> Settings</a></li>
    <li class='divider'></li>
    <li><a tabindex='-1' class='sign-out' href='#'>Sign out</a></li>
  </ul>
""")
class intertwinkles.UserMenu extends Backbone.View
  tagName: 'li'
  template: user_menu_template
  events:
    'click .sign-out': 'signOut'

  initialize: ->
    intertwinkles.user.on "change", @render

  remove: =>
    intertwinkles.user.off "change", @render
    super()

  render: =>
    @$el.addClass("dropdown")
    if intertwinkles.is_authenticated()
      @$el.html(@template(user: intertwinkles.user.toJSON()))
    else
      @$el.html("")
    @setAuthFrameVisibility()

  setAuthFrameVisibility: =>
    if intertwinkles.is_authenticated()
      $("#auth_frame").hide()
    else
      $("#auth_frame").show()

  signOut: (event) =>
    event.preventDefault()
    intertwinkles.request_logout()

#
# Room users menu
#

room_users_menu_template = _.template("""
  <a class='room-menu dropdown-toggle btn' href='#' data-toggle='dropdown'
     title='People in this room'>
    <i class='icon-user'></i><span class='count'></span>
    <b class='caret'></b>
  </a>
  <ul class='dropdown-menu' role='menu'></ul>
""")
room_users_menu_item_template = _.template("""
  <li><a>
    <% if (icon) { %>
      <img src='<%= icon.tiny %>' />
    <% } else { %>
      <i class='icon icon-user'></i>
    <% } %>
    <%= name %>
  </a></li>
""")

class intertwinkles.RoomUsersMenu extends Backbone.View
  tagName: "li"
  template: room_users_menu_template
  item_template: room_users_menu_item_template

  initialize: (options={}) ->
    @room = options.room
    intertwinkles.socket.on "room_users", @roomList
    intertwinkles.socket.emit "join", {room: @room}
    @list = []

  remove: =>
    intertwinkles.socket.removeListener "room_users", @roomList
    intertwinkles.socket.emit "leave", {room: @room}
    super()

  roomList: (data) =>
    @list = data.list
    if data.anon_id?
      @anon_id = data.anon_id
    @renderItems()
    
  render: =>
    @$el.addClass("room-users dropdown")
    @$el.html @template()
    @renderItems()

  renderItems: =>
    @$(".count").html(@list.length)
    @menu = @$(".dropdown-menu")
    @menu.html("")
    for item in @list
      self = item.anon_id == @anon_id
      context = _.extend {self}, item
      if self
        @menu.prepend(@item_template(context))
      else
        @menu.append(@item_template(context))
    @menu.prepend("<li><a>Online now:</a></li>")

#
# Toolbar
#

intertwinkles.build_toolbar = (destination, options) ->
  toolbar = new intertwinkles.Toolbar(options)
  $(destination).html(toolbar.el)
  toolbar.render()
  $(".auth_frame").html(intertwinkles.auth_frame_template())
  toolbar.setAuthFrameVisibility()

toolbar_template = _.template("""
  <div class='navbar navbar-top nav'>
    <div class='navbar-inner'>
      <div class='container-fluid'>
        <ul class='nav pull-right'>
          <li class='invite-helper dropdown'></li>
          <li class='search-menu dropdown'>
            <a href='#' title='search' data-toggle='dropdown' class='search-menu-trigger'>
              <i class='icon-search'></i>
              <span class='hidden-phone'>Search</span>
            </a>
            <ul class='dropdown-menu search' role='menu' aria-labeledby='dlogo'>
              <li class='linkless'>
                <form class='form-search'
                      action='<%= INTERTWINKLES_APPS.www.url %>/search/'
                      method='GET'>
                  <div class='input-append'>
                    <input class='input-medium search-query' type='text' name='q' />
                    <button class='btn' type='submit'>
                      <i class='icon-search' title='Search'></i>
                    </button>
                  </div>
                </form>
              </li>
            </ul>
          </li>
          <li class='notifications dropdown'></li>
          <li class='user-menu dropdown'></li>
          <li class='auth_frame'></li>
        </ul>
        <a class='brand dropdown-toggle'
           data-target='.nav-collapse' data-toggle='collapse' href='#'
           role='button' id='dlogo'>
          <span class='visible-phone'>
            I<span class='intertwinkles'>T</span>
            <span class='appname'><%= apps[0].name.substr(0, 1) %></span>
            <b class='caret'></b>
            <span class='label' style='font-size: 50%;'>B</span>
          </span>
          <span class='hidden-phone'>
            Inter<span class='intertwinkles'>Twinkles</span>:
            <span class='appname'><%= apps[0].name %></span>
            <b class='caret'></b>
            <span class='label' style='font-size: 50%;'>BETA</span>
          </span>
        </a>
        <div class='pull-left nav-collapse collapse' style='height: 0px;'>
          <ul class='nav appmenu'>
            <% for (var i = 0; i < apps.length; i++) { %>
              <% var app = apps[i]; %>
              <li class='<%= i == 0 ? "active" : "" %>'>
                <a href='<%= app.url + "/" %>'>
                  <b><%= app.name %></b>: <%= app.about %>
                </a>
              </li>
            <% } %>
          </ul>
        </div>
      </div>
    </div>
  </div>
""")

class intertwinkles.Toolbar extends Backbone.View
  template: toolbar_template
  initialize: (options={}) ->
    @applabel = options.applabel

  remove: =>
    @user_menu?.remove()
    @notification_menu?.remove()
    super()

  render: =>
    apps = []
    thisapp = null
    for label, app of INTERTWINKLES_APPS
      if label == @applabel
        apps.unshift(app)
      else
        apps.push(app)

    @$el.html @template({apps: apps})

    @user_menu?.remove()
    @user_menu = new intertwinkles.UserMenu()
    @$(".user-menu.dropdown").replaceWith(@user_menu.el)
    @user_menu.render()

    @notification_menu?.remove()
    @notification_menu = new intertwinkles.NotificationMenu()
    @$(".notifications").replaceWith(@notification_menu.el)
    @notification_menu.render()

    invite_helper = new intertwinkles.InviteHelper()
    @$(".invite-helper").replaceWith(invite_helper.el)
    invite_helper.render()

    this

  setAuthFrameVisibility: => @user_menu.setAuthFrameVisibility()

#
# Footer
#

footer_template = _.template("""
<div class='bg'>
  <img src='/static/img/coop-world.png' alt='Flavor image' />
</div>
<div class='container-fluid'>
  <div class='ramp'></div>
  <div class='footer-content'>
    <div class='row-fluid'>
      <div class='span4 about-links'>
        <h2>About</h2>
        <ul>
          <li><a href='#{INTERTWINKLES_APPS.www.url}/about/'>About</a><small>: Free software revolutionary research</small></li>
          <li><a href='#{INTERTWINKLES_APPS.www.url}/about/terms/'>Terms of Use</a><small>: Play nice</small></li>
          <li><a href='#{INTERTWINKLES_APPS.www.url}/about/privacy/'>Privacy Policy</a><small>: You own it</small></li>
          <li><a href='http://github.com/yourcelf/intertwinkles/'>Source Code</a><small>: Run your own!</small></li>
        </ul>
      </div>
      <div class='span4 community'>
        <h2>Community</h2>
        <ul>
          <li><a href='http://lists.byconsens.us/mailman/listinfo/design'>Codesign mailing list</a></li>
          <li><a href='http://project.intertwinkles.org/'>Project tracker</a></li>
          <li><a href='#{INTERTWINKLES_APPS.www.url}/about/related/'>Related projects</a></li>
        </ul>
      </div>
      <div class='span4 sponsors'>
        <h2>Supported by</h2>
        <a href='http://civic.mit.edu'>
          <img alt='The MIT Center for Civic Media' src='/static/img/C4CM.png'>
        </a>

        <a href='http://media.mit.edu/speech'>
          <img alt='The Speech + Mobility Group' src='/static/img/S_M.png'>
        </a>
      </div>
    </div>
  </div>
</div>
""")

intertwinkles.build_footer = (destination) ->
  $(destination).html(footer_template())


#
# User choice widget
#

user_choice_template = _.template("""
  <input type='text' name='name' id='id_user' data-provide='typeahead' autocomplete='off' value='<%= name %>' />
  <span class='icon-holder' style='width: 32px; display: inline-block;'>
    <% if (icon) { %><img src='<%= icon %>' /><% } %>
  </span>
  <input type='hidden' name='user_id' id='id_user_id' value='<%= user_id %>' />
  <div class='form-hint unknown'></div>
""")

class intertwinkles.UserChoice extends Backbone.View
  tagName: "span"
  template: user_choice_template
  events:
    'keydown input': 'onkey'

  initialize: (options={}) ->
    @model = options.model or {}
    intertwinkles.user.on "change", @render

  remove: =>
    intertwinkles.user.off "change", @render
    super()

  set: (user_id, name) =>
    @model = { user_id: user_id, name: name }
    @$("#user_id").val(name)
    @$("#id_user_id").val(user_id)
    @render()

  render: =>
    user_id = @model.get?("user_id") or @model.user_id
    if user_id and intertwinkles.users?[user_id]?
      name = intertwinkles.users[user_id].name
      icon = intertwinkles.users[user_id].icon
    else
      user_id = ""
      name = @model.get?("name") or @model.name or ""
      icon = {}

    @$el.html(@template({
      name: name
      user_id: user_id
      icon: if icon.small? then icon.small else ""
    }))

    @$("#id_user").typeahead {
      source: @source
      matcher: @matcher
      sorter: @sorter
      updater: @updater
      highlighter: @highlighter
    }
    this

  onkey: (event) =>
    if @$("#id_user").val() != @model.get?("name") or @model.name
      @$(".icon-holder").html("")
      @$("#id_user_id").val("")
      if intertwinkles.is_authenticated()
        @$(".unknown").html("Not a known group member.")
      else
        @$(".unknown").html("
          Sign in first to see your groups. &#8599;
        ")

  source: (query) ->
    return ("#{id}" for id,u of intertwinkles.users)

  matcher: (item) ->
    name = intertwinkles.users[item]?.name
    return name and name.toLowerCase().indexOf(@query.toLowerCase()) != -1

  sorter: (items) ->
    return _.sortBy items, (a) -> intertwinkles.users[a].name

  updater: (item) =>
    @$("#id_user_id").val(item)
    @$(".unknown").html("")
    user = intertwinkles.users[item]
    @model = user
    if user.icon?
      @$(".icon-holder").html("<img src='#{user.icon.small}' />")
    else
      @$(".icon-holder").html("")
    return intertwinkles.users[item].name

  highlighter: (item) ->
    user = intertwinkles.users[item]
    if user.icon?.small?
      img = "<img src='#{user.icon.small}' />"
    else
      img = "<span style='width: 32px; display: inline-block;'></span>"
    query = this.query.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, '\\$&')
    highlit = user.name.replace new RegExp('(' + query + ')', 'ig'), ($1, match) ->
      return '<strong>' + match + '</strong>'
    return "<span>#{img} #{highlit}</span>"

#
# Group choice widget
#

group_choice_template = _.template("""
  <% if (intertwinkles.is_authenticated()) { %>
    <% var has_group = _.keys(intertwinkles.groups).length > 0; %>
    <% if (has_group) { %>
      <select id='id_group'>
        <option value=''>----</option>
        <% for (var key in intertwinkles.groups) { %>
          <% group = intertwinkles.groups[key]; %>
          <option value='<%= group.id %>'><%= group.name %></option>
        <% } %>
      </select>
    <% } else { %>
      <input type='hidden' id='id_group' />
      You don't have any groups yet.
    <% } %>
    <br />
    (<%= has_group ? "or " : "" %><a href='<%= INTERTWINKLES_APPS.www.url %>/groups/new/'>create a new group</a>)
  <% } else { %>
    Sign in to add a group.
  <% } %>
""")

class intertwinkles.GroupChoice extends Backbone.View
  tagName: "span"
  template: group_choice_template
  initialize: (options={}) ->
  render: =>
    @$el.html(@template())
    this

#
# Invite helper
#

intertwinkles.get_short_url = (params, callback) ->
  socket_callback = "short_url_#{Math.random()}"
  intertwinkles.socket.once socket_callback, (data) ->
    if data.error?
      callback(data.error, null)
    else
      callback(null, data.short_url)


  intertwinkles.socket.emit "get_short_url", {
    callback: socket_callback, application: params.application, path: params.path
  }

invite_helper_template = _.template("
<a href='#' class='dropdown-toggle invite-helper'
   data-toggle='dropdown'
   title='Barcodes and short URLs' >&lt;/&gt; <i class='caret'></i> </a>
<ul class='dropdown-menu invite-helper-menu' role='menu'>
  <li class='linkless'>
    <%= message %><br />
    <input readonly type='text' value='<%= url %>' />
    <br />
    <a class='barcode' data-url='<%= url %>' href='#'>Get barcode</a><br />
    <a class='short-url'
       data-url='<%= url %>'
       data-application='<%= application %>'
       href='#'>Get short URL</a>
  </li>
</ul>
")

class intertwinkles.InviteHelper extends Backbone.View
  tagName: "li"
  template: invite_helper_template
  events:
    'click .barcode': 'getBarcode'
    'click .short-url': 'getShortUrl'
    'click input': 'selectText'
  initialize: (options) ->
    @message = options?.message or "Invite others with this link:"
    @url = options?.url or window.location.href
    @application = options?.application or INITIAL_DATA.application

  selectText: (event) =>
    $(event.currentTarget).select()
    event.stopPropagation()
    event.preventDefault()

  render: (event) =>
    @$el.addClass("invite-helper dropdown")
    if @application? and @url?
      @$el.html(@template({
        url: @url
        application: @application
        message: @message
      }))
    else
      @$el.html("")

  getBarcode: (event) =>
    event.preventDefault()
    event.stopPropagation()
    loading = $("<span></span>").html("<img src='/static/img/spinner.gif' /> ...")
    @$(".barcode").replaceWith(loading)
    url = $(event.currentTarget).attr("data-url")
    #TODO: Replace this with a local or https-safe option.
    img =  $("<img class='qurcode' />").attr("src",
      "http://api.qrserver.com/v1/create-qr-code/" +
      "?size=150x150&data=#{encodeURIComponent(url)}")
    img.on "load", -> loading.remove()
    loading.after img

  getShortUrl: (event) =>
    event.preventDefault()
    event.stopPropagation()
    orig = $(event.currentTarget)
    url = orig.attr("data-url")
    application = orig.attr("data-application")

    loading = $("<span></span>").html("<img src='/static/img/spinner.gif' /> ...")
    @$(".short-url").replaceWith(loading)
    intertwinkles.get_short_url { path: url, application: application }, (err, result) ->
      if err?
        console.error(err)
        flash "error", "Server error!... sorrrrrry."
        loading.replaceWith(orig)
      else
        loading.replaceWith("Short URL:<br /><input type='text' readonly value='#{result}' />")
