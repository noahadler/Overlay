# TODO: with Iron-Router, these subscriptions can be moved to the waitOn
Deps.autorun ->
  console.log 'Search updated: ' + Session.get('search')
  Meteor.subscribe 'searchResults', Session.get('search')

Deps.autorun ->
  Meteor.subscribe 'indexedFiles', Session.get('search')

Deps.autorun ->
  Meteor.subscribe 'jobQueue'

Session.set 'current_view', 'thumbnails'

Template.searchbox.events
  'keypress input': (e) ->
    if e.keyCode == 13
      s = $('input[name="searchbox"]').val()
      console.log s
      Meteor.Router.to('/' + encodeURIComponent(s))
  'click input[value="Search"]': (e) ->
    s = $('input[type="text"]').val()
    console.log s
    Meteor.Router.to('/' + encodeURIComponent(s))

Handlebars.registerHelper 'arrayify', (obj) ->
  {name:key, value: val} for own key, val of obj

Template.current_view.content = ->
  a = Template[Session.get 'current_view']()

Template.progress.helpers
  progress: -> parseInt Session.get 'progress'

Template.thumbnails.numFound = ->
  s = SearchResults.findOne {search: Session.get('search') }
  j = if s then JSON.parse(s.searchResult) else { response: { numFound: 0 }}
  console.log 'search result count: ' + j
  j.response.numFound


Template.thumbnails.cdnUrl = (url) ->
  url
  #'http://mrt' + url.charCodeAt(0)%10 + ':3000' + url

Template.thumbnails.splitPath = (path) ->
  path.replace(/\//g,"\n")

Template.thumbnails.basename = (path) ->
  path.split('/').pop()

Template.thumbnails.doc = ->
  return IndexedFiles.find({}, {limit: 50})

Template.thumbnails.events
  'click .thumbnail': (e) ->
    $(e.currentTarget).find('.modal').modal()

Template.queue.helpers
  queuedItems: -> JobQueue.find {}, {sort: {submitTime: -1}}
  fromNow: (date) ->
    d = Deps.currentComputation

    setTimeout ->
      d.invalidate()
    , 5000

    moment(date).fromNow()


