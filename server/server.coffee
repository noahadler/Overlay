Meteor.publish 'searchResults', (search) ->
  SearchResults.find {search:search} #|| do (search) ->

Meteor.publish 'indexedFiles', (search = '') ->
  IndexedFiles.find {file: {$regex: search, $options: 'i' }}, {limit: 50}
  #IndexedFiles.find {file: {$regex: '/Dentist/' }}, {limit: 200}

Meteor.publish 'jobQueue', ->
  JobQueue.find {}, {limit: 100}
      
Meteor.startup ->
  JobQueue.remove {}
  console.log 'Solr server: ' + solrBase
  IndexedFiles.remove {}
  console.log IndexedFiles.find({}).fetch().length + ' currently indexed'
  return
  # Start by scanning files and building the collection
  fs = Npm.require 'graceful-fs'
  crypto = Npm.require 'crypto'

  file_process_queue = async.queue process_file, 5
  file_process_queue.drain = ->
    console.log 'Finished processing all files'

  scan_directory = (d) ->
    #console.log d
    fs.readdir d, (err, files) ->
      if files
        for d2 in files
          c = d + '/' + d2
          try
            stat = fs.lstatSync c
            if stat.isSymbolicLink()
              c = fs.realpathSync c
              stat = fs.lstatSync c
            if stat.isDirectory()
              scan_directory c
            else if stat.isFile()
              file_process_queue.push c
              #index_file d + '/' + d2
          catch e
            console.log 'Error with path ' + c

  async_scan = Npm.require('fibers') ->
    scan_directory 'uploads'
    #scan_directory '/var/www/hivedam-test/sites/default/files/hollywood-media/Photography'
  async_scan.run()

  #async.forever ->
    #scan_directory '../overlay_files'
    #scan_directory '/var/www/hivedam-test/sites/default/files/hollywood-media/Photography/A\&S\ misc_project_photos/UK_misc'
    #scan_directory './files'

