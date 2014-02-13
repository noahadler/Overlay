class Processor
  constructor: (@sourcefile) ->
    console.log 'File processing ' + @sourcefile
    processor = this
    processorType = @constructor.name
    f = Npm.require('fibers') ->
      job = JobQueue.insert
        file: processor.sourcefile
        processor: processorType
        submitTime: new Date()
        status: 'running'

      processor.process()

      JobQueue.update {_id: job},
        $set:
          status: 'done'
    f.run()

  process: ->
    console.log 'Process the file here, a long running process'



class Md5FileProcessor extends Processor
  process: ->
    fs = Npm.require 'fs'
    crypto = Npm.require 'crypto'

    console.log 'computing md5'

    s = fs.ReadStream @sourcefile
    md5sum = crypto.createHash 'md5'
    Future = Npm.require 'fibers/future'

    future = new Future()

    s.on 'data', (d) ->
      md5sum.update(d)
    s.on 'end', ->
      md5 = md5sum.digest('hex')
      future.return md5
    md5 = future.wait()
    console.log 'md5 of ' + @sourcefile + ' is ' + md5
    return md5

class Tika extends Processor
  process: ->
    spawn = Npm.require('child_process').spawn
    Future = Npm.require 'fibers/future'

    f = @sourcefile

    tikaFuture = new Future()
    tikaComplete = tikaFuture.resolver()

    tika = spawn('java', ['-jar', 'tika-app-1.4.jar', '-j', f])
    tika.stdout.parse_text = ''
    tika.stdout.on 'data', (data) ->
      @parse_text += data
    tika.on 'close', (code, signal) ->
      try
        metadata = JSON.parse @stdout.parse_text
        tikaFuture.return metadata
      catch e
        console.log 'Error parsing metadata for ' + f
        console.log e
        tikaFuture.return {}

    metadata = tikaFuture.wait()

    console.log 'Got metadata for ' + f + ': ' + metadata['Content-Type']
    console.log 'Waited for tika process to finish'
    console.log metadata
    metadata



(exports ? @).Processors =
  Md5: Md5FileProcessor
  Tika: Tika
