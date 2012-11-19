class intertwinkles.User extends Backbone.Model
  idAttribute: "id"

#
# User authentication state
#
intertwinkles.user = new intertwinkles.User()
intertwinkles.users = null  # map of intertwinkles user_id to user data
intertwinkles.groups = null # list of groups
if INITIAL_DATA.groups?
  intertwinkles.users = INITIAL_DATA.groups.users
  intertwinkles.groups = INITIAL_DATA.groups.groups
  user = _.find intertwinkles.users, (e) -> e.email == INITIAL_DATA.email
  if user? then intertwinkles.user.set(user)

#
# Persona handlers
#

intertwinkles.request_logout = ->
  frame = $("#auth_frame")[0].contentWindow
  frame.postMessage {action: 'intertwinkles_logout'}, INTERTWINKLES_API_URL

onlogin = (assertion) ->
  console.log "onlogin"
  handle = (data) ->
    old_user = intertwinkles.user?.get("email")
    if not data.error? and data.email
      intertwinkles.users = data.groups.users
      intertwinkles.groups = data.groups.groups
      user = _.find intertwinkles.users, (e) -> e.email == data.email
      if user?
        intertwinkles.user.set(user)
      else
        intertwinkles.user.clear()
    
      if _.contains data.messages, "NEW_ACCOUNT"
        #modal = $(new_account_template())
        #$("body").append(modal)
        #modal.modal('show')
        profile_editor = new intertwinkles.EditNewProfile()
        $("body").append(profile_editor.el)
        profile_editor.render()
        profile_editor.on "done", -> profile_editor.remove()
      else if old_user != intertwinkles.user.get("email")
        flash "info", "Welcome, #{intertwinkles.user.get("name")}"

    if data.error?
      intertwinkles.request_logout()
      flash "error", data.error or "Error signing in."

  if intertwinkles.socket?
    socket_ready = setInterval ->
      clearInterval(socket_ready)
      intertwinkles.socket.once "login", handle
      intertwinkles.socket.emit "verify", {callback: "login", assertion: assertion}
    , 50

onlogout = ->
  reload = intertwinkles.is_authenticated()
  intertwinkles.users = null
  intertwinkles.groups = null
  intertwinkles.user.clear()
  socket_ready = setInterval ->
    clearInterval(socket_ready)
    intertwinkles.socket.once "logout", ->
      if reload
        flash "info", "Signed out."
        #window.location.pathname = "/"
    intertwinkles.socket.emit "logout", {callback: "logout"}
  , 50

onmessage = (event) ->
  if event.origin == INTERTWINKLES_API_URL
    switch event.data.action
      when 'onlogin' then onlogin(event.data.assertion)
      when 'onlogout' then onlogout()
window.addEventListener('message', onmessage, false)

intertwinkles.is_authenticated = ->
  return intertwinkles.user.get("email")?

intertwinkles.auth_frame_template = _.template("""<iframe id='auth_frame'
  src='#{INTERTWINKLES_API_URL}/api/auth_frame/'
  style='border: none; overflow: hidden;' width=97 height=29></iframe>""")

