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
  #progress: -> parseInt Session.get 'progress'
  progress: ->
    current = 0
    total = 0
    uploads = UploadProgress.find({}).forEach (up) ->
      if up.uploaded < up.total
        current += up.uploaded
        total += up.total
    if total > 0
      return parseInt ((100*current) / total)
    else
      return 0

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
    FileRegistry.find()
  stillUploading: (f) ->
    u = UploadProgress.findOne {name: f.filename}
    u? && u.uploaded < u.total
  uploadProgressPercent: (f) ->
    u = UploadProgress.findOne {name: f.filename}
    if u?
      parseInt ((100*u.uploaded)/u.total)

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
  'click a.btn[name=toggle-embed-code]': (e, tpl) ->
    tpl.$('.embed-code').toggle()
  'click a.btn[name=delete]': (e, tpl) ->
    console.log @, arguments
    FileRegistry.remove(FileRegistry.findOne({filenameOnDisk: @filenameOnDisk})._id)

Template.videos.helpers
  videos: ->
    FileRegistry.find({videoPreviewFrames: {$exists: 1}})
  stillUploading: (f) ->
    u = UploadProgress.findOne {name: f.filename}
    u? && u.uploaded < u.total
  uploadProgressPercent: (f) ->
    u = UploadProgress.findOne {name: f.filename}
    if u?
      parseInt ((100*u.uploaded)/u.total)
  formatBytes: (byteCount) ->
    if byteCount < 1024
      return byteCount+" bytes"
    if (kbCount = byteCount / 1024) < 1024
      return kbCount.toFixed(0)+"KB"
    if (mbCount = kbCount / 1024) < 1024
      return mbCount.toFixed(1)+"MB"
    if gbCount = mbCount / 1024
      return gbCount.toFixed(2)+"GB"

Template.videos.events
  'click tr': (e, tpl) ->
    Blaze.renderWithData Template.file_dialog, @, $('body').get(0)
    $('#fileModal').modal('show')

Template.videos_videostack.helpers
  videoPreviewFrames: ->
    {i:k, value: v, z: 100-k, left: k*15} for own k, v of @videoPreviewFrames
  z: ->
    if hpf = Template.instance().hoveredPreviewFrame.get()
      100 - 10*Math.abs(hpf - parseInt(@i))
    else
      @z

Template.videos_videostack.onCreated ->
  Template.instance().hoveredPreviewFrame = new ReactiveVar(null);

Template.videos_videostack.events
  'mouseenter .video-stack > img': (e, tpl) ->
    console.log 'hovering!', @, arguments
    tpl.hoveredPreviewFrame.set @i
  'mouseleave .video-stack': (e, tpl) ->
    console.log 'leaving...'
    tpl.hoveredPreviewFrame.set null


Jobs = new Mongo.Collection 'jobs'
Template.queue.onCreated ->
  @subscribe 'jobs'

Template.queue.helpers
  queuedItems: -> Jobs.find {}, {sort: {submitTime: -1}}
  fromNow: (date) ->
    d = Deps.currentComputation

    setTimeout ->
      d.invalidate()
    , 5000

    moment(date).fromNow()
