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
      #Session.set 'search', s
      #Meteor.call 'search', s
  'click input[value="Search"]': (e) ->
    s = $('input[type="text"]').val()
    console.log s
    Meteor.Router.to('/' + encodeURIComponent(s))
    #Session.set 'search', s
    #Meteor.call 'search', s

Handlebars.registerHelper 'arrayify', (obj) ->
  {name:key, value: val} for own key, val of obj

Template.current_view.content = ->
  a = Template[Session.get 'current_view']()

Template.progress.helpers
  progress: -> parseInt Session.get 'progress'

Template.facets.facet = ->
  console.log 'facet template...'
  s = SearchResults.findOne {search: Session.get('search') }
  j = if s then JSON.parse(s.searchResult) else { facet_counts: { facet_fields: {}}}
  console.log j
  j.facet_counts.facet_fields

Template.facet.log = (l) ->
  console.log l

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
  #console.log i
  #return i
  console.log 'thumbnail template...'
  s = SearchResults.findOne {search: Session.get('search') }
  j = if s then JSON.parse(s.searchResult) else { response: { docs: [] }}
  console.log j
  j.response.docs
  ###
  _.map j.response.docs, (d) ->
    { item_id: d.item_id, url: '/thumbnail/test' } #'https://media-dev.as.uky.edu/hivedam-test/sites/default/files/styles/square_thumbnail/public/' + d.tm_url.slice(4).join('/') }
    #j.response.docs
  ###

Template.thumbnails.events
  'click .thumbnail': (e) ->
    $(e.currentTarget).find('.modal').modal()

Template.queue.helpers
  queuedItems: -> JobQueue.find()
  fromNow: (date) ->
    d = Deps.currentComputation

    setTimeout ->
      d.invalidate()
    , 5000

    moment(date).fromNow()


