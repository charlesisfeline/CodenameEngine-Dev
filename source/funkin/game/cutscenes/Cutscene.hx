package funkin.game.cutscenes;

import funkin.menus.PauseSubState;

/**
 * Substate made for cutscenes.
 */
class Cutscene extends MusicBeatSubstate {
	var __callback:Void->Void;
	var __pausable:Bool;
	var game:PlayState = PlayState.instance;

	public var pauseItems:Array<String>;
	public var skippable(default, set):Bool;

	public function set_skippable(val:Bool):Bool {
		if(!val) pauseItems.remove('Skip Cutscene');
		else if(!pauseItems.contains('Skip Cutscene')) pauseItems.insert(1, 'Skip Cutscene');
		return skippable = val;
	}

	public function new(callback:Void->Void, allowPause:Bool = true, canSkip:Bool = true) {
		super();
		__callback = callback;
		__pausable = allowPause;

		pauseItems = Constants.DEFAULT_CUTSCENE_PAUSE_ITEMS;
		skippable = canSkip;
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		if (controls.PAUSE && __pausable) pauseCutscene();
	}

	var _before:Array<Bool> = [false, true];
	public function pauseCutscene() {
		_before = [game.persistentUpdate, game.persistentDraw];
		game.persistentUpdate = persistentUpdate = false;
		game.persistentDraw = persistentDraw = true;
		openSubState(new PauseSubState(pauseItems, selectPauseOption));
	}

	public function onSkipCutscene() close();
	public function onRestartCutscene() game.resetSubState();

	public function selectPauseOption(name:String):Bool {
		switch(name) {
			case 'Skip Cutscene': onSkipCutscene();
			case 'Restart Cutscene': onRestartCutscene();
			case 'Resume':
				game.persistentUpdate = _before[0];
				game.persistentDraw = _before[1];
		}

		return true;
	}

	public override function close() {
		__callback();
		super.close();
	}
}