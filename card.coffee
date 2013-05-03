state =
    DECIDING: 1
    TRACKING:2

direction =
    VERTICAL: 1
    HORIZONTAL: 2

swipeDirection =
    LEFTTORIGHT: 1
    RIGHTTOLEFT: 2


class Card
    _decideRadius = 5
    constructor: (@el) ->
        @el.on "touchstart mousedown", @touchstart
        @el.on "touchmove mousemove", @touchmove
        @el.on "touchend mouseup", @touchend

        @frontEl = $("div.front",@el)
        @backEl = $("div.back",@el)


    _translateTouchCoordinates: (e) =>
        # only support one finger touch for now
        #if e.originalEvent.touches.length > 1 then return null

        if @touchId
            for t in e.originalEvent.touches
                if t.identifier == @touchId
                    touch = t
                    break
        else
            touch = e.originalEvent.touches?[0]

        @touchId = touch.identifier
        return {
            x: touch.pageX - touch.target.offsetLeft
            y: touch.pageY - touch.target.offsetTop
        }

    touchstart: (e) =>
        e.preventDefault();
        e.stopPropagation();
        if @touchId
            return false
        # Reset attributes


        @el.css "-webkit-transition-duration": ""
        @el.removeClass "animated"
        @frontEl.removeClass "animated"
        @backEl.removeClass "animated"
        @frontEl.css "-webkit-transition-duration": ""
        @backEl.css "-webkit-transition-duration": ""

        @startCoords = @_translateTouchCoordinates(e)
        @startTime = Date.now()
        @lastMoveTime = @startTime
        @currentState = state.DECIDING
        return true

    touchmove: (e) =>
        e.preventDefault();
        e.stopPropagation();
        #@el.html("touchmove")
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

            #@el.html(@moveMode)

    touchend: (e) =>
        if e.originalEvent.touches.length > 0 then return false
        @touchId = null
        endTime = Date.now()
        distance = 0
        if @moveMode == direction.HORIZONTAL
            distance = Math.abs(@currentPos.x - @startCoords.x)
            @swipeDirection = if @currentPos.x < @startCoords.x then swipeDirection.RIGHTTOLEFT else swipeDirection.LEFTTORIGHT
        else
            distance = Math.abs(@currentPos.y - @startCoords.y)

        time = endTime - @startTime
        acceleration = distance / time
        return {acceleration,distance, time}

class VerticalSwipeCard extends Card
    constructor: (el) ->
        super(el)
        @panes = $("div.side",@el)

    touchmove: (e) =>
        super(e)

        if @currentState == state.TRACKING && @moveMode == direction.VERTICAL
            cardHeight = @el.height()
            @percentVertical = (@startCoords.y - @currentPos.y) / cardHeight
            topPos = $(window).height() * @percentVertical
            @panes.css "-webkit-transform", "translate3d(0,#{0-topPos}px,0)"
    touchend: (e) =>
        stats = super(e)
        console.log stats
        if !stats then return false

        timeForAllAtAccelerationRate = stats.time * (1/Math.abs(@percentVertical))
        if @moveMode == direction.VERTICAL
            if @percentVertical > 0.5 || @percentVertical < -0.5
                eventualTop = 110 * if @percentVertical < 0 then 1 else -1

                timeLeft = timeForAllAtAccelerationRate * (1-Math.abs(@percentVertical)) / 1000

                @panes.css
                    "-webkit-transform": "translate3d(0,#{eventualTop}%,0)"
                    "-webkit-transition-duration": "#{timeLeft}s"
            else if stats.acceleration > 0.8
                timeLeft = timeForAllAtAccelerationRate * (1-Math.abs(@percentVertical)) / 1000
                eventualTop = 110 * if @percentVertical < 0 then 1 else -1
                @panes.css
                    "-webkit-transform": "translate3d(0,#{eventualTop}%,0)"
                    "-webkit-transition-duration": "#{timeLeft}s"

            else
                @panes.css
                    "-webkit-transform": "translate3d(0,0%,0)"
                    "-webkit-transition-duration": "0.2s"
        return stats


class RotateCard extends VerticalSwipeCard
    touchstart: (e) =>
        super(e)
        @frontEl.off "webkitTransitionEnd", @delayedAnimateComplete
        @backEl.off "webkitTransitionEnd", @delayedAnimateComplete
    touchmove: (e) =>
        e.preventDefault()
        super(e)
        if @currentState == state.TRACKING && @moveMode == direction.HORIZONTAL

            if @backEl.css("display") == "none"
                @backEl.css
                    "display": "block"
                    "-webkit-transform": "rotate3d(0,1,0,90deg)"

            cardWidth = @el.width()
            @percentAcross = (@startCoords.x - @currentPos.x) / cardWidth
            multiplier = if @percentAcross < 0 then -1 else 1
            @percentAcross = Math.abs(@percentAcross)

            if @percentAcross <= 0.5
                frontAngle = -180 * @percentAcross
                if frontAngle < -180 then frontAngle = -180
                frontAngle = frontAngle * multiplier
                backAngle = 90 * multiplier
             else
                frontAngle = -90 * multiplier
                backAngle = ((-180 * @percentAcross) + 180) * multiplier
                #if backAngle < -180 then frontAngle = -180

            @frontEl.css "-webkit-transform", "rotate3d(0,1,0,#{frontAngle}deg)"
            @backEl.css "-webkit-transform", "rotate3d(0,1,0,#{backAngle}deg)"

    touchend: (e) =>
        if !super(e) then return false
        console.log @moveMode
        if @moveMode != direction.HORIZONTAL then return
        console.log "processing", @moveMode, direction.HORIZONTAL 
        stats = super(e)

        cardWidth = @el.width()
        
        timeForAllAtAccelerationRate = stats.time * (1/@percentAcross)

        if stats.acceleration < 0.8 && @percentAcross <= 0.5
            @frontEl.addClass "animated"
            @frontEl.css "-webkit-transform", "rotate3d(0,1,0,0deg)"
        else if stats.acceleration < 0.8 || @percentAcross > 0.5

            #remainingTime = (timeForAllAtAccelerationRate * (1 - @percentAcross)) / 1000

            # establish a minimum
            #if remainingTime < 0.2 then remainingTime = 0.2

            @backEl.addClass "animated"
            @backEl.css
                "-webkit-transform": "rotate3d(0,1,0,0deg)"
                #"-webkit-transition-duration": "#{remainingTime}s"

            @postAnimate()

        else if stats.acceleration >= 0.8

            # things get complex here. If we have high acceleration but haven't reached half way.
            percentLeftForFront = 0.5 - @percentAcross
            timeForFront = (timeForAllAtAccelerationRate * percentLeftForFront)  / 1000
            @timeForBack = (timeForAllAtAccelerationRate * 0.5) / 1000

            @frontEl.on "webkitTransitionEnd", @delayedAnimateComplete

            frontAngleTo = if @swipeDirection == swipeDirection.RIGHTTOLEFT then -90 else 90

            @frontEl.addClass "animated"
            @backEl.css
                "display": "block"
                "-webkit-transform": "rotate3d(0,1,0,90deg)"

            @frontEl.css
                "-webkit-transition-duration": "#{timeForFront}s"
                "-webkit-transform": "rotate3d(0,1,0,#{frontAngleTo}deg)"

    delayedAnimateComplete: () =>
        @frontEl.off "webkitTransitionEnd", @delayedAnimateComplete
        @backEl.addClass "animated"
        @backEl.css
            "-webkit-transition-duration": "#{@timeForBack}s"
            "-webkit-transform": "rotate3d(0,1,0,0deg)"
        @postAnimate()

    postAnimate: () =>
        console.log "switching"
        newBack = @frontEl
        @frontEl = @backEl
        @backEl = newBack
        @backEl.css "display", "none"






$(document).on "touchmove", (e) ->
    e.preventDefault();

$(document).on "touchstart", (e) ->
    e.preventDefault();

$(document).on "scroll", () ->
    console.log "scrolly"

new RotateCard($(".glasspane"))