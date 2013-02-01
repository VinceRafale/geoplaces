Place = Backbone.Model.extend
  idAttribute: "_id"
  url: '/api/places'

  defaults: ->
    name: ''
    address: ''
    loc:
      lat: 0
      lon: 0

PlaceList = Backbone.Collection.extend
  model: Place
  url: '/api/places'

  geoFetch: ->
    this.fetch {data: {lat: window.map.getCenter().lat(), lon: window.map.getCenter().lon()}}

Places = new PlaceList

PlaceView = Backbone.View.extend
  tagName: 'li'
  className: 'place'
  template: _.template($('#place-template').html())

  events: 
    'click .icon-edit': 'edit'
    'click .submit': 'updatePlace'
    'click .cancel': 'render'
    'click .view': 'showOnMap'

  initialize: ->
    this.model.bind('change', this.render, this)
    this.model.bind('destroy', this.remove, this)

  render: ->
    $(this.el).html(this.template(this.model.toJSON()))
    this

  edit: ->
    this.$('.view, .form').fadeToggle(
      duration: 100)

  delete: ->
    this.model.delete

  updatePlace: -> 
    this.model.save
      name: this.$('input.name').val()
      address: this.$('input.address').val()
      lat: this.$('input.lat').val()
      lon: this.$('input.lon').val()
    Places.geoFetch

  showOnMap: ->
    loc = new google.maps.LatLng this.model.get('loc').lat, this.model.get('loc').lon
    window.placeMarker.setMap(null) if typeof(window.placeMarker) != 'undefined'
    window.placeMarker = new google.maps.Marker
      map: window.map
      position: loc
      animation: google.maps.Animation.DROP
    window.map.panTo(loc)
    info_content = $('<p>').html(this.model.get('address').replace("\n",'<br>'))
    window.info = new google.maps.InfoWindow
      content: info_content.html()
    window.info.open(window.map, window.placeMarker)

AppView = Backbone.View.extend
  el: $('#places-map')

  initialize: ->
    Places.bind('add', this.addPlace, this)
    Places.bind('reset', this.addAll, this)
    Places.bind('all', this.render, this)

  getPlaces: ->
    Places.fetch {data: {lat: window.lat, lon: window.lon}}

  addPlace: (place) ->
    view = new PlaceView({model: place})
    this.$('#places ul').prepend(view.render().el)
    view

  addAll: ->
    Places.each(this.addPlace)

  newPlace: (address, lat, lon) ->
    place = new Place
      address: address
      loc:
        lat: lat
        lon: lon
    this.addPlace(place).edit()

window.App = new AppView

$ ->
  window.Geocoder = new google.maps.Geocoder()

  if navigator.geolocation
    navigator.geolocation.getCurrentPosition (position) ->
      window.map.panTo(new google.maps.LatLng(position.coords.latitude, position.coords.longitude))
      window.map.setZoom(16)
      window.App.getPlaces()
  else
    # We should do *something*
    
  mapOptions = 
    mapTypeId: google.maps.MapTypeId.ROADMAP
    zoom: 8
    center: new google.maps.LatLng(0,0)
  
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
      loc = ui.item.obj
      window.placeMarker.setMap(null) if typeof(window.placeMarker) != 'undefined'
      window.placeMarker = new google.maps.Marker
        map: window.map
        position: ui.item.obj.geometry.location
        animation: google.maps.Animation.DROP
      info_content = $('<p>')
        .html(loc.formatted_address.replace(/,/,'<br>'))
        .append('<br><a id="add-place" class="btn btn-primary">Add This Place</a>')
      window.info = new google.maps.InfoWindow
        content: info_content.html()
      google.maps.event.addListener info, 'domready', ->
        $('#add-place').on 'click', ->
          window.info.close()
          window.App.newPlace loc.formatted_address, loc.geometry.location.lat(), loc.geometry.location.lng()
      window.info.open(window.map, window.placeMarker)
      window.map.panTo(loc.geometry.location)

