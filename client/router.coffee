Meteor.Router.add
  '/':
    as: 'search'
    and: ->
      Session.set 'current_view', 'thumbnails'
      Session.set 'search', ''
      Meteor.call 'search', ''
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

