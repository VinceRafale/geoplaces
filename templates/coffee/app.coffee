Place = Backbone.Model.extend
  idAttribute: "_id"

  defaults: ->
    name: ''
    address: ''

PlaceList = Backbone.Collection.extend
  model: Place
  url: '/api/places'

Places = new PlaceList

PlaceView = Backbone.View.extend
  tagName: 'li'
  className: 'place'
  template: _.template($('#place-template').html())

  events: 
    'click .icon-edit': 'edit'
    'click .submit': 'updatePlace'
    'click .cancel': 'render'

  initialize: ->
    this.model.bind('change', this.render, this)
    this.model.bind('destroy', this.remove, this)

  render: ->
    $(this.el).html(this.template(this.model.toJSON()))
    this

  edit: ->
    this.$('.view, .form').fadeToggle(
      duration: 100)

  updatePlace: -> 
    this.model.save(
      name: this.$('input.name').val()
      address: this.$('textarea.address').val())
    this.render

AppView = Backbone.View.extend
  el: $('#places-map')

  initialize: ->
    Places.bind('add', this.addPlace, this)
    Places.bind('reset', this.addAll, this)
    Places.bind('all', this.render, this)
    Places.fetch()

  addPlace: (place)->
    view = new PlaceView({model: place})
    this.$('.places').append(view.render().el)

  addAll: ->
    Places.each(this.addPlace)

window.App = new AppView

$ ->
  window.Geocoder = new google.maps.Geocoder()

  if navigator.geolocation
    navigator.geolocation.getCurrentPosition((position) ->
      window.map.panTo(new google.maps.LatLng(position.coords.latitude, position.coords.longitude))
      window.map.setZoom(16)
      marker = new google.maps.Marker
        map: window.map
        position: new google.maps.LatLng(position.coords.latitude, position.coords.longitude))
  else
    
  mapOptions = 
    mapTypeId: google.maps.MapTypeId.ROADMAP
    zoom: 8
    center: new google.maps.LatLng(-34.397, 150.644)
  
  window.map = new google.maps.Map(document.getElementById('map_canvas'), mapOptions)

  $('#address-search').autocomplete
    minLength: 3
    source: (req, resp) ->
      window.Geocoder.geocode({address: req.term, bounds: window.map.getBounds()}, (results, status) ->
        resp(_.map(results, (loc) ->
          {
            label: loc.formatted_address
            value: loc.formatted_address
            obj: loc
          })
        )
      )
    select: (event, ui) ->
      $('#address-search').val('')
      marker = new google.maps.Marker
        map: window.map
        position: ui.item.obj.geometry.location
        animation: google.maps.Animation.DROP
      info = new google.maps.InfoWindow
        content: ui.item.obj.formatted_address.replace(/,/, '<br>')
      info.open(window.map, marker)
      window.map.panTo(ui.item.obj.geometry.location)

