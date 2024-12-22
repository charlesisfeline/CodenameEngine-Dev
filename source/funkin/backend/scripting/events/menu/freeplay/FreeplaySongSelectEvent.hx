package funkin.backend.scripting.events;

import funkin.menus.FreeplayState.FreeplayGameMode;

final class FreeplaySongSelectEvent extends CancellableEvent {
	/**
	 * Song name that is about to be played
	 */
	public var song:String;
	/**
	 * Difficulty name
	 */
	public var difficulty:String;
	/**
	 * Used game mode's data.
	 */
	public var gameMode:FreeplayGameMode;


	// Backwards compat
	@:noCompletion public var opponentMode(get, set):Bool;
	@:noCompletion private function get_opponentMode() return gameMode.modeID == "codename.opponent";
	@:noCompletion private function set_opponentMode(val:Bool) {
		if (val != opponentMode) {  // brb imma resume from here next time  - Nex
			if (coopMode) gameMode = val ? : new FreeplayGameMode("Opponent Mode", "codename.opponent", ["opponent"]) : null;
		}
		return opponentMode = val;
	}
	@:noCompletion public var coopMode(get, set):Bool;
	@:noCompletion private function get_coopMode() return gameMode.modeID == "codename.coop" || gameMode.modeID == "codename.coop-opponent";
	@:noCompletion private function set_coopMode(val:Bool) {
		if (val == coopMode) return val;
		return val ? new FreeplayGameMode("Opponent Mode", "codename.coop", ["coop"]) : gameMode = null;
	}
}