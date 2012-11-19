new_account_template = _.template("""
  <div class='modal hide fade'>
    <div class='modal-header'>
      <button type='button' class='close' data-dismiss='modal' aria-hidden='true'>&times;</button>
      <h3>Account created</h3>
    </div>
    <div class='modal-body'>
      <p>
      Your new account for the login &ldquo;<%= intertwinkles.user.get('email') %>&rdquo; was created, and you've been given the random icon and name:
      <blockquote>
        <img src='<%= intertwinkles.user.get('icon').small %>' />
        <%= intertwinkles.user.get('name') %>
      </blockquote>
      <p>Edit your settings to choose better ones!</p>
      <a class='btn' href='<%= INTERTWINKLES_APPS.home.url %>/profiles/edit'>Edit settings</a>
    </div>
    <div class='modal-footer'>
      <a href='#' class='btn' data-dismiss='modal'>Close</a>
    </div>
  </div>
""")

edit_new_profile_template = _.template("""
  <div class='modal hide fade'>
    <div class='modal-body'>
      <h1 style='text-align: center;'>Ready in 1, 2, 3:</h1><br />
      <div class='control-group'>
        <b>1: What is your name?</b><br />
        <input type='text' name='name' value='<%= name %>' />
      </div>
      <div class='control-group'>
        <b>2: What is your favorite color?</b><br />
        <input type='text' name='color' value='<%= color %>' class='color' />
        <span class='help-text color-label'></span>
      </div>
      <div class='control-group'>
        <b>3. Which icon do you like the best?</b><br />
        <div class='image-chooser'></div>
      </div>
    </div>
    <div class='modal-footer'>
      <input type='submit' value='OK, Ready, Go!' class='btn btn-primary btn-large' />
    </div>
  </div>
""")

class intertwinkles.EditNewProfile extends Backbone.View
  template: edit_new_profile_template
  events:
    'click input[type=submit]': 'saveProfile'
  render: =>
    name = intertwinkles.user.get("name")
    icon = intertwinkles.user.get("icon")
    if icon?
      color = icon.color
      icon_id = icon.id
    else
      color = ""
      icon_id = ""
    @$el.html(@template({name, color}))
    chooser = new intertwinkles.IconChooser(chosen: icon_id)
    @$(".image-chooser").html(chooser.el)
    chooser.render()
    @$(".modal").modal("show")
    name_color = =>
      @$(".color-label").html(intertwinkles.match_color(@$(".color").val()))
    @$(".color").on "change", name_color
    name_color()

    # Make it bigger.
    #width = Math.max(@$(".modal").width(), $(window).width() * 0.8)
    #height = Math.max(@$(".modal").height(), $(window).height() * 0.8)
    #@$(".modal").css({
    #  width: width + "px"
    #  "margin-left": -(width / 2) + "px"
    #  "top": (height / 2) + "px"
    #})
    #@$(".modal-body").css({
    #  "max-height": (height - 48) + "px"
    #})
    this

  saveProfile: =>
    new_name = @$("input[name=name]").val()
    new_icon = @$("input[name=icon]").val()
    new_color = @$("input[name=color]").val()
    @$(".error-msg").remove()
    @$("input[type=submit]").addClass("loading")
    errors = []
    if not new_name
      errors.push({field: "name", message: "Please choose a name."})
    if not new_icon
      errors.push({field: "icon", message: "Please choose an icon."})
    if not new_color or not /[a-f0-9A-F]{6}/.exec(new_color)?
      errors.push({field: "color", message: "Invalid color..."})
    if errors.length != 0
      console.log errors
      for error in errors
        @$("input[name=#{error.field}]").parent().addClass("error")
        @$("input[name=#{error.field}]").after(
          "<span class='help-inline error-msg'>#{error.message}</span>"
        )
        @$("input[type=submit]").removeClass("loading")
    else
      intertwinkles.socket.once "profile_updated", (data) =>
        @$("input[type=submit]").removeClass("loading")
        if data.error?
          flash "error", "Oh Noes... Server errorrrrrrr........."
          console.log(data)
          @$(".modal").modal("hide")
          @trigger "done"
        else
          intertwinkles.user.set(data.model)
          @$(".modal").modal("hide")
          @trigger "done"

      intertwinkles.socket.emit "edit_profile", {
        callback: "profile_updated"
        model: {
          email: intertwinkles.user.get("email")
          name: new_name
          icon: { id: new_icon, color: new_color }
        }
      }

#
# Icon Chooser widget
#

icon_chooser_template = _.template("""
  <input name='icon' id='id_icon' value='<%= chosen %>' type='hidden' />
  <div class='profile-image-chooser'><img src='/static/img/spinner.gif' alt='Loading...'/></div>
  <div>
    <a class='attribution-link' href='#{INTERTWINKLES_APPS.home.url}/profiles/icon_attribution/'>
      About these icons
    </a>
  </div>
  <div style='clear: both;'></div>
""")

class intertwinkles.IconChooser extends Backbone.View
  template: icon_chooser_template
  chooser_image: "/static/js/intertwinkles_profile_icons.png"
  initialize: (options={}) ->
    @chosen = options.chosen

  render: =>
    @$el.html(@template(chosen: @chosen or ""))
    $.get "/js/intertwinkles_icon_chooser.json", (data) =>
      icon_holder = @$(".profile-image-chooser")
      icon_holder.html("")
      _.each data, (def, i) =>
        cls = "profile-image"
        cls += " chosen" if @chosen == def.pk
        icon = $("<div/>").html(def.name).attr({ "class": cls }).css {
          "background-image": "url('#{@chooser_image}')"
          "background-position": "#{-32 * i}px 0px"
        }
        icon.on "click", =>
          @$(".profile-image.chosen").removeClass("chosen")
          icon.addClass("chosen")
          @$("input[name=icon]").val(def.pk)
          @chosen = def.pk
        icon_holder.append(icon)
      icon_holder.append("<div style='clear: both;'></div>")
    jscolor.bind()
