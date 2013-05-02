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

        @frontEl = $("div.front",@el)
        @backEl = $("div.back",@el)


    _translateTouchCoordinates: (e) ->
        # only support one finger touch for now

        touch = e.originalEvent.targetTouches[0]
        return {
            x: touch.pageX - touch.target.offsetLeft
            y: touch.pageY - touch.target.offsetTop
        }

    touchstart: (e) =>
        e.preventDefault();
        e.stopPropagation();
        
        # Reset attributes

        @frontEl.removeClass "animated"
        @backEl.removeClass "animated"
        @frontEl.css "-webkit-transition-duration": ""
        @backEl.css "-webkit-transition-duration": ""

        @startCoords = @_translateTouchCoordinates(e)
        @startTime = Date.now()
        @lastMoveTime = @startTime
        @currentState = state.DECIDING

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

        endTime = Date.now()
        distance = 0
        if @moveMode == direction.HORIZONTAL
            distance = Math.abs(@currentPos.x - @startCoords.x)
        else
            distance = Math.abs(@currentPos.y - @startCoords.y)

        time = endTime - @startTime
        acceleration = distance / time
        return {acceleration,distance, time}

class VerticalSwipeCard extends Card
    touchmove: (e) =>
        super(e)
        if @currentState == state.TRACKING && @moveMode == direction.VERTICAL
            cardHeight = @el.height()
            percentAcross = (@startCoords.y - @currentPos.y) / cardHeight
            topPos = $(window).height() * percentAcross
            @el.css "-webkit-transform", "translate3d(0,#{0-topPos}px,0)"
    touchend: (e) =>
        if @moveMode == direction.VERTICAL
            console.log "gotmytouchend"
            @el.css "-webkit-transform", ""
        return super(e)


class RotateCard extends VerticalSwipeCard
    touchstart: (e) =>
        super(e)
        @backEl.css "display", "block"
    touchmove: (e) =>
        e.preventDefault()
        super(e)
        if @currentState == state.TRACKING && @moveMode == direction.HORIZONTAL
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
        super(e)
        console.log @moveMode
        if @moveMode != direction.HORIZONTAL then return
        console.log "processing", @moveMode, direction.HORIZONTAL 
        stats = super(e)

        cardWidth = @el.width()
        
        timeForAllAtAccelerationRate = stats.time * (1/@percentAcross)

        if stats.acceleration < 1 && @percentAcross <= 0.5
            console.log @frontEl[0]
            @frontEl.addClass "animated"
            @frontEl.css "-webkit-transform", "rotate3d(0,1,0,0deg)"
        else if stats.acceleration < 1 || @percentAcross > 0.5

            #remainingTime = (timeForAllAtAccelerationRate * (1 - @percentAcross)) / 1000

            # establish a minimum
            #if remainingTime < 0.2 then remainingTime = 0.2

            @backEl.addClass "animated"
            @backEl.css
                "-webkit-transform": "rotate3d(0,1,0,0deg)"
                #"-webkit-transition-duration": "#{remainingTime}s"

            @postAnimate()

        else if stats.acceleration > 1

            # things get complex here. If we have high acceleration but haven't reached half way.
            console.log "going weird"
            percentLeftForFront = 0.5 - @percentAcross
            timeForFront = (timeForAllAtAccelerationRate * percentLeftForFront) / 1000
            timeForBack = (timeForAllAtAccelerationRate * 0.5) / 1000

            animateBack = () =>
                @frontEl.off "webkitTransitionEnd", animateBack
                @backEl.addClass "animated"
                @backEl.css
                    "-webkit-transition-duration": "#{timeForBack}s"
                    "-webkit-transform": "rotate3d(0,1,0,0deg)"
                @postAnimate()

            @frontEl.on "webkitTransitionEnd", animateBack

            @frontEl.addClass "animated"
            @frontEl.css
                "-webkit-transition-duration": "#{timeForFront}s"
                "-webkit-transform": "rotate3d(0,1,0,90deg)"

            
        
        

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