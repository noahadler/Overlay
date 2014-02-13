Meteor.Router.add
  '/':
    as: 'search'
    and: ->
      Session.set 'current_view', 'thumbnails'
      Session.set 'search', ''
      Meteor.call 'search', ''
  '/queue':
    as: 'queue'
    and: ->
      Session.set 'current_view', 'queue'
  '/:search':
    as: 'search'
    and: (search) ->
      Session.set 'current_view', 'thumbnails'
      Session.set 'search', search
      Meteor.call 'search', search
  '/:view/:search':
    as: 'search'
    and: (view, search) ->
      Session.set 'current_view', view
