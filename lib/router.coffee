Router.configure
  layoutTemplate: 'layout'

Router.route '/', ->
  Session.set 'search', ''
  @render 'thumbnails'

Router.route '/videos', ->
  Session.set 'search', ''
  @render 'videos'

Router.route '/queue', ->
  @render 'queue'

Router.route '/:search', ->
  Session.set 'search', @params.search
  @render 'thumbnails'

Router.route '/:view/:search', ->
  Session.set 'search', @params.search
  @render @params.view


Router.route '/thumbnails/:filename',
  path: '/thumbnails/:filename'
  where: 'server'
  action: FileRegistry.serveFile
###
  action: (id) ->
    #@params
    #@request
    
    fs = Npm.require 'fs'
    
    res = @response

    if !fs.existsSync('../overlay_thumbnails/' + id)
      console.log 'Thumbnail ' + id + ' not found (404)'
      return [404, {}, '']

    f = fs.readFileSync '../overlay_thumbnails/'+id

    console.log 'Serving thumbnails/' + id + ' \t(' + (f.length/1024) + ' KB)'
    
    headers =
      'Content-Length': f.length
      'Content-Type': 'image/jpeg'
      'Cache-Control': 'max-age=3600, must-revalidate'

    return [200, headers, f]
###

Router.route '/uploads/:filename',
  path: '/uploads/:filename'
  where: 'server'
  action: FileRegistry.serveFile
    disposition: 'attachment'
###
  action: (f) ->
    fs = Npm.require 'fs'
    res = @response
    if !fs.existsSync('uploads/' + f)
      console.log 'File not found (404): ' + f
      return [404, {}, '']

    file = fs.readFileSync 'uploads/' + f

    console.log 'Serving uploads/' + f + ' \t(' + (file.length/1024) + ' KB)'
    headers =
      'Content-Length': file.length
      'Content-Type': 'image/jpeg'
      'Cache-Control': 'max-age=3600, must-revalidate'

    return [200, headers, file]
###

Router.route '/search/:s',
  path: '/search/:s'
  where: 'server'
  action: (s) ->
    solrQ = solrBase + 'select?qf=content^1.0&qf=sm_tags^1.0&q='+s+'&facet=true&facet.limit=25&fl=ss_filename,ss_md5,id,score&facet.field=sm_tags&facet.field=content&facet.missing=false&facet.mincount=1&json.nl=map&wt=json&rows=100&facet.sort=count&start=0'
    Meteor.http.get solrQ, {}, (err, result) ->
        #if !SearchResults.findOne {search:s}
        SearchResults.remove {search:s}
        SearchResults.insert {search:s, searchResult: result.content}
        console.log 'search returned: ' + result
        #console.log "json: \n" + result.content

