(exports ? this).process_file = (f, done_callback) ->
  fs = Npm.require 'fs'
  crypto = Npm.require 'crypto'

  console.log 'Processing file ' + f
  s = fs.ReadStream f
  md5sum = crypto.createHash 'md5'
  s.on 'data', (d) ->
    md5sum.update(d)
  s.on 'end', ->
    fiber = Npm.require('fibers') ->
      md5 = md5sum.digest('hex')
      if IndexedFiles.findOne({file: f, md5: md5}) && fs.existsSync('../overlay_thumbnails/'+md5+'.jpg')
        console.log 'Skipping ' + f + '...'
      else
        IndexedFiles.remove {file: f, md5: md5}
        console.log f + ': ' + md5

        spawn = Npm.require('child_process').spawn
        Future = Npm.require 'fibers/future'

        tika = ->
          tikaFuture = new Future()
          tikaComplete = tikaFuture.resolver()

          tika = spawn('java', ['-jar', 'tika-app-1.4.jar', '-j', f])
          tika.stdout.parse_text = ''
          tika.stdout.on 'data', (data) ->
            #console.log @
            @parse_text += data
          tika.on 'close', (code, signal) ->
            #console.log @
            #console.log @stdout.parse_text
            try
              metadata = JSON.parse @stdout.parse_text
              tikaFuture.return metadata
            catch e
              console.log 'Error parsing metadata for ' + f
              tikaFuture.return {}

          metadata = tikaFuture.wait()

          console.log 'Got metadata for ' + md5 + ': ' + metadata['Content-Type']
          console.log 'Waited for tika process to finish'
          console.log metadata
          metadata
        metadata = tika()

        if metadata == {}
          return

        #console.log 'Got metadata for ' + md5 + ': ' + metadata['Content-Type']
        #console.log JSON.parse(@stdout.parse_text)

        thumbnailConversionFuture = new Future()
        thumbnailConverters = 
          createImageThumbnail: (f, callback) ->
            im = Meteor.require 'imagemagick'
            im.convert [f, '-resize', '64x64', '../overlay_thumbnails/'+md5+'.jpg'], ->
              console.log 'generated thumbnail for ' + f
              thumbnailConversionFuture.return {}
              callback()

          createVideoThumbnail: (f, callback) ->
            thumbnailConversionFuture.return {}
            callback()

          createDocumentThumbnail: (f, callback) ->
            thumbnailConversionFuture.return {}
            callback()

        mime = metadata['Content-Type']
        if ['image/jpeg','image/png'].indexOf mime > -1
          thumbnailConverters.createImageThumbnail f, ->
        else if ['application/msword','application/pdf'].indexOf mime > -1
          thumbnailConverters.createDocumentThumbnail f, ->
        else if ['video/mp4','video/mov'].indexOf mime > -1
          thumbnailConverters.createVideoThumbnail f, ->

        console.log 'Created thumbnails for ' + f
        thumbnailConversionFuture.wait()

        #new_fiber = Npm.require('fibers') ->
        IndexedFiles.insert _.extend {file: f, md5: md5, thumbnail: '/thumbnails/'+md5+'.jpg'}, metadata
        console.log 'Inserted '+f+' into collection'
        #new_fiber.run()

        escapeEntities = (s) ->
          String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')

        ucwords = (str) ->
          (str + '').replace /^([a-z\u00E0-\u00FC])|\s+([a-z\u00E0-\u00FC])/g, (t) ->
            t.toUpperCase()

        path_terms = _.filter escapeEntities(f).split('/'), (t) ->
          t.indexOf(stopword) for stopword in ['','var','..']
        path_terms.pop()
        path_terms = _.map path_terms, (t) ->
          t = t.replace /_/g,' '
          '<field name="sm_tags">'+ucwords(t)+'</field>'

        metadata_fields = ''
        _.each metadata, (v,k) ->
          solr_key = k.toLowerCase().replace /\W/g, '_'
          metadata_fields += '<field name="tm_'+solr_key+'">'+escapeEntities(v)+'</field>'
          metadata_fields += '<field name="sm_'+solr_key+'">'+escapeEntities(v)+'</field>'
          

        ###solrDoc = '<add overwrite="true"><doc><field name="ss_filename">'+escapeEntities(f)+'</field><field name="id">'+md5+'</field><field name="ss_md5">'+md5+'</field><field name="content">'+escapeEntities(f)+'</field>'+path_terms+metadata_fields+'</doc></add>'

        Meteor.http.post solrBase + 'update?commit=true', {
          headers:
            'Content-Type': 'text/xml'
          content:
            solrDoc #'<add overwrite="false"><doc><field name="ss_filename">'+f.replace(/\//g,' ')+'</field><field name="id">'+md5+'</field><field name="ss_md5">'+md5+'</field><field name="content">'+f.replace(/\//g,' ')+'</field></doc></add>'
        }, (err, result) ->
          if !err
            console.log 'SOLRized '+md5
          else
            console.log 'Error sending to solr: '
            console.log err
            console.log 'Query was: ' + solrDoc
        ###
          
        #im.readMetadata(f, (err, metadata) ->
        ###
        imagemagick = Npm.require 'imagemagick-native'
        srcData = fs.readFileSync f
        thumbnail = imagemagick.convert
          srcData: srcData,
          width: 64,
          height: 64,
          resizeStyle: 'aspectfill',
          quality: 80,
          format: 'JPEG'
        fs.writeFileSync '../overlay_thumbnails/' + md5 + '.jpg', thumbnail, 'binary'
        ###
      done_callback && done_callback()
    fiber.run()
