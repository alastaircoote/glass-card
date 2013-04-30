state =
    DECIDING: 1
    TRACKING:2

direction =
    VERTICAL: 1
    HORIZONTAL: 2


class Card
    _decideRadius = 5
    constructor: (@el) ->
        @el.on "touchstart", @touchstart
        @el.on "touchmove", @touchmove
        @el.on "touchend", @touchend

    _translateTouchCoordinates: (e) ->
        # only support one finger touch for now

        touch = e.originalEvent.targetTouches[0]
        return {
            x: touch.pageX - touch.target.offsetLeft
            y: touch.pageY - touch.target.offsetTop
        }

    touchstart: (e) =>
        @el.removeClass "animated"
        @startCoords = @_translateTouchCoordinates(e)
        @startTime = Date.now()
        @currentState = state.DECIDING

    touchmove: (e) =>
        @currentPos = @_translateTouchCoordinates(e)
        if @currentState == state.DECIDING
            xDiff = Math.abs(@currentPos.x - @startCoords.x)
            yDiff = Math.abs(@currentPos.y - @startCoords.y)
            if xDiff < 5 && yDiff < 5 then return

            if xDiff >= 5
                @moveMode = direction.HORIZONTAL
            else
                @moveMode = direction.VERTICAL

            @currentState = state.TRACKING

            @el.html(@moveMode)

    touchend: (e) =>

        endTime = Date.now()
        distance = 0
        if @moveMode == direction.HORIZONTAL
            distance = Math.abs(@currentPos.x - @startCoords.x)
        else
            distance = Math.abs(@currentPos.y - @startCoords.y)

        time = endTime - @startTime
        acceleration = distance / time
        return {acceleration,distance}

class VerticalSwipeCard extends Card
    touchmove: (e) =>
        e.preventDefault()
        super(e)
        if @currentState == state.TRACKING && @moveMode == direction.VERTICAL
            cardHeight = @el.height()
            percentAcross = (@startCoords.y - @currentPos.y) / cardHeight
            topPos = $(window).height() * percentAcross
            @el.css "-webkit-transform", "translate3d(0,#{0-topPos}px,0)"


class RotateCard extends VerticalSwipeCard
    touchmove: (e) =>
        e.preventDefault()
        super(e)
        if @currentState == state.TRACKING && @moveMode == direction.HORIZONTAL
            cardWidth = @el.width()
            percentAcross = (@startCoords.x - @currentPos.x) / cardWidth
            rotateAngle = -180 * percentAcross
            if rotateAngle < -180 then rotateAngle = -180
            #@el[0].innerHTML += "<br/>" +  percentAcross
            @el.css "-webkit-transform", "rotate3d(0,1,0,#{rotateAngle}deg)"
    touchend: (e) =>
        if !@moveMode == direction.HORIZONTAL then return
        stats = super(e)
        @el.html(stats.acceleration)
        cardWidth = @el.width()
        if stats.acceleration < 1 && stats.distance < cardWidth / 2
            @el.addClass "animated"
            @el.css "-webkit-transform", ""
        else 
            @el.addClass "animated"
            @el.css "-webkit-transform", "rotate3d(0,1,0,-180deg)"



new RotateCard($("#cardtarget"))