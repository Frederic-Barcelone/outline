# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.OUT = {} unless window.OUT?

OUT.contentItems =

  createSortables: ->
    $('.content-items.sortable').sortable
      axis: 'y'
      handle: '.move-handle'
      cursor: 'crosshair'
      items: '> .content-item'
      scroll: true
      update: OUT.handlers.listSorted

  clearDecoratedContentItemOptions: (event) ->
    $("div.content-item-options").removeClass "open"

  decorateContentItemOptions: (event) ->
    console.log "decorateContentItemOptions"
    $("div.content-item-options").each () ->
      options = $(this)
      if options.find("li.dropdown.open").length > 0
        options.addClass "open"
      else
        options.removeClass "open"

  #
  # Wrapper method that is called when a content_item form should be deactivated
  #
  deactivateForm: (form_selector, content_selector) ->
    $(form_selector).find("input[type=text], textarea").val("").blur()
    OUT.triggerHandler OUT.HANDLER_DEACTIVATE_FORM, form_selector, [form_selector, content_selector]

  open: (select) ->
    details = $(select).find('.content-item-details')
    details.animate
      'display': 'block'
      'height': 16
      'opacity': 1
      , "slow"
    ele = $(select).animate
      'margin-top': "20"
      'margin-bottom': "20"
      , "slow"

  setAddFormArrowTo: (anchor) ->
    pane = $(anchor).attr("href")
    if pane?
      arrow_width = 16
      arrow_left_global = $(anchor).parent().offset().left + $(anchor).parent().width() / 2
      arrow_left_local = arrow_left_global - $(pane).offset().left
      arrow_left = arrow_left_local - arrow_width / 2
      $(pane).css("background-position", arrow_left+"px 0")

$ ->
  OUT.contentItems.setAddFormArrowTo $("#add-content-item-tabs li.active a")

  $("#add-content-item-tabs li.active").removeClass("active")

$(window).load ->
  OUT.contentItems.createSortables()

  OUT.registerCreatedHandler "*", ->
    $("ul.content-items li.blank-slate").remove()

  $('body').bind 'click', OUT.contentItems.clearDecoratedContentItemOptions
  $('a[data-toggle="dropdown"]').bind 'click', OUT.contentItems.decorateContentItemOptions

  $('a[data-toggle="content-item-form"]').live "click", (event) ->
    selector = $(event.target).data('target')
    $(selector).toggle();
    OUT.selectFirstInput(selector)
    $(this).hide()
    false

  $('#add-content-item-tabs').bind 'shown', (event) ->
    OUT.contentItems.setAddFormArrowTo $(event.target)
    pane = $(event.target).attr("href")
    if pane?
      OUT.selectFirstInput($(pane))

  $('a[data-toggle="move-to-page"]').live "click", (event) ->
    $("body").click()
    url = $(this).attr("href")
    quickjump = new OUT.QuickJump.Modal (selected) ->
        $.ajax
          type: 'POST'
          url: url
          data: {"page_id": selected.id}
          success: () ->
            quickjump.hide()
      , "/quick_jump_targets/pages.json"
    false
