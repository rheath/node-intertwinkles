#
# Sharing control widget
#

sharing_control_template = _.template("""
  <% if (intertwinkles.is_authenticated()) { %>
    <div>
      <a href='#' class='show-all-options'>Change sharing options</a>
    </div>
    <div class='hide all-options'>
      <div class='group-options'>
        Belongs to group:
        <div class='group-choice'></div>
      </div>
      <div class='public-options'>
        <hr>
        <div class='public-editing'>
            In addition to group members, share with:<br />
            Public: <select name='public_edit_or_view'>
                      <option value=''>No</option>
                      <option value='edit'>can edit</option>
                      <option value='view'>can view</option>
                    </select>
          </label>
          <span class='public-until'>
            until <select name='public_until'>
                    <option value='-1'>Forever</option>
                    <option value='<%= 1000 * 60 * 60 %>'>One hour</option>
                    <option value='<%= 1000 * 60 * 60 * 24 %>'>One day</option>
                    <option value='<%= 1000 * 60 * 60 * 24 * 7 %>'>One week</option>
                  </select>
          </span>
        <div class='advertise'>
          <label>
            List the link publicly?
            <input type='checkbox' name='advertise' value='on' <%= sharing.advertise ? 'checked=\"checked\"' : '' %> />
          </label>
        </div>
        <hr>
          <div>
            <% var has_more_sharing = sharing.extra_editors != null || sharing.extra_viewers != null; %>
            <div class='extra<%= has_more_sharing ? '' : ' hide' %>'>
              Extra editors (list email addresses):<br />
              <textarea name='extra_editors'><%= (sharing.extra_editors || []).join(', ') %></textarea>
              <br />
              Extra viewers (list email addresses):<br />
              <textarea name='extra_viewers'><%= (sharing.extra_viewers || []).join(', ') %></textarea>
            </div>
            <% if (!has_more_sharing) { %>
              <a href='#' class='more-sharing-options'>Add specific people</a>
            <% } %>
          </div>
        </div>
      </div>
    </div>
        <hr>
    <div class='summary'>
      <h4>Sharing summary:</h4>
      <b><span class='summary-title'></span></b>
      <div class='summary-content'></div>
    </div>
  <% } else { %>
    <span class='help-inline'>
      Anyone with the URL can edit or view.<br />
      Sign in to change this.
    </span>
  <% } %>
""")

class intertwinkles.SharingFormControl extends Backbone.View
  #
  # A control for editing the sharing settings within a form.
  #
  template: sharing_control_template
  initialize: (options={}) ->
    # Create a deep copy to operate on.
    sharing = options.sharing or {}
    @sharing = {
      group_id: sharing.group_id
      public_edit_until: if sharing.public_edit_until then new Date(sharing.public_edit_until) else undefined
      public_view_until: if sharing.public_view_until then new Date(sharing.public_view_until) else undefined
      extra_editors: if sharing.extra_editors then (a for a in sharing.extra_editors) else undefined
      extra_viewers: if sharing.extra_viewers then (a for a in sharing.extra_viewers) else undefined
      advertise: sharing.advertise
    }
    @sharing = intertwinkles.normalize_sharing(@sharing)
    intertwinkles.user.on "change", @render

  render: =>
    @$el.addClass("sharing-controls")
    @$el.html(@template({sharing: @sharing}))
    @render_summary()
    return unless intertwinkles.is_authenticated()

    group_choice = new intertwinkles.GroupChoice()
    @$(".group-choice").html(group_choice.el)
    group_choice.render()
    @$("#id_group").val(@sharing.group_id) if @sharing.group_id?

    if @sharing.public_edit_until?
      @$("select[name=public_edit_or_view]").val("edit")
    else if @sharing.public_view_until?
      @$("select[name=public_edit_or_view]").val("view")
    public_until = @sharing.public_edit_until or @sharing.public_view_until
    if public_until
      diff = public_until - new Date().getTime()
      if diff > 1000 * 60 * 60 * 24 * 365
        @$("select[name=public_until]").val("-1")
      else if diff > 1000 * 60 * 60 * 24
        @$("select[name=public_until]").val(1000 * 60 * 60 * 24 * 7) # one week
      else if diff > 1000 * 60 * 60
        @$("select[name=public_until]").val(1000 * 60 * 60 * 24) # one day
      else
        @$("select[name=public_until]").val(1000 * 60 * 60) # one hour

    @$(".show-all-options").on "click", (event) =>
      event.preventDefault()
      $(event.currentTarget).hide()
      @$(".all-options").show()

    @$(".more-sharing-options").on "click", (event) =>
      event.preventDefault()
      extra = @$(".extra")
      if extra.is(":visible")
        extra.hide()
        $("textarea", extra).val("")
        $(event.currentTarget).html("Add specific people")
        @render_summary()
      else
        $(event.currentTarget).html("Remove these")
        extra.show()

    setSharingVisibility = => @$(".public-options").toggle(@sharing.group_id?)
    setSharingVisibility()

    @$("#id_group").on "change", =>
      @sharing.group_id = @$("#id_group").val()
      if @sharing.group_id
        @sharing.group_id = parseInt(@sharing.group_id)
      else
        delete @sharing.group_id
        delete @sharing.public_view_until
        delete @sharing.public_edit_until
        delete @sharing.extra_viewers
        delete @sharing.extra_editors
      setSharingVisibility()
      @render_summary()

    setUntil = =>
      val = parseInt(@$("select[name=public_until]").val())
      if val == -1
        # 1000 years in the future should be good enough for 'forever'.
        val = 1000 * 60 * 60 * 24 * 365 * 1000
      future = new Date(new Date().getTime() + val)
      switch @$("select[name=public_edit_or_view]").val()
        when 'edit'
          @sharing.public_edit_until = future
          @sharing.public_view_until = null
          @$(".advertise").show()
        when 'view'
          @sharing.public_edit_until = null
          @sharing.public_view_until = future
          @$(".advertise").show()
        when ''
          @sharing.public_edit_until = null
          @sharing.public_view_until = null
          @sharing.advertise = false
          @$("input[name=advertise]").val(false)
          @$(".advertise").hide()
      @render_summary()

    @$("select[name=public_until]").on "change", setUntil
    @$("select[name=public_edit_or_view]").on "change", (event) =>
      val = $(event.currentTarget).val()
      @$(".public-until, .advertise").toggle(val != '')
      if val == ''
        @$("input[name=advertise]").attr("checked", false)

      setUntil()
    @$(".public-until, .advertise").toggle(@sharing.public_edit_until? or @sharing.public_view_until?)

    @$("input[name=advertise]").on "change", (event) =>
      @sharing.advertise = @$("input[name=advertise]").is(":checked")
      @render_summary()

    @$("textarea[name=extra_editors], textarea[name=extra_viewers]").on "change", =>
      @sharing.extra_editors = _.reject(
        @$("textarea[name=extra_editors]").val().split(/[,\s]+/), (e) -> not e
      )
      @sharing.extra_viewers = _.reject(
        @$("textarea[name=extra_viewers]").val().split(/[,\s]+/), (e) -> not e
      )
      if @sharing.extra_editors.length == 0
        @sharing.extra_editors = null
      if @sharing.extra_viewers.length == 0
        @sharing.extra_viweers = null
      @render_summary()

  render_summary: =>
    # Render a natural-language summary of the model's current sharing preferences.
    summary = intertwinkles.sharing_summary(@sharing)
    @$(".summary .summary-content").html(summary.content)
    @$(".summary .summary-title").html(summary.title)

intertwinkles.sharing_summary = (sharing) ->
  perms = []
  short_title = ""
  if not sharing?
    short_title = "Public with secret URL"
    perms.push("Anyone with the link can edit.")
  else if not sharing.group_id?
    if sharing.advertise
      short_title = "Public wiki"
      icon_class = "icon-globe"
      perms.push("Anyone can find and edit.")
    else
      short_title = "Public with secret URL"
      icon_class = "icon-share"
      perms.push("Anyone with the link can edit.")
  else
    now = new Date()
    is_public = false
    group = _.find intertwinkles.groups, (g) -> "" + g.id == "" + sharing.group_id
    if sharing.public_edit_until?
      if sharing.public_edit_until.getTime() - now.getTime() > 1000 * 60 * 60 * 24 * 365 * 100
        future = "forever"
      else
        future = "until #{sharing.public_edit_until.toString("ddd MMM d, h:mmtt")}"
        short_title = "Public " + future
      perms.push("Anyone with the URL can edit this #{future}.")
      is_public = true
      if sharing.advertise
        short_title = "Public wiki"
        icon_class = "icon-globe"
      else
        short_title = "Public with secret URL"
        icon_class = "icon-share"
    else if sharing.public_view_until?
      if sharing.public_view_until.getTime() - now.getTime() > 1000 * 60 * 60 * 24 * 365 * 100
        future = "forever"
      else
        future = "until #{sharing.public_view_until.toString("ddd MMM d, h:mmtt")}"
      perms.push("Anyone with the URL can view this #{future}.")
      is_public = true
      if sharing.advertise
        short_title = "Public on the web"
        icon_class = "icon-globe"
      else
        short_title = "Public with secret URL"
        icon_class = "icon-share"
    else
      short_title = "Private to #{group.name}"
      icon_class = "icon-lock"

    if group?
      group_list = _.map(group.members, (m) ->
        intertwinkles.users[m.user_id].email
      )
      perms.push("Members of <acronym title='#{group_list.join(", ")}'>#{group.name}</acronym> can view and edit#{if is_public then " beyond that date" else ""}.")
      if sharing.extra_editors?.length > 0
        other_editors = _.difference(sharing.extra_editors, group_list)
      else
        other_editors = []
      if sharing.extra_viewers?.length > 0
        other_viewers = _.difference(sharing.extra_viewers, group_list, other_editors)
      else
        other_viewers = []
      if other_editors.length > 0
        perms.push("<br />The following people can also edit: <i>#{other_editors.join(", ")}</i>.")
      if other_viewers.length > 0
        perms.push("<br />The following people can also view: <i>#{other_viewers.join(", ")}</i>.")
    if not is_public
      perms.push("All others, and people who aren't signed in, cannot view or edit.")
  perms.push("<br />The link will #{if sharing.advertise then "" else "not"} be listed publicly.")
  return {
    title: short_title
    content: perms.join(" ")
    icon_class: icon_class
  }

intertwinkles.normalize_sharing = (sharing) ->
  # Normalize sharing
  return {} if not sharing?
  now = new Date()
  if sharing.public_edit_until?
    # Remove stale public edit until
    sharing.public_edit_until = new Date(sharing.public_edit_until)
    if sharing.public_edit_until < now
      delete sharing.public_edit_until
  if sharing.public_view_until?
    # Remove stale public view until
    sharing.public_view_until = new Date(sharing.public_view_until)
    if sharing.public_view_until < now
      delete sharing.public_view_until
  if sharing.extra_editors?.length == 0
    # Remove empty extra editors.
    delete sharing.extra_editors
  if sharing.extra_viewers?.length == 0
    # Remove empty extra viewers.
    delete sharing.extra_viewers
  if sharing.group_id? and not (sharing.public_edit_until? or sharing.public_view_until?)
    # Can't advertise unless it's public.
    sharing.advertise = false
  return sharing


sharing_settings_button_template = _.template("""
  <div class='sharing-settings-button'>
    <a class='btn btn-success open-sharing'><i class='<%= icon_class %>'></i> Sharing</a>
  </div>
""")
sharing_settings_modal_template = _.template("""
  <div class='modal hide fade'>
    <div class='modal-header'>
      <button type='button' class='close' data-dismiss='modal' aria-hidden='true'>&times;</button>
      <h3>Sharing</h3>
    </div>
    <form class='form-horizontal'>
      <div class='modal-body'>
        <div class='sharing-controls'></div>
      </div>
      <div class='modal-footer'>
        <div class='url-to-share pull-left'>
          Share this: <input readonly type='text' class='url' value='<%= window.location.href %>' />
        </div>
        <input type='submit' class='btn btn-primary' value='Save' />
      </div>
    </form>
  </div>
""")

class intertwinkles.SharingSettingsButton extends Backbone.View
  # A control that briefly summarizes the sharing preferences for a document,
  # and invokes a form to edit them.
  template: sharing_settings_button_template
  modalTemplate: sharing_settings_modal_template
  events:
    'click .open-sharing': 'renderModal'

  initialize: (options={}) ->
    @model = options.model
    @model.on "change:sharing", @render
    intertwinkles.user.on "change", @render

  render: =>
    summary = intertwinkles.sharing_summary(intertwinkles.normalize_sharing(
      @model.get("sharing")
    ))
    @$el.html(@template(icon_class: summary.icon_class))
    popover_content = summary.content
    if intertwinkles.is_authenticated()
      popover_content += "<br /><i>Click to change settings.</i>"
    else
      @$(".open-sharing").addClass("disabled")
      popover_content += "<br /><i>Sign in to change sharing settings.</i>"
        
    @$(".open-sharing").popover({
        placement: "bottom"
        html: true
        title: summary.title
        content: popover_content
        trigger: "hover"
      })

  renderModal: (event) =>
    event.preventDefault()
    unless intertwinkles.is_authenticated()
      return
    @modal = $(@modalTemplate())
    $("body").append(@modal)
    @modal.modal('show').on('hidden', => @modal.remove())
    @sharing = new intertwinkles.SharingFormControl(sharing: @model.get("sharing"))
    $(".sharing-controls", @modal).html(@sharing.el)
    @sharing.render()
    $("form", @modal).on "submit", @save

  close: =>
    @modal.modal('hide')

  save: (event) =>
    event.preventDefault()
    $("input[type=submit]", @modal).addClass("loading")
    @trigger "save", @sharing.sharing
    return false
