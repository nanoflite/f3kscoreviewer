#= require 'jquery'
#= require 'underscore'
#= require 'backbone'
#= require 'mustache'
#= require 'bootstrap'
#= require 'backbone-patch-recursive-json'

class window.PilotsView extends Backbone.View

    initialize: ->
        @template = $('#pilot-list-template').text()
        @el = '#pilots'

    render: ->
        $(@el).html Mustache.render @template, @collection.toJSON()
        @    

class window.TasksView extends Backbone.View

    initialize: ->
        @template = $('#task-list-template').text()
        @el = '#tasks'

    render: ->
        $(@el).html Mustache.render @template, @collection.toJSON()
        @

class window.FlightMatrixView extends Backbone.View

    initialize: ->
        @template = $('#flightmatrix-template').text()
        @el = '#flightmatrix'

    render: ->
        model = { pilots: @collection.toJSON(), rounds: @collection.first().get('flightGroups').toJSON() }
        $(@el).html Mustache.render @template, model

class window.StartlistView extends Backbone.View

    initialize: ->
        @template = $('#start-template').text()
        @el = '#start'

    render: ->
       $(@el).html Mustache.render @template, @collection.toJSON() 

class window.DetailScoreView extends Backbone.View

    initialize: ->
        @template = $('#detail-template').text()
        @el = '#detail'

    render: ->
        $(@el).html Mustache.render @template, @collection.toJSON()

class window.ScoreView extends Backbone.View

    initialize: ->
        @template = $('#score-template').text()
        @el = '#score'

    render: ->
        rounds = ( @collection.at 0 ).get( 'totalScores' ).length
        $(@el).html Mustache.render @template, { pilots: @collection.toJSON(), rounds: [1..rounds] }

class window.ContestView extends Backbone.View

    initialize: ->
        @template = $('#name-template').text()
        @el = '#name'

    render: ->    
        $(@el).html Mustache.render @template, @model.toJSON()

class window.Contest extends Backbone.Model

    showPilots: ->
        pilotsView = new PilotsView
            collection: @get 'pilots'
        pilotsView.render()

    showTasks: ->
        tasksView = new TasksView
            collection: @get 'tasks'
        tasksView.render()

    showFlightGroupMatrix: ->
        flightmatrixView = new FlightMatrixView
            collection: @get 'pilots'
        flightmatrixView.render()
    
    showStartlist: ->
        startlistView = new StartlistView
            collection: @get 'rounds'
        startlistView.render()

    showDetailScore: ->
        detailScoreView = new DetailScoreView
            collection: @get 'rounds'
        detailScoreView.render()

    showScore: ->
        scoreView = new ScoreView
            collection: @get 'scorePilots'
        scoreView.render()    
        $('#btnExport').off().on 'click', =>
            @get( 'scorePilots' ).exportCSV()

    showContest: ->
        contestView = new ContestView
            model: @
        contestView.render()

    calculateScores: ->
        @get( 'rounds' ).each (round) =>
            round.get( 'groups' ).each (group) =>
                group.calculateScores()
    
        nrRounds = @get( 'rounds' ).length
        nrScrappers = @_calcutateNrScrappers nrRounds
        
        @set 'scorePilots', new PilotCollection
        @get( 'rounds' ).each (round) =>
            roundId = round.get 'id'
            round.get( 'groups' ).each (group) =>
                group.get( 'scorePilots' ).each (pilot) =>
                    scorePilot = @get( 'scorePilots' ).get pilot.get 'id'
                    if not scorePilot
                        scorePilot = pilot.clone()
                        @get( 'scorePilots' ).add scorePilot
                    scores = scorePilot.get 'totalScores'
                    if not scores
                        scorePilot.set 'totalScores', new ScoreCollection
                    totalScore = scorePilot.get 'totalScore'
                    if not totalScore
                        scorePilot.set 'totalScore', 0
                    scorePilot.get( 'totalScores' ).add new Score
                        score:  ( parseFloat( pilot.get( 'score' ).get 'score' ) ).toFixed(0)
                        penalty: pilot.get( 'score' ).get 'penalty'
                        roundId: roundId
                        scrapper: false
        @get( 'scorePilots' ).each (pilot) ->
            sortedScores = pilot.get( 'totalScores' ).sortBy (score) -> parseFloat( score.get 'score' )
            if nrScrappers > 0
                for index in [0..nrScrappers-1]
                    sortedScores[ index ].set 'scrapper', true
            total = 0
            for index in [nrScrappers..sortedScores.length-1]
                total += parseFloat( sortedScores[ index ].get( 'score' ) )    
            pilot.set 'totalScore', total
    
        maxPilot = @get( 'scorePilots' ).max (pilot) -> pilot.get 'totalScore'
        maxScore = maxPilot.get 'totalScore'
        @get( 'scorePilots' ).each (pilot) =>
            pilot.set 'totalPercent', ( 100.0 * pilot.get( 'totalScore' ) / maxScore ).toFixed(2)
            pilot.set 'totalScore', ( parseFloat( pilot.get( 'totalScore' ) ) ).toFixed(0)
        @get( 'scorePilots' ).comparator = (pilot) ->
            -1 * parseFloat( pilot.get 'totalScore' )
        @get( 'scorePilots' ).sort()
        rank = 1
        @get( 'scorePilots' ).each (pilot) =>
            pilot.set 'rank', rank++ 

    _calcutateNrScrappers: (rounds) ->
        scrappers = 0
        if rounds >= 5
            scrappers = 1
        if rounds >= 9
            scrappers = 2
        if rounds >= 14    
            scrappers = 1 + (nr_rounds - 4) / 2
        scrappers

    _getFlightGroupMatrix: ->
        @get( 'pilots' ).each (pilot) =>
            pilotId = pilot.get 'id'
            flightGroups = new FlightGroupCollection
            pilot.set 'flightGroups', flightGroups
            @get( 'rounds').each (round) =>
                roundId = round.get 'id'
                round.get( 'groups' ).each (group) =>
                    groupId = group.get 'id'
                    if group.get( 'pilots' ).get( pilotId ) != undefined
                        flightGroup = new FlightGroup
                            round: roundId
                            group: groupId
                        flightGroups.add flightGroup

    parse: ($x) ->
        @_parseContest $x
        @_parseTasks $x
        @_parsePilots $x
        @_filterRoundsWithAllZeroScores()
        @_getFlightGroupMatrix()

    _value: (element, field) ->
        $(element).find(field).first().text() 

    _parseContest: ($x) ->
        @set 'name', $x.find('competitionName').first().text()

    _parsePilots: ($x) ->
        rounds = new RoundCollection
        pilots = new PilotCollection
        id = 0
        $x.find("competitorList f3kscore\\.Competitor").each (index, element) =>
            firstName = @_value element, 'firstName'
            if firstName != ""
                pilot = new Pilot
                    id: id++
                    firstName: firstName
                    lastName: @_value element, 'lastName'
                    competitorClass: @_value element, 'competitorClass'
                    country: @_value element, 'country'
                    club: @_value element, 'club'
                    faiAmaNum: @_value element, 'faiAmaNum'
                pilots.add pilot
                $(element).find('scores').first().find("f3kscore\\.RoundScore").each (roundScoreIndex, roundScoreElement) =>
                    roundNumber = 1 + parseInt $(roundScoreElement).find("roundNumber").text()
                    groupNumber = parseInt $(roundScoreElement).find("groupNumber").text()
                    round = rounds.get roundNumber
                    if not round
                        round = new Round
                            id: roundNumber
                            task: @get( 'tasks' ).get roundScoreIndex
                            groups: new GroupCollection
                        rounds.add round
                    group = round.get('groups').get groupNumber
                    if not group
                        group = new Group
                            id: groupNumber
                            pilots: new PilotCollection
                            times: new TimeCollection
                            scores: new ScoreCollection
                        round.get('groups').add group
                    group.get('pilots').add pilot
                    times = []
                    $(roundScoreElement).find("flightTimes int").each (timeIndex, timeElement) ->
                        time = parseInt $(timeElement).text()
                        time = 0 if time < 0
                        times.push time
                    time = new Time
                        times: times
                    group.get('times').add time
        @set 'rounds', rounds
        @set 'pilots', pilots

    _filterRoundsWithAllZeroScores: ->
        roundsToDelete = []
        @get( 'rounds' ).each (round) ->
            time = 0
            round.get( 'groups' ).each (group) ->
                group.get( 'times' ).each (times) ->
                    time += _.reduce times.get( 'times' ), ( (a, n) -> a + n ), 0
            roundsToDelete.push round if time == 0
        @get( 'rounds' ).remove round for round in roundsToDelete
    
    _parseTasks: ($x) ->
        tasks = new TaskCollection
        id = 0
        $x.find("competitorList f3kscore\\.Competitor").first().find("lastCalculatedTask").each (index, element) =>
            parts = ( @_value element, 'name' ).split /-/
            task = new Task
                id: id++
                letter: parts[0].replace /"/g, ''
                name: parts[1]
                description: @_value element, 'longName'
                windowTime: @_value element, 'windowTime'
            tasks.add task
        @set 'tasks', tasks

class window.Pilot extends Backbone.Model

class window.PilotCollection extends Backbone.Collection

    model: Pilot

#    comparator: (model) ->
#        "#{model.get 'lastName'} #{model.get 'firstName'}"

    exportCSV: ->
        array = [ [ 'Rank', 'Name', 'Score' ] ]
        @.each (pilot) =>
            array.push [ pilot.get( 'rank' ), "#{pilot.get( 'firstName' )} #{pilot.get( 'lastName' )}", pilot.get( 'totalPercent' ) ]
        csv = ( line.join(",") for line in array ).join( '\r\n' )
        blob = new Blob [ csv ], { type: 'text/csv' }
        url = window.webkitURL.createObjectURL( blob )
        $('#btnExport').attr 'download', 'export.csv'
        $('#btnExport').attr 'href', url

class window.Task extends Backbone.Model

class window.TaskCollection extends Backbone.Collection

    model: Task

class window.Round extends Backbone.Model
    
class window.RoundCollection extends Backbone.Collection

    model: Round

    comparator: (model) ->
        model.get 'id'

class window.Group extends Backbone.Model

    calculateScores: ->
        @get( 'times' ).each (time) =>
            totalTime = _.reduce time.get('times'), ( (a, n) -> a + n ), 0
            time.set 'totalTime', totalTime
        maxTime = @get( 'times' ).max (time) -> time.get 'totalTime'
        max = maxTime.get 'totalTime'
        @get( 'times' ).each (time) =>
            score = (1000.0 * time.get( 'totalTime' ) / max).toFixed(2)
            score = 0 if isNaN score 
            @get( 'scores' ).add new Score
                score: score
                penalty: 0
        times = @get( 'times' ).at 0
        @set 'timesWidth', [1..times.get('times').length]
        @set 'scorePilots', new PilotCollection    
        for i in [0..@get( 'pilots' ).length-1]
            pilot = @get( 'pilots' ).at( i ).clone()
            @get( 'scorePilots' ).add pilot
            pilot.set 'times', @get( 'times' ).at i
            pilot.set 'score', @get( 'scores' ).at i
 
class window.GroupCollection extends Backbone.Collection
    
    model: Group

    comparator: (model) ->
        model.get 'id'

class window.Time extends Backbone.Model

class window.TimeCollection extends Backbone.Collection

    model: Time

class window.FlightGroup extends Backbone.Model

class window.FlightGroupCollection extends Backbone.Collection

    model: FlightGroup

class window.Score extends Backbone.Model

class window.ScoreCollection extends Backbone.Collection

handleFileSelect = (event) ->
    file = event.target.files[0]

    reader = new FileReader
    reader.onload = (event) =>
        showContestFromText event.target.result
    reader.readAsText file

handleUrlSelect = (url) ->
    return if not url
    $.get url, (xml) ->
        showContestFromXml jQuery(xml) 

showContestFromText = (text) ->
    $x = $ $.parseXML text
    showContestFromXml $x

showContestFromXml = (xml) ->
        $('#menu').hide()
        $('#contest').fadeIn()
        contest = new Contest
        contest.parse xml
        contest.calculateScores()
        contest.showContest() 
        contest.showPilots() 
        contest.showTasks()
        contest.showFlightGroupMatrix()
        contest.showStartlist()
        contest.showDetailScore()
        contest.showScore()

$(document).ready ->
    $('#f3kscoreurlselect').hide()
    $('#f3kscoreurl').focus (event) ->
        $('#f3kscoreurlselect').show().css('position', 'relative').css('left', $('#f3kscoreurltitle').width() + 10)
    $('#f3kscoreurl').keypress (event) ->
        event.preventDefault()
    $('#f3kscoreurlselect').find('a').click (event) ->
        $('#f3kscoreurl').val $(event.currentTarget).text()
        $('#f3kscoreurl').data('value', $(event.currentTarget).data('value'))
        $('#f3kscoreurlselect').fadeOut()
    $('#contest').hide()
    $('#_f3kscorefile').on 'change', (event) =>
        $('#f3kscorefile').val $(event.currentTarget).val().replace 'C:\\fakepath\\', ''
        handleFileSelect event
    $('#btnExamine').click (event) ->
        handleUrlSelect $('#f3kscoreurl').data 'value'
