#= require 'jquery'
#= require 'mustache'
#= require 'underscore'
#= require 'bootstrap'

class Competitor
    constructor: (@index, @name, @lastName, @class, @country, @club, @faiNumber) ->
        console.log "#{@index}, #{@name}, #{@lastName}"
        @rounds = []        

    getName: ->
        "#{@name} #{@lastName}"

    addRound: (round) ->
        @rounds.push round

competitors = []

class Task
    constructor: (@index, @name, @longName, @windowTime) ->

    getName: ->
        "#{@name} - #{@longName}"

tasks = []

class RoundScore
    constructor: (@round, @group, @task, @competitor, @flightTimes) ->

roundScores = []

class Round
    constructor: (@roundNumber, @groupNumber, @task) ->

class Contest
    constructor: (@name) ->
        @pilots = []
        @tasks = []
        @rounds = []

    findContestRound: (roundNumber) ->
        for round in @rounds
            return round if round.roundNumber == roundNumber
        return null

    addContestRound: (round) ->
        @rounds.push round

class ContestRound
    constructor: (@roundNumber, @task) ->
        @groups = []
        @scores = []

    findContestGroup: (groupNumber) ->
        for group in @groups
            return group if group.groupNumber == groupNumber
        return null

    addContestGroup: (group) ->
        @groups.push group

    addRoundScore: (score) ->
        @scores.push score

    getPilotTotalFlightTime: (pilot) ->
        for score in @scores
            if score.competitor == pilot
                sum = 0
                sum += time for time in score.flightTimes
                return sum

    getPilotFlightTimes: (pilot) ->
        for score in @scores
            if score.competitor == pilot
                return score.flightTimes
        []

    getPilotScores: (groupNumber) ->
        scores = {}
        group = @findContestGroup groupNumber
        sortedPilots = _.sortBy group.pilots, (pilot) => @getPilotTotalFlightTime(pilot)
        sortedPilots = sortedPilots.reverse() 
        max = @getPilotTotalFlightTime sortedPilots[0]
        for pilot in sortedPilots
            points = Math.floor( @getPilotTotalFlightTime(pilot) / max * 1000 )
            scores[pilot.getName()] = points
        scores

    getMaxFlights: ->
        maxFlights = 0
        for group in @groups
            for pilot in group.pilots
                flights = @getPilotFlightTimes(pilot)
                maxFlights = flights.length if flights.length > maxFlights 
        maxFlights

class ContestGroup
    constructor: (@groupNumber) ->
        @pilots = []

    addPilot: (pilot) ->
        @pilots.push pilot

contest = null

showCompetitors = ->
    template = $("#competitor-list-template").text()
    $("#competitors").html Mustache.render template, { competitors: competitors }

showTasks = ->
    template = $("#task-list-template").text()
    $("#tasks").html Mustache.render template, { tasks: tasks }

showFlightMatrix = ->
    matrix = []
    for competitor in competitors
        rounds = competitor.rounds
        groups = [] 
        for round in rounds
            groups.push { group: round.groupNumber }
        matrix.push { name: competitor.getName(), groups: groups }
    rounds = competitors[0].rounds 

    template = $("#flightmatrix-template").text()
    $("#flightmatrix").html Mustache.render template, { rounds: rounds, matrix: matrix }

scores = {} 

showDetail = ->
    _rounds = []
    for round in contest.rounds
        _round =
            roundNumber: round.roundNumber 
            roundName: round.task.getName()
        _groups = []
        for group in _.sortBy( round.groups, (group) -> group.groupNumber )
            _group = 
                groupNumber: group.groupNumber
            _pilots = []
            pilotScores = round.getPilotScores group.groupNumber
            for pilot in group.pilots
                flights = round.getPilotFlightTimes(pilot)
                _pilot =
                    name: pilot.getName()
                    flights: ( { time: flights[i] } for i in [0..round.getMaxFlights()-1] )
                    total: round.getPilotTotalFlightTime(pilot)
                    score: pilotScores[pilot.getName()]
                    penalty: 0
                _pilots.push _pilot

                if not scores[pilot.getName()]
                    scores[pilot.getName()] = { rounds: [] }
                scores[pilot.getName()]['rounds'].push { round: round.roundNumber, score: _pilot['score'], scrapped: false }

            _group['pilots'] = _.sortBy( _pilots, (pilot) -> -1 * pilot.score )
            _group['flights'] = ( { time: i } for i in [1..round.getMaxFlights()] )
            _groups.push _group
            _round['groups'] = _groups
        _rounds.push _round

    console.log _rounds

    template = $("#detail-template").text()
    $("#detail").html Mustache.render template, { rounds: _rounds }

    template = $("#start-template").text()
    $("#start").html Mustache.render template, { rounds: _rounds }

showScore = ->
    nr_rounds = contest.rounds.length

    scrappers = 0
    if nr_rounds >= 5
        scrappers = 1
    if nr_rounds >= 9
        scrappers = 2
    if nr_rounds >= 14    
        scrappers = 1 + (nr_rounds - 4) / 2

    for pilot of scores
        total = 0
        rounds = _.sortBy( scores[pilot]['rounds'], (round) -> round.score )
        if scrappers > 0    
            for i in [0..scrappers-1]
                rounds[i]['scrapped'] = true
        for round in rounds 
            total += round['score'] if not round['scrapped']
        scores[pilot]['total'] = total   

    console.log scores

    _rounds = ( { roundNumber: round.roundNumber } for round in contest.rounds  )
    _pilots = ( { rounds: scores[pilot]['rounds'], name: pilot, score: scores[pilot]['total'] } for pilot of scores )
    _pilots = _.sortBy( _pilots, (pilot) -> -1 * pilot.score )

    rank = 1
    for _pilot in _pilots
        _pilot['rank'] = rank++

    hundred = _pilots[0].score
    pilot['percent'] = Math.round( pilot['score'] / hundred * 10000 ) / 100 for pilot in _pilots       
 
    template = $("#score-template").text()
    $("#score").html Mustache.render template, { rounds: _rounds, pilots: _pilots }

parse = (xml) ->
    $x = $ $.parseXML xml

    contest = new Contest $x.find('competitionName').first().text()

    $x.find("competitorList f3kscore\\.Competitor").first().find("task").each (index, element) ->
        values = ( $(element).find(field).text() for field in [ "name", "longName", "windowTime" ] )
        tasks.push new Task index, values...

    id = 0
    $x.find("competitorList f3kscore\\.Competitor").each (index, element) ->
        values = ( $(element).find(field).first().text() for field in [ "firstName", "lastName", "competitorClass", "country", "club", "faiAmaNum" ] )
        console.log values
        if values[0] != ""
            competitor = new Competitor id++, values... 
            competitors.push competitor
            $(element).find('scores').first().find("f3kscore\\.RoundScore").each (roundScoreIndex, roundScoreElement) ->
                roundNumber = 1 + parseInt $(roundScoreElement).find("roundNumber").text()
                groupNumber = parseInt $(roundScoreElement).find("groupNumber").text()
                times = []
                $(roundScoreElement).find("flightTimes int").each (timeIndex, timeElement) ->
                    time = parseInt $(timeElement).text()
                    times.push time if time not in [ -1, 0 ]
                roundScores.push new RoundScore roundNumber, groupNumber, tasks[roundScoreIndex], competitor, times

    for score in roundScores
        round = new Round score.round, score.group, score.task
        score.competitor.addRound round

    contest.pilots = competitors
    contest.tasks = tasks

    for score in roundScores
        if not contest.findContestRound score.round
            round = new ContestRound score.round, score.task
            for roundScore in roundScores
                if roundScore.round == score.round
                    round.addRoundScore roundScore
            contest.addContestRound round
        round = contest.findContestRound score.round
        if not round.findContestGroup score.group
            group = new ContestGroup score.group
            round.addContestGroup group
        group = round.findContestGroup score.group
        group.addPilot score.competitor
    
showCompetition = ->
    template = $('#name-template').text()
    $("#name").html Mustache.render template, { name: contest.name }

handleFileSelect = (event) ->
    file = event.target.files[0]
    $("#pilots").append "#{file.name}, #{file.type}, #{file.size}, #{file.lastModifiedDate}"

    reader = new FileReader
    reader.onload = (event) =>
        parse event.target.result
        showCompetition()
        showCompetitors()
        showTasks()
        showFlightMatrix()
        showDetail()
        showScore()    
    
    reader.readAsText file

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
        $('#menu').hide()
        $('#contest').fadeIn()
        handleFileSelect event
