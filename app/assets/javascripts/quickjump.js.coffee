# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.OUT = {} unless window.OUT?

window.OUT.QuickJump = {}

class OUT.QuickJump.Dictionary
  constructor: (@key_length) ->
    @store = {}
  
  getKey: (query) ->
    query[0...@key_length]

  getResultsFor: (query) ->
    @store[this.getKey(query)]

  setResultsFor: (query, results) ->
    @store[this.getKey(query)] = results

class OUT.QuickJump.Controls
  KEY_UP: 38
  KEY_DOWN: 40
  KEY_ENTER: 13
  KEY_ESC: 27

  constructor: (@parent, @selector, @result_callback) ->
    @active_result = null
    self = this
    $(@selector).find("input[type=text]").bind "keydown", (event) ->
      val = self.keydown(event)
      if val == false
        event.preventDefault()
        event.stopPropagation()
      val
    .bind "keyup", (event) ->
      val = self.keyup(event)
      if val == false
        event.preventDefault()
        event.stopPropagation()
      val

  keydown: (event) ->
    if event.keyCode == @KEY_ENTER
      @parent.activateResult()
      false
    else if event.keyCode == @KEY_UP
      @parent.moveSelection(-1)
      false
    else if event.keyCode == @KEY_DOWN
      @parent.moveSelection(+1)
      false
    else if event.keyCode == @KEY_ESC
      @parent.deactivate()
      false

  keyup: (event) ->
    query = event.target.value
    if query != @old_query
      if query == ""
        @parent.setDefaultResults()
      else if query.length >= @parent.DICTIONARY_KEY_LENGTH
        @parent.setOrRequestResults(query)
    @old_query = query


class OUT.QuickJump.Renderer
  constructor: (@parent, @selector) ->

  highlight: (str, phrases) ->
    str.toString().replace(new RegExp('('+phrases.join('|')+')', 'gi'), '<strong>$1</strong>')

  getResultTemplate: ->
    '<a class="result" data-result-index="%{index}" href="%{url}"><div class=title><i class="icon-%{type}"></i> <span>%{title}</span></div></a>'

  renderResultsToString: (query, results = @parent.results[0...@MAX_RESULTS]) ->
    out = ""
    index = 0
    phrases = query.replace(/^\s+|\s+$/g, '').split(' ')
    template = this.getResultTemplate()

    for result in results
      t = this.highlight(result.title, phrases)
      out += template.toString().replace("%{title}", t).replace(/%\{type\}/g, result.type).replace("%{url}", result.url).replace("%{index}", index).replace("%{query}", query)
      index += 1
    out

  renderResults: (query) ->
    # out = this.renderResultsToString(query)
    # $(@selector+" .results").html(out)



class OUT.QuickJump.RendererForModal extends OUT.QuickJump.Renderer
  constructor: (@parent, selector) ->
    @selector = this.cloneModal(selector)
    self = this
    $(@selector).bind "hidden", ->
      $(self.selector).remove()

    $(@selector).bind "shown", ->
      $(self.selector+" input").select()

    $(@selector).modal().modal("show")

  cloneModal: (selector) ->
    new_modal_id = "quickjump"+new Date().getTime()
    new_modal = $(selector).clone()
    new_modal.attr("id", new_modal_id)
    $("body").append(new_modal)
    "##{new_modal_id}"

  renderResults: (query) ->
    out = this.renderResultsToString(query)
    $(@selector).find(".results").html(out)
    self = this
    $(@selector).find(".results a.result").bind "click", (event) ->
      self.parent.activateResult(this)
      event.preventDefault()
      false


class OUT.QuickJump.RendererForDropdown extends OUT.QuickJump.Renderer

  getResultTemplate: ->
    '<li class="result" data-result-index="%{index}"><a href="%{url}"><div class=title><i class="icon-%{type}"></i> <span>%{title}</span></div></a></li>'

  extendResults: (html) ->
    out

  renderResults: (query) ->
    out = this.renderResultsToString(query)
    if out != ""
      out += '<li class="divider after-results"></li>'
    if query == ""
      out += ('<li class="result"><a href="/%{type}s" class="result">'+@parent.index_link+'</a></li>').replace(/%\{type\}/g, @parent.type).replace(/%\{query\}/g, query)
    else
      out += ('<li class="result"><a href="/%{type}s/new?%{type}[title]=%{query}" onclick="OUT.%{type}s.showModal(\'%{query}\', true); return false;"><i class="icon-plus"></i> '+@parent.new_template+'</a></li>').replace(/%\{type\}/g, @parent.type).replace(/%\{query\}/g, query)

    last_li = $(@selector).find("li.insert-results-after")
    last_li.nextAll().remove()
    $(out).insertAfter(last_li)

    self = this
    $(@selector).find(".results a.result").bind "click", (event) ->
      self.parent.activateResult(this)
      event.preventDefault()
      false


class OUT.QuickJump.Base
  MAX_RESULTS: 10
  DELAY_BEFORE_SERVER_CALL: 300
  FETCHING_RESULTS: "fetching"
  DICTIONARY_KEY_LENGTH: 1

  constructor: (@result_callback, @data_url = "/quick_jump_targets.json", selector = "#quick-jump-template") ->
    @dictionary = new OUT.QuickJump.Dictionary(@DICTIONARY_KEY_LENGTH)
    @renderer = new OUT.QuickJump.Renderer(this, selector)
    @selector = @renderer.selector
    @controls = new OUT.QuickJump.Controls(this, @selector, @result_callback)
    this.setDefaultResults()

  activateResult: (anchor) ->
    anchor or= this.getActiveResult()
    if anchor?
      index = $(anchor).data("result-index")
      console.log( anchor, index )
      if index?
        result = @results[index]
        @result_callback.apply(null, [result])
      else
        # follow link
        $(anchor).find("a").click()
        #window.location.href = $(anchor).find("a").attr("href")

  getActiveResult: ->
    if @active_result?
      all = $(@selector).find(".result")
      anchor = $(all[@active_result])

  getMatchingResults: (query, results) ->
    this.matchResults(query, results)

  deactivate: ->

  getMaxResult: ->
    Math.min(@results.length, @MAX_RESULTS)

  hide: ->
    this.deactivate()

  markActiveResult: ->
    if @active_result?
      $(@selector).find(".result").removeClass "active"
      this.getActiveResult().addClass "active"

  moveSelection: (modifier) ->
    max_result = this.getMaxResult()
    @active_result += modifier
    @active_result = max_result-1 if @active_result < 0
    @active_result = 0 if @active_result > max_result-1
    this.markActiveResult()

  requestResults: (query, data) ->
    @dictionary.setResultsFor(query, @FETCHING_RESULTS)
    self = this
    $.ajax
      url: @data_url
      data: data
      type: 'get'
      dataType: 'script'
      complete: (request) ->
        self.requestComplete(query, request)

  requestComplete: (query, request) ->
    results = eval(request.responseText)
    this.setResults(query, results)

  setOrRequestResults: (query) ->
    stored_results = @dictionary.getResultsFor(query)
    if stored_results?
      if stored_results != @FETCHING_RESULTS
        this.setResults query, stored_results
    else
      data = {}
      data[$(event.target).attr("name")] = @dictionary.getKey(query)
      self = this
      OUT.setLazyTimer "quickjump_request", @DELAY_BEFORE_SERVER_CALL, ->
        self.requestResults(query, data)

  getDefaultResults: ->
    []

  setDefaultResults: ->
    @results = this.getDefaultResults()
    @renderer.renderResults('')
    @active_result = 0
    this.markActiveResult()

  setResults: (query, results) ->
    OUT.clearLazyTimer "quickjump_request"
    @dictionary.setResultsFor(query, results)
    @results = this.getMatchingResults(query, results)
    @renderer.renderResults(query)
    @active_result = 0
    this.markActiveResult()

  matchResults: (query, results) ->
    results.filter (result) ->
      name = result.title.toLowerCase()
      expr = '.*' + query.toLowerCase().replace(/\s/g, '.+') + '.*'
      name.match(new RegExp(expr))




class OUT.QuickJump.Modal extends OUT.QuickJump.Base
  constructor: (@result_callback, @data_url = "/quick_jump_targets.json") ->
    @dictionary = new OUT.QuickJump.Dictionary(@DICTIONARY_KEY_LENGTH)
    @renderer = new OUT.QuickJump.RendererForModal(this, "#quick-jump-template")
    @selector = @renderer.selector
    @controls = new OUT.QuickJump.Controls(this, @selector, @result_callback)
    this.setDefaultResults()

  deactivate: ->
    $(@selector).modal("hide")

  getDefaultResults: ->
    OUT.quick_jump_modal_defaults || []


class OUT.QuickJump.Dropdown extends OUT.QuickJump.Base
  MAX_RESULTS: 20
  constructor: (@dropdown) ->
    @data_url = $(@dropdown).data("target-url")
    @type = $(@dropdown).data("target-type")
    @index_link = $(@dropdown).data("index-link")
    @search_link = $(@dropdown).data("search-link")
    @new_template = $(@dropdown).data("new-template")
    @result_callback = (selected) ->
      window.location.href = selected.url
    @dictionary = new OUT.QuickJump.Dictionary(@DICTIONARY_KEY_LENGTH)
    @renderer = new OUT.QuickJump.RendererForDropdown(this, @dropdown)
    @selector = @renderer.selector
    @controls = new OUT.QuickJump.Controls(this, @selector, @result_callback)
    this.setDefaultResults()

    $(@selector).find("input").bind "click", (e) ->
      e.stopImmediatePropagation()

  deactivate: ->
    $(@selector).find("input").val("")
    $(@selector).parents("li.dropdown").removeClass("open")

  getDefaultResults: ->
    OUT["quick_jump_#{@type}s_defaults"] || []

  getMatchingResults: (query, results) ->
    results = this.matchResults(query, results)
    results.unshift
      type: 'search'
      url: "/#{@type}s?query=%{query}".replace(/%\{query\}/g, query)
      title: @search_link
    results

  getMaxResult: ->
    Math.min(@results.length, @MAX_RESULTS) + 1


OUT.lazyTimerIds = {}
OUT.setLazyTimer = (name, delay, func) ->
  OUT.clearLazyTimer(name)
  OUT.lazyTimerIds[name] = window.setTimeout func, delay

OUT.clearLazyTimer = (name) ->
  if OUT.lazyTimerIds[name]
    window.clearTimeout(OUT.lazyTimerIds[name])

$(window).load ->
  OUT.registerKeyboardShortcut "t", ->
    result_callback = (selected) ->
      window.location.href = selected.url
    new OUT.QuickJump.Modal result_callback

  $('ul.quickjump-dropdown').each (index, item, arr) ->
    new OUT.QuickJump.Dropdown(item)