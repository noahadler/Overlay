doc = document.documentElement
doc.ondragover = (e) ->
  @className = 'hover'
  false

doc.ondragend = ->
  @className = ''
  false

doc.ondrop = (e) ->
  e.preventDefault()
  @className = ''
  #console.log e
  
  for item in e.dataTransfer.items
    entry = item.webkitGetAsEntry()
    if entry.isFile
      console.log entry
      files = e.dataTransfer.files
      console.log files

      Meteor.saveFile file, file.name for file in files
    else if entry.isDirectory
      console.log entry
      traverse = (item, path) ->
        console.log 'traversing ' + path
        path = path || ''
        if item.isFile
          console.log 'file '
          console.log item
          item.file (file) ->
            Meteor.saveFile file, file.name
        else if item.isDirectory
          console.log 'directory '
          console.log item
          item.createReader().readEntries (entries) ->
            traverse entry, path + item.name + '/' for entry in entries
      traverse entry, ''



  false
