// Took the one inside the BaseGame source as a base  - Nex
var pupilState:Int = 0;

var PUPIL_STATE_NORMAL = 0;
var PUPIL_STATE_LEFT = 1;

var abot:FunkinSprite;
//var abotViz:ABotVis;
var stereoBG:FlxSprite;
var eyeWhites:FlxSprite;
var pupil:FunkinSprite;

var animationFinished:Bool = false;

function postCreate() {
	stereoBG = new FlxSprite(0, 0, Paths.image('characters/abot/stereoBG'));
	eyeWhites = new FunkinSprite().makeSolid(160, 60);
	pupil = new FunkinSprite(0, 0, Paths.image("characters/abot/systemEyes"));
	abot = new FunkinSprite(0, 0, Paths.image('characters/abot/abotSystem'));
	stereoBG.antialiasing = eyeWhites.antialiasing = pupil.antialiasing = abot.antialiasing = true;

	animation.finishCallback = function (name:String) {
		switch(currentState) {
			case STATE_RAISE:
				if (name == "raiseKnife") {
					animationFinished = true;
					transitionState();
				}
			case STATE_LOWER:
				if (name == "lowerKnife") {
					animationFinished = true;
					transitionState();
				}
			default:
				// Ignore.
		}
	}

	animation.callback = function (name:String, frameNumber:Int, frameIndex:Int) {
		switch(currentState) {
			case STATE_PRE_RAISE:
				if (name == "danceLeft" && frameNumber == 14) {
					animationFinished = true;
					transitionState();
				}
			default:
				// Ignore.
		}
	}

	/*abotViz = new ABotVis(FlxG.sound.music);
	abotViz.x = this.x;
	abotViz.y = this.y;
	abotViz.zIndex = abot.zIndex + 1;
	FlxG.debugger.track(abotViz);*/
}

/**
 * At this amount of life, Nene will raise her knife.
 */
var VULTURE_THRESHOLD = 0.25 * 2;

/**
 * Nene is in her default state. 'danceLeft' or 'danceRight' may be playing right now,
 * or maybe her 'combo' or 'drop' animations are active.
 *
 * Transitions:
 * If player health <= VULTURE_THRESHOLD, transition to STATE_PRE_RAISE.
 */
var STATE_DEFAULT = 0;

/**
 * Nene has recognized the player is at low health,
 * but has to wait for the appropriate point in the animation to move on.
 *
 * Transitions:
 * If player health > VULTURE_THRESHOLD, transition back to STATE_DEFAULT without changing animation.
 * If current animation is combo or drop, transition when animation completes.
 * If current animation is danceLeft, wait until frame 14 to transition to STATE_RAISE.
 * If current animation is danceRight, wait until danceLeft starts.
 */
var STATE_PRE_RAISE = 1;

/**
 * Nene is raising her knife.
 * When moving to this state, immediately play the 'raiseKnife' animation.
 *
 * Transitions:
 * Once 'raiseKnife' animation completes, transition to STATE_READY.
 */
var STATE_RAISE = 2;

/**
 * Nene is holding her knife ready to strike.
 * During this state, hold the animation on the first frame, and play it at random intervals.
 * This makes the blink look less periodic.
 *
 * Transitions:
 * If the player runs out of health, move to the GameOverSubState. No transition needed.
 * If player health > VULTURE_THRESHOLD, transition to STATE_LOWER.
 */
var STATE_READY = 3;

/**
 * Nene is raising her knife.
 * When moving to this state, immediately play the 'lowerKnife' animation.
 *
 * Transitions:
 * Once 'lowerKnife' animation completes, transition to STATE_DEFAULT.
 */
var STATE_LOWER = 4;

/**
 * Nene's animations are tracked in a simple state machine.
 * Given the current state and an incoming event, the state changes.
 */
var currentState:Int = STATE_DEFAULT;

/**
 * Nene blinks every X beats, with X being randomly generated each time.
 * This keeps the animation from looking too periodic.
 */
var MIN_BLINK_DELAY:Int = 3;
var MAX_BLINK_DELAY:Int = 7;
var blinkCountdown:Int = MIN_BLINK_DELAY;

function onDance(event) {
	//abot.playAnim("", forceRestart);

	// Then, perform the appropriate animation for the current state.
	switch(currentState) {
		case STATE_PRE_RAISE: event.danced = true;
		case STATE_READY:
			if (blinkCountdown == 0) {
				playAnim('idleKnife', false, PlayAnimContext.LOCK);
				blinkCountdown = FlxG.random.int(MIN_BLINK_DELAY, MAX_BLINK_DELAY);
			} else {
				blinkCountdown--;
			}
		default:
			// In other states, don't interrupt the existing animation.
	}
}

function movePupilsLeft() {
	if (pupilState == PUPIL_STATE_LEFT) return;
	trace("left");
	pupil.playAnim('');
	pupil.globalCurFrame = 0;
	pupilState = PUPIL_STATE_LEFT;
}

function movePupilsRight() {
	if (pupilState == PUPIL_STATE_NORMAL) return;
	trace("right");
	pupil.playAnim('');
	pupil.globalCurFrame = 17;
	pupilState = PUPIL_STATE_NORMAL;
}

function moveByNoteKind(kind:String) {
	// Force ABot to look where the action is happening.
	switch(event.note.kind) {
		case "weekend-1-lightcan":
			movePupilsLeft();
		case "weekend-1-kickcan":
			// movePupilsLeft();
		case "weekend-1-kneecan":
			// movePupilsLeft();
		case "weekend-1-cockgun":
			movePupilsRight();
		case "weekend-1-firegun":
			// movePupilsRight();
		default: // Nothing
	}
}

function onNoteHit(event:HitNoteScriptEvent)
{
	super.onNoteHit(event);
	moveByNoteKind(event.note.kind);
}

function onNoteMiss(event:NoteScriptEvent)
{
	super.onNoteMiss(event);
	moveByNoteKind(event.note.kind);
}

function draw(_) {
	stereoBG.draw();
	eyeWhites.draw();
	pupil.draw();
	abot.draw();
}

var __firstTime:Bool = true;
function update(elapsed) {
	// Set the visibility of ABot to match Nene's.
	abot.visible = this.visible;
	pupil.visible = this.visible;
	eyeWhites.visible = this.visible;
	stereoBG.visible = this.visible;

	var right:Bool = PlayState.instance.camFollow.x > this.getCameraPosition().x;
	if (__firstTime) {
		__firstTime = false;
		pupilState = right ? PUPIL_STATE_NORMAL : PUPIL_STATE_LEFT ;
	}

	if (right) movePupilsRight();
	else movePupilsLeft();

	if (!pupil.isAnimFinished())
	{
		switch (pupilState)
		{
			case PUPIL_STATE_NORMAL:
				if (pupil.globalCurFrame >= 17)
				{
					pupil.stopAnimation();
				}

			case PUPIL_STATE_LEFT:
				if (pupil.globalCurFrame >= 31)
				{
					pupil.stopAnimation();
				}

		}
	}

	abot.update(elapsed);
	abot.x = this.x - 100;
	abot.y = this.y + 316; // 764 - 740

	/*abotViz.x = this.x + 100;
	abotViz.y = this.y + 400;
	*/

	eyeWhites.update(elapsed);
	eyeWhites.x = abot.x + 40;
	eyeWhites.y = abot.y + 250;

	pupil.update(elapsed);
	pupil.x = this.x - 607;
	pupil.y = this.y - 176;

	stereoBG.update(elapsed);
	stereoBG.x = abot.x + 150;
	stereoBG.y = abot.y + 30;

	if (shouldTransitionState()) {
		transitionState();
	}
}

/*public function onScriptEvent(event:ScriptEvent):Void {
	if (event.type == "SONG_START")
	{
		abotViz.snd = FlxG.sound.music;
		abotViz.initAnalyzer();
	}
}*/

function shouldTransitionState():Bool {
	return PlayState.instance.boyfriend?.curCharacter != "pico-blazin";
}

function transitionState() {
	switch (currentState) {
		case STATE_DEFAULT:
			if (PlayState.instance.health <= VULTURE_THRESHOLD) {
				// trace('NENE: Health is low, transitioning to STATE_PRE_RAISE');
				currentState = STATE_PRE_RAISE;
			} else {
				currentState = STATE_DEFAULT;
			}
		case STATE_PRE_RAISE:
			if (PlayState.instance.health > VULTURE_THRESHOLD) {
				// trace('NENE: Health went back up, transitioning to STATE_DEFAULT');
				currentState = STATE_DEFAULT;
			} else if (animationFinished) {
				// trace('NENE: Animation finished, transitioning to STATE_RAISE');
				currentState = STATE_RAISE;
				playAnim('raiseKnife');
				animationFinished = false;
			}
		case STATE_RAISE:
			if (animationFinished) {
				// trace('NENE: Animation finished, transitioning to STATE_READY');
				currentState = STATE_READY;
				animationFinished = false;
			}
		case STATE_READY:
			if (PlayState.instance.health > VULTURE_THRESHOLD) {
				// trace('NENE: Health went back up, transitioning to STATE_LOWER');
				currentState = STATE_LOWER;
				playAnim('lowerKnife');
			}
		case STATE_LOWER:
			if (animationFinished) {
				// trace('NENE: Animation finished, transitioning to STATE_DEFAULT');
				currentState = STATE_DEFAULT;
				animationFinished = false;
			}
		default:
			// trace('UKNOWN STATE ' + currentState);
			currentState = STATE_DEFAULT;
	}
}
