/**
 * @blob (https://developer.mozilla.org/en-US/docs/DOM/Blob)
 * @name the file's name
 * @type the file's type: binary, text (https://developer.mozilla.org/en-US/docs/DOM/FileReader#Methods) 
 *
 * TODO Support other encodings: https://developer.mozilla.org/en-US/docs/DOM/FileReader#Methods
 * ArrayBuffer / DataURL (base64)
 */
Meteor.saveFile = function(blob, name, path, type, callback) {
  var fileReader = new FileReader(),
    method, encoding = 'binary', type = type || 'binary';
  switch (type) {
    case 'text':
      // TODO Is this needed? If we're uploading content from file, yes, but if it's from an input/textarea I think not...
      method = 'readAsText';
      encoding = 'utf8';
      break;
    case 'binary': 
      method = 'readAsBinaryString';
      encoding = 'binary';
      break;
    default:
      method = 'readAsBinaryString';
      encoding = 'binary';
      break;
  }

  transferred = 0

  fileReader.onload = function(file) {
    //Meteor.call('saveFile', file.srcElement.result, name, path, encoding, callback);

  }

  outputProgress = _.throttle(function(e) {
    console.log('Upload progress: ' + parseInt(e.loaded * 100.0/ e.total));
    // call meteor method for partial upload?
    //console.log
    var pending = e.loaded - transferred;
    console.log('pending to send: ' + pending + ' bytes');
    console.log('result length: ' + e.srcElement.result.length + ' bytes');
    //wait = Meteor.call('saveFilePart', e.srcElement.result.substr(transferred, pending), name, path, encoding);
    transferred += pending;    
  }, 2000);

  fileReader.onprogress = function(e) {
    //outputProgress(e);
    Session.set('progress', parseInt(e.loaded * 100.0/ e.total));
  }

  fileReader[method](blob);
}

