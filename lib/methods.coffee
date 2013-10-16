(exports ? this).solrBase = 'http://solr.as.uky.edu:8995/solr/'

Meteor.methods
  'search': (s, facets = []) ->
    console.log 'Searching for: ' + s
    #solrQ = solrBase + 'select?facet=true&sort=sort_search_api_id+desc&f.tm_url.facet.limit=50&facet.limit=10&f.ss_field_exif_make.facet.limit=50&f.ss_mime.facet.limit=50&fl=sm_*,tm_url,item_id,score&facet.field=ss_field_exif_model&facet.field=ss_field_exif_make&facet.field=tm_field_exif_usercomment&facet.field=im_field_tags&facet.field=ss_mime&facet.field=is_size&facet.field=tm_url&fq=index_id:file_index&facet.missing=false&facet.mincount=1&qf=tm_url^1.0&qf=tm_field_exif_usercomment^1.0&qf=tm_field_exif_image_description^1.0&f.tm_field_exif_usercomment.facet.limit=50&json.nl=map&wt=json&rows=100&f.im_field_tags.facet.limit=50&facet.sort=count&start=0&q="'+s+'"&f.is_size.facet.limit=50&f.ss_field_exif_model.facet.limit=50'
    solrQ = solrBase + 'select?qf=content^1.0&qf=sm_tags^1.0&q='+s+'&facet=true&facet.limit=25&fl=*,ss_filename,ss_md5,id,score&facet.field=sm_content_type&facet.field=sm_tags&facet.missing=false&facet.mincount=1&json.nl=map&wt=json&rows=100&facet.sort=count&start=0'
    #solrQ += _.map(facets, (f) ->
    #  '&facet.field=' + f
    #).join '';
    Meteor.http.get solrQ, {}, (err, result) ->
      #if !SearchResults.findOne {search:s}
      SearchResults.remove {search:s}
      SearchResults.insert {search:s, searchResult: result.content}
      console.log 'search returned: ' + s
      #console.log "json: \n" + result.content

