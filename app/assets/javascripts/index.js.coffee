PeopleFindr.controller 'IndexCtrl', ['$scope', ($scope) ->
  $scope.data = {}
  $scope.result = {}
  $scope.buttonClass = 'btn-default'
  $scope.disabled = true

  $scope.submit = ->
    $.post '/info', $scope.data
    .then (result) ->
      console.log result
]
