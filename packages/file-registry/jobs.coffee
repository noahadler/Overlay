# returns an object with properties code and stdout, representing
# the numeric exit code and accumulated stdout string of the executed
# (or last executed) process
execProcesses = (cmd, env) ->
  if cmd instanceof Array
    r = null
    for c in cmd
      r = execProcesses c, env
    return r

  spawn = Npm.require('child_process').spawn
  Future = Npm.require 'fibers/future'
  cwd = process.cwd().substr(0, process.cwd().lastIndexOf('.meteor'))

  #console.log "Spawning SHELL: #{process.env.SHELL}"
  console.log "Running #{cmd}"
  p = spawn process.env.SHELL, [], {cwd: cwd, env: env}
  f = new Future()
  parse_text = ''

  p.stdout.on 'data', (data) ->
    Cluster.log data.toString()
    parse_text += data
  p.stderr.on 'data', (data) ->
    console.error data.toString()
    parse_text += "(STDERR) #{data}"
  p.on 'exit', (code, signal) =>
    f.return {code: code, stdout: parse_text}

  p.stdin.write cmd
  p.stdin.end()

  return f.wait()

class @ThumbnailJob extends Job
  handleJob: ->
    fr = FileRegistry.getFileRoot()
    fd = @params.filenameOnDisk
    src = fr+fd
    thumbnail = fd.substr(0,fd.lastIndexOf('.'))+'_thumbnail.jpg'
    tmp = fd.substr(0,fd.lastIndexOf('.'))+'_thumbnail_tmp.jpg'
    dst = fr+thumbnail
    ext = fd.substr(fd.lastIndexOf('.')).toLowerCase()

    cmd =
      if ext in ['.pdf', '.ps']
        "gs -dBATCH -dNOPAUSE -sDEVICE=jpeg -sOutputFile=\"#{tmp}\" \"#{src}\" && convert \"#{tmp}\" -thumbnail 128x128 -background white \"#{dst}\" && rm \"#{tmp}\""
      else
        "convert -flatten \"#{src}[0]\" -thumbnail 128x128 \"#{dst}\""

    execProcesses cmd

    FileRegistry.update {filenameOnDisk: @params.filenameOnDisk}, {$set: {thumbnail: thumbnail} }
    Cluster.log 'ThumbnailJob: thumbnailed ', @params.filenameOnDisk

class @Md5Job extends Job
  handleJob: ->
    fn = @params.filenameOnDisk
    fs = Npm.require 'fs'
    crypto = Npm.require 'crypto'
    Future = Npm.require 'fibers/future'

    f = new Future()
    s = fs.ReadStream (FileRegistry.getFileRoot()+fn)
    md5sum = crypto.createHash 'md5'
    s.on 'data', (d) ->
      md5sum.update d
    s.on 'end', (d) ->
      md5 = md5sum.digest 'hex'
      f.return md5

    md5 = f.wait()
    Cluster.log 'Md5Job: ', fn, '-', md5

    FileRegistry.update {filenameOnDisk: fn}, {$set: {md5: md5} }

class @ExecJob extends Job
  handleJob: ->
    execProcesses @params.cmd, @params.env
    #Workers.log 'Exec: ' + @params.command.command + ' ' + (if @params.command.args.join? then @params.command.args.join(' ') else @params.command.args)

class @VideoTranscodeJob extends Job

  handleJob: ->
    fn = FileRegistry.findOne({filenameOnDisk: @params.filenameOnDisk}).filename
    fr = FileRegistry.getFileRoot()
    src = '"'+fr+@params.filenameOnDisk+'"'
    converted = fn.substr(0, fn.lastIndexOf('.')) + '.' + @params.targetType
    convertedFn = @params.filenameOnDisk.substr(0,@params.filenameOnDisk.lastIndexOf('.'))+'.'+@params.targetType
    dst = '"'+fr+convertedFn+'"'
    cmd = ["ffmpeg -i #{src} -y #{dst}"]
    execProcesses cmd

  afterJob: ->
    fs = Npm.require 'fs'
    #Not sure if there's a better way than just redoing all of our file name stuff. Not much of this is intensive though.
    fn = FileRegistry.findOne({filenameOnDisk: @params.filenameOnDisk}).filename
    fr = FileRegistry.getFileRoot()
    src = '"'+fr+@params.filenameOnDisk+'"'
    converted = fn.substr(0, fn.lastIndexOf('.')) + '.' + @params.targetType
    convertedFn = @params.filenameOnDisk.substr(0,@params.filenameOnDisk.lastIndexOf('.'))+'.'+@params.targetType
    dst = fr+convertedFn
    stats = fs.statSync dst

    FileRegistry.update {filenameOnDisk: @params.filenameOnDisk}, {$set: {webVideo: convertedFn}}
    Cluster.log 'VideoTranscodeJob: converted ', @params.filenameOnDisk, 'to type ', @params.targetType

    ###
    FileRegistry.insert
      filename: converted
      filenameOnDisk: convertedFn
      size: stats['size']
      timestamp: new Date()
      userId: @userId

    #Get an Md5 and Thumbnail for our new file.
    Job.push new Md5Job filenameOnDisk: convertedFn
    Job.push new ThumbnailJob filenameOnDisk: convertedFn

    Cluster.log 'VideoTranscodeJob: converted ', @params.filenameOnDisk, 'to type ', @params.targetType
    ###

# Extract X evenly-spaced frames from a video for rollover thumbnails
class @VideoPreviewFramesJob extends Job
  handleJob: ->
    f = FileRegistry.findOne({filenameOnDisk: @params.filenameOnDisk})
    fn = f.filename
    fr = FileRegistry.getFileRoot()
    fd = @params.filenameOnDisk
    src = '"'+fr+@params.filenameOnDisk+'"'
    videoLengthInSeconds=20 # TODO
    cmd = "ffprobe #{src}"
    ffprobe_stdout = (execProcesses cmd).stdout
    getDurationHMS = (a) ->
      (a.match /Duration: ([0-9]{2}):([0-9]{2}):([0-9]{2}.[0-9]+)/).slice(1,5).map((x) -> parseFloat(x) )
    [h,m,s]= getDurationHMS ffprobe_stdout
    duration = h*60*60+m*60+s;
    console.log 'Duration in seconds: ', duration
    for frame in [0..9]
      thumbnail = fd.substr(0,fd.lastIndexOf('.'))+'_frame_'+frame+'.jpg'
      dst = '"'+fr+thumbnail+'"'
      ext = fd.substr(fd.lastIndexOf('.')).toLowerCase()
      startingSecond = parseFloat(duration*frame/9.1)
      cmd = "ffmpeg -ss #{startingSecond} -i #{src} -vframes 1 -filter:v 'yadif,scale=160:90' #{dst}"
      execProcesses cmd
      FileRegistry.update f._id, 
        $push:
          videoPreviewFrames: thumbnail
