Place = Backbone.Model.extend
  idAttribute: "_id"
  url: ->
    if this.isNew()
      '/api/places'
    else
      '/api/places/' + this.id

  defaults: ->
    name: ''
    address: ''
    loc:
      lat: 0
      lon: 0

PlaceList = Backbone.Collection.extend
  model: Place
  url: '/api/places'

  geoFetch: (latitude, longitude)->
    latitude = window.map.getCenter().lat() if typeof(latitude) == 'undefined'
    longitude = window.map.getCenter().lng() if typeof(longitude) == 'undefined'
    this.fetch {data: {lat: latitude, lon: longitude}}

Places = new PlaceList

PlaceView = Backbone.View.extend
  tagName: 'li'
  className: 'place'
  template: _.template($('#place-template').html())

  events: 
    'click .icon-eye-open': 'showOnMap'
    'click .icon-edit': 'edit'
    'click .icon-remove': 'clear'
    'click .submit': 'updatePlace'
    'click .cancel': 'render'

  initialize: ->
    this.model.bind('reset', this.render, this)
    this.model.bind('change', this.render, this)
    this.model.bind('destroy', this.remove, this)

  render: ->
    $(this.el).html(this.template(this.model.toJSON()))
    this

  edit: ->
    this.$('.view, .form').fadeToggle(
      duration: 100)

  remove: ->
    $(this.el).remove()

  clear: ->
    if confirm 'Are you sure?'
      this.model.destroy 
        wait: true
      success: ->
        window.App.getPlaces()
        window.App.togglePlacesMessage()

  updatePlace: -> 
    this.model.save
      wait: true
      name: this.$('input.name').val()
      address: this.$('input.address').val()
      lat: this.$('input.lat').val()
      lon: this.$('input.lon').val()
      success: ->
        window.App.getPlaces()

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

  getPlaces: (lat, lng)->
    Places.geoFetch(lat, lng)

  addPlace: (place) ->
    view = new PlaceView({model: place})
    this.$('#places ul').append(view.render().el)

  addAll: ->
    this.togglePlacesMessage()
    Places.each(this.addPlace)

  newPlace: (address, lat, lon) ->
    view = new PlaceView
      model: new Place
        address: address
        loc:
          lat: lat
          lon: lon
    $('#empty-message').fadeOut('fast')
    this.$('#places ul').prepend(view.render().el)
    $('#address-search').val('')
    view.edit()

  togglePlacesMessage: ->
    if Places.isEmpty()
      $('#empty-message').fadeIn('fast') unless $('#empty-message').is(':visible')
    else
      $('#empty-message').fadeOut('fast') unless $('#empty-message').is(':hidden')

window.App = new AppView

$ ->
  window.Geocoder = new google.maps.Geocoder()

  if navigator.geolocation
    navigator.geolocation.getCurrentPosition (position) ->
      window.map.panTo(new google.maps.LatLng(position.coords.latitude, position.coords.longitude))
      window.map.setZoom(16)
      window.App.getPlaces(position.coords.latitude, position.coords.longitude)
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

