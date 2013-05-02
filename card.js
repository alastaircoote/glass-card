// Generated by CoffeeScript 1.3.3
(function() {
  var Card, RotateCard, VerticalSwipeCard, direction, state,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  state = {
    DECIDING: 1,
    TRACKING: 2
  };

  direction = {
    VERTICAL: 1,
    HORIZONTAL: 2
  };

  Card = (function() {
    var _decideRadius;

    _decideRadius = 5;

    function Card(el) {
      this.el = el;
      this.touchend = __bind(this.touchend, this);

      this.touchmove = __bind(this.touchmove, this);

      this.touchstart = __bind(this.touchstart, this);

      this._translateTouchCoordinates = __bind(this._translateTouchCoordinates, this);

      this.el.on("touchstart mousedown", this.touchstart);
      this.el.on("touchmove mousemove", this.touchmove);
      this.el.on("touchend mouseup", this.touchend);
      this.frontEl = $("div.front", this.el);
      this.backEl = $("div.back", this.el);
    }

    Card.prototype._translateTouchCoordinates = function(e) {
      var t, touch, _i, _len, _ref, _ref1;
      if (this.touchId) {
        _ref = e.originalEvent.touches;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          t = _ref[_i];
          if (t.identifier === this.touchId) {
            touch = t;
            break;
          }
        }
      } else {
        touch = (_ref1 = e.originalEvent.touches) != null ? _ref1[0] : void 0;
      }
      this.touchId = touch.identifier;
      return {
        x: touch.pageX - touch.target.offsetLeft,
        y: touch.pageY - touch.target.offsetTop
      };
    };

    Card.prototype.touchstart = function(e) {
      e.preventDefault();
      e.stopPropagation();
      if (this.touchId) {
        return false;
      }
      this.frontEl.removeClass("animated");
      this.backEl.removeClass("animated");
      this.frontEl.css({
        "-webkit-transition-duration": ""
      });
      this.backEl.css({
        "-webkit-transition-duration": ""
      });
      this.startCoords = this._translateTouchCoordinates(e);
      this.startTime = Date.now();
      this.lastMoveTime = this.startTime;
      this.currentState = state.DECIDING;
      return true;
    };

    Card.prototype.touchmove = function(e) {
      var xDiff, yDiff;
      e.preventDefault();
      e.stopPropagation();
      this.currentPos = this._translateTouchCoordinates(e);
      if (this.currentState === state.DECIDING) {
        xDiff = Math.abs(this.currentPos.x - this.startCoords.x);
        yDiff = Math.abs(this.currentPos.y - this.startCoords.y);
        if (xDiff < 5 && yDiff < 5) {
          return;
        }
        if (xDiff >= 5) {
          this.moveMode = direction.HORIZONTAL;
        } else {
          this.moveMode = direction.VERTICAL;
        }
        return this.currentState = state.TRACKING;
      }
    };

    Card.prototype.touchend = function(e) {
      var acceleration, distance, endTime, time;
      if (e.originalEvent.touches.length > 0) {
        return false;
      }
      this.touchId = null;
      endTime = Date.now();
      distance = 0;
      if (this.moveMode === direction.HORIZONTAL) {
        distance = Math.abs(this.currentPos.x - this.startCoords.x);
      } else {
        distance = Math.abs(this.currentPos.y - this.startCoords.y);
      }
      time = endTime - this.startTime;
      acceleration = distance / time;
      return {
        acceleration: acceleration,
        distance: distance,
        time: time
      };
    };

    return Card;

  })();

  VerticalSwipeCard = (function(_super) {

    __extends(VerticalSwipeCard, _super);

    function VerticalSwipeCard() {
      this.touchend = __bind(this.touchend, this);

      this.touchmove = __bind(this.touchmove, this);
      return VerticalSwipeCard.__super__.constructor.apply(this, arguments);
    }

    VerticalSwipeCard.prototype.touchmove = function(e) {
      var cardHeight, percentAcross, topPos;
      if (!VerticalSwipeCard.__super__.touchmove.call(this, e)) {
        return;
      }
      if (this.currentState === state.TRACKING && this.moveMode === direction.VERTICAL) {
        cardHeight = this.el.height();
        percentAcross = (this.startCoords.y - this.currentPos.y) / cardHeight;
        topPos = $(window).height() * percentAcross;
        return this.el.css("-webkit-transform", "translate3d(0," + (0 - topPos) + "px,0)");
      }
    };

    VerticalSwipeCard.prototype.touchend = function(e) {
      var res;
      res = VerticalSwipeCard.__super__.touchend.call(this, e);
      if (!res) {
        return false;
      }
      if (this.moveMode === direction.VERTICAL) {
        console.log("gotmytouchend");
        this.el.css("-webkit-transform", "");
      }
      return res;
    };

    return VerticalSwipeCard;

  })(Card);

  RotateCard = (function(_super) {

    __extends(RotateCard, _super);

    function RotateCard() {
      this.postAnimate = __bind(this.postAnimate, this);

      this.delayedAnimateComplete = __bind(this.delayedAnimateComplete, this);

      this.touchend = __bind(this.touchend, this);

      this.touchmove = __bind(this.touchmove, this);

      this.touchstart = __bind(this.touchstart, this);
      return RotateCard.__super__.constructor.apply(this, arguments);
    }

    RotateCard.prototype.touchstart = function(e) {
      RotateCard.__super__.touchstart.call(this, e);
      this.backEl.css("display", "block");
      this.frontEl.off("webkitTransitionEnd", this.delayedAnimateComplete);
      return this.backEl.off("webkitTransitionEnd", this.delayedAnimateComplete);
    };

    RotateCard.prototype.touchmove = function(e) {
      var backAngle, cardWidth, frontAngle, multiplier;
      e.preventDefault();
      RotateCard.__super__.touchmove.call(this, e);
      if (this.currentState === state.TRACKING && this.moveMode === direction.HORIZONTAL) {
        cardWidth = this.el.width();
        this.percentAcross = (this.startCoords.x - this.currentPos.x) / cardWidth;
        multiplier = this.percentAcross < 0 ? -1 : 1;
        this.percentAcross = Math.abs(this.percentAcross);
        if (this.percentAcross <= 0.5) {
          frontAngle = -180 * this.percentAcross;
          if (frontAngle < -180) {
            frontAngle = -180;
          }
          frontAngle = frontAngle * multiplier;
          backAngle = 90 * multiplier;
        } else {
          frontAngle = -90 * multiplier;
          backAngle = ((-180 * this.percentAcross) + 180) * multiplier;
        }
        this.frontEl.css("-webkit-transform", "rotate3d(0,1,0," + frontAngle + "deg)");
        return this.backEl.css("-webkit-transform", "rotate3d(0,1,0," + backAngle + "deg)");
      }
    };

    RotateCard.prototype.touchend = function(e) {
      var cardWidth, percentLeftForFront, stats, timeForAllAtAccelerationRate, timeForFront;
      if (!RotateCard.__super__.touchend.call(this, e)) {
        return false;
      }
      console.log(this.moveMode);
      if (this.moveMode !== direction.HORIZONTAL) {
        return;
      }
      console.log("processing", this.moveMode, direction.HORIZONTAL);
      stats = RotateCard.__super__.touchend.call(this, e);
      cardWidth = this.el.width();
      timeForAllAtAccelerationRate = stats.time * (1 / this.percentAcross);
      if (stats.acceleration < 0.8 && this.percentAcross <= 0.5) {
        console.log(this.frontEl[0]);
        this.frontEl.addClass("animated");
        return this.frontEl.css("-webkit-transform", "rotate3d(0,1,0,0deg)");
      } else if (stats.acceleration < 0.8 || this.percentAcross > 0.5) {
        this.backEl.addClass("animated");
        this.backEl.css({
          "-webkit-transform": "rotate3d(0,1,0,0deg)"
        });
        return this.postAnimate();
      } else if (stats.acceleration >= 0.8) {
        console.log("going weird");
        percentLeftForFront = 0.5 - this.percentAcross;
        timeForFront = (timeForAllAtAccelerationRate * percentLeftForFront) / 1000;
        this.timeForBack = (timeForAllAtAccelerationRate * 0.5) / 1000;
        this.frontEl.on("webkitTransitionEnd", this.delayedAnimateComplete);
        this.frontEl.addClass("animated");
        return this.frontEl.css({
          "-webkit-transition-duration": "" + timeForFront + "s",
          "-webkit-transform": "rotate3d(0,1,0,90deg)"
        });
      }
    };

    RotateCard.prototype.delayedAnimateComplete = function() {
      this.frontEl.off("webkitTransitionEnd", this.delayedAnimateComplete);
      this.backEl.addClass("animated");
      this.backEl.css({
        "-webkit-transition-duration": "" + this.timeForBack + "s",
        "-webkit-transform": "rotate3d(0,1,0,0deg)"
      });
      return this.postAnimate();
    };

    RotateCard.prototype.postAnimate = function() {
      var newBack;
      console.log("switching");
      newBack = this.frontEl;
      this.frontEl = this.backEl;
      this.backEl = newBack;
      return this.backEl.css("display", "none");
    };

    return RotateCard;

  })(VerticalSwipeCard);

  $(document).on("touchmove", function(e) {
    return e.preventDefault();
  });

  $(document).on("touchstart", function(e) {
    return e.preventDefault();
  });

  $(document).on("scroll", function() {
    return console.log("scrolly");
  });

  new RotateCard($(".glasspane"));

}).call(this);
