rewire = angular.module("rewire", [])

rewire.controller(
    "Options": ($scope) ->
        $scope.patterns = {}

        $scope.validate_pattern = () ->
            try
                RegExp($scope.rewire_pattern)
                $scope.bad_pattern = false
            catch e
                $scope.bad_pattern = true

        $scope.add_pattern = () ->
            if $scope.bad_pattern
                return

            chrome.runtime.sendMessage({type: "add-pattern", pattern: $scope.rewire_pattern}, () ->
                $scope.rewire_pattern = ""
                $scope.refreshPatterns()
            )

        $scope.del_pattern = (id) ->
            console.log("Deleting pattern: " + id)
            chrome.runtime.sendMessage({type: "del-pattern", id: id}, () -> $scope.refreshPatterns())

        $scope.refreshPatterns = () ->
            chrome.runtime.sendMessage({type: "list-patterns"}, (patterns) ->
                $scope.$apply(() -> $scope.patterns = patterns)
            )

        $scope.setDestination = (idx, url) ->
            console.log("Setting destination " + idx + " to " + url)
            chrome.runtime.sendMessage({type: "set-destination", idx:idx, url:url}, () ->)

        $scope.refreshDestinations = () ->
            chrome.runtime.sendMessage({"type": "list-destinations"}, (destinations) ->
                $scope.$apply(() -> $scope.destinations = destinations)
            )

        $scope.refreshDestinations()
        $scope.refreshPatterns()
)
