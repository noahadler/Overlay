# TODO: with Iron-Router, these subscriptions can be moved to the waitOn
Deps.autorun ->
  console.log 'Search updated: ' + Session.get('search')
  Meteor.subscribe 'searchResults', Session.get('search')

Deps.autorun ->
  Meteor.subscribe 'indexedFiles', Session.get('search')

Deps.autorun ->
  Meteor.subscribe 'jobQueue'

Template.searchbox.events
  'keypress input': (e) ->
    if e.keyCode == 13
      s = $('input[name="searchbox"]').val()
      console.log s
      Router.go('/' + encodeURIComponent(s))
  'click input[value="Search"]': (e) ->
    s = $('input[type="text"]').val()
    console.log s
    Router.go('/' + encodeURIComponent(s))

Handlebars.registerHelper 'arrayify', (obj) ->
  {name:key, value: val} for own key, val of obj

Template.progress.helpers
  progress: -> parseInt Session.get 'progress'

Template.thumbnails.helpers
  numFound: ->
    s = SearchResults.findOne {search: Session.get('search') }
    j = if s then JSON.parse(s.searchResult) else { response: { numFound: 0 }}
    console.log 'search result count: ', j
    j.response.numFound
  cdnUrl: (url) ->
    url
    #'http://mrt' + url.charCodeAt(0)%10 + ':3000' + url
  splitPath: (path) ->
    path.replace(/\//g,"\n")
  basename: (path) ->
    path.split('/').pop()
  doc: ->
    FileRegistry.find({}, {limit: 50})

Template.thumbnails.events
  'click .thumbnail': (e, tpl) ->
    Blaze.renderWithData Template.file_dialog, @, $('body').get(0)
    $('#fileModal').modal('show')

Template.file_dialog.helpers
  endsWith: (s, ending1) ->
    endings = Array.from(arguments).slice(1)
    l = s.toLowerCase()
    _.find endings, (ending) ->
      l.toLowerCase().endsWith ending.toLowerCase()

Template.file_dialog.events
  'hidden.bs.modal': (e, tpl) ->
    Blaze.remove tpl.view

Template.queue.helpers
  queuedItems: -> JobQueue.find {}, {sort: {submitTime: -1}}
  fromNow: (date) ->
    d = Deps.currentComputation

    setTimeout ->
      d.invalidate()
    , 5000

    moment(date).fromNow()


