/**
 * TODO support other encodings:
 * http://stackoverflow.com/questions/7329128/how-to-write-binary-data-to-a-file-using-node-js
 */

function cleanPath(str) {
  if (str) {
    return str.replace(/\.\./g,'').replace(/\/+/g,'').
      replace(/^\/+/,'').replace(/\/+$/,'');
  }
}
function cleanName(str) {
  return str.replace(/\.\./g,'').replace(/\//g,'');
}

Meteor.methods({
  meteorFileUpload: function(mf) {
    console.log('Uploading '+ mf.name +': ' + mf.uploadProgress +'% done');

    jq = JobQueue.find({
      file: mf.name,
      processor: 'Uploading'
    });

    if (jq.count() > 0) {
      JobQueue.update({file: mf.name, processor: 'Uploading'},
        {$set: {status: mf.uploadProgress} });
    } else {
      JobQueue.insert({
        file: mf.name,
        processor: 'Uploading',
        submitTime: new Date(),
        status: mf.uploadProgress
      });
    }

    // Save to disk -- will append as new sections come in
    var path = cleanPath(path), fs = Npm.require('fs'),
      name = cleanName(mf.name || 'file'), encoding = encoding || 'binary',
      chroot = Meteor.chroot || 'uploads';
    path = chroot + (path ? '/' + path + '/' : '/');
    
    // TODO Add file existance checks, etc...
    console.log('Writing ' + path + mf.name);

    mf.save(path);
    console.log('Written!');

    if (mf.size === mf.end) {
      console.log('Finished uploading file: ' + mf.name);
      JobQueue.update({
        file: mf.name,
        processor: 'Uploading'},
        {$set: {status: 'done'}
      });

      process_file(path + name);
      new Processors.Md5(path+name);
      new Processors.Tika(path+name);
    }
    
  }
});

Meteor.startup(function() {
  //fs = Npm.require('fs');
  process.chdir('../../../../..');
  console.log('cwd: ' + process.cwd());
  //fs.symlinkSync('../../../../uploads', '.meteor/local/build/uploads');
});

