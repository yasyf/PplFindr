PeopleFindr.controller 'IndexCtrl', ['$scope', '$timeout', '$interval', '$location', '$modal', ($scope, $timeout, $interval, $location, $modal) ->

  reset = (keep_data) ->
    $location.search('go', false) if keep_data
    $scope.data = {} unless keep_data
    $scope.loading = false
    $scope.progress = 1
    $scope.results = undefined
    $scope.disabled = true

  reset(false)

  $scope.$watch 'data', (data) ->
    $location.search('data', btoa($.param(data)))
  , true

  $scope.resultSort = (item) -> -item[0]

  getIconClass = (name) ->
    formattedName = name.replace('+', ' Plus').toLowerCase().replace(' ', '-')
    "#{formattedName} fa fa-#{formattedName}"

  getSocialItems = (memberships, defaultName) ->
    unless memberships?.length > 0
      return []
    memberships = _.reject memberships, (membership) ->
      membership.site_name not in ['Twitter', 'Facebook', 'LinkedIn', 'Google+', 'GitHub', 'Flickr', "Foursquare", "Tumblr", "YouTube"]
    membership_chunks = (memberships[i..i+4] for i in [0..memberships.length-1] by 5)
    _.map membership_chunks, (chunk) ->
      _.map chunk, (membership) ->
        url: membership.profile_url
        name: membership.site_name
        user: membership.username or defaultName
        class: getIconClass(membership.site_name)

  $scope.submit = ->
    $scope.loading = true
    interval = $interval ->
      return unless $scope.progress < 95
      $scope.progress += 1
    , 500
    $.post '/info', $scope.data
    .then (results) ->
      $timeout ->
        $interval.cancel(interval)
        $scope.results = _.map results, (result) ->
          result[1].socialItems = getSocialItems(result[1].memberships, result[1].first_name?.toLowerCase())
          result
      $timeout ->
        $scope.loading = false
        $location.search('go', true)
      , 100
      $timeout ->
        $('.ttip').tooltip()
      , 1000

  $scope.reset = -> reset(true)

  $scope.shorten = ->
    url = encodeURIComponent($location.absUrl())
    $.get("https://api-ssl.bitly.com/v3/shorten?access_token=c1358035bc401ff7a8306fde6e969f94659412cc&domain=j.mp&longUrl=#{url}")
    .then (response) ->
      shortUrl = response.data.url
      $modal.open
        templateUrl: 'shorten_modal.html'
        controller: 'ShortenModalCtrl'
        resolve:
          url: -> shortUrl

  try
    $scope.data = $.deparam(atob($location.search().data), true) if $location.search().data
    if $location.search().go is true
      $scope.submit()
  catch e
    console.error e.toString()

]

PeopleFindr.controller 'ShortenModalCtrl', ['$scope', 'url', ($scope, url) ->
  $scope.url = url
]
