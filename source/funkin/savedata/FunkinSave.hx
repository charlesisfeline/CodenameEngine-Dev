package funkin.savedata;

import flixel.util.FlxSave;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.menus.FreeplayState.FreeplayGameMode;
import openfl.Lib;

/**
 * The stuff here is saved in the mod save folder.
 *
 * Class used for saves WITHOUT going through the struggle of type checks
 * Just add your save variables the way you would do in the Options.hx file.
 * The macro will automatically generate the `flush` and `load` functions.
 */
@:build(funkin.backend.system.macros.FunkinSaveMacro.build(null, "flush", "load"))
class FunkinSave {
	@:saveField(highscoreSave)
	public static var highscores:Array<Highscore> = [];  // enums unfortunately are extremely buggy on saves, typedefs are the best solution  - Nex

	/**
	 * ONLY OPEN IF YOU WANT TO EDIT FUNCTIONS RELATED TO SAVING, LOADING OR HIGHSCORES.
	 */
	#if REGION
	@:dox(hide) @:doNotSave
	private static var __eventAdded = false;
	@:doNotSave
	public static var highscoreSave:CodenameSave;

	/**
	 * INTERNAL - Only use when editing source mods!!
	 */
	@:dox(hide) @:doNotSave
	public static var onReloadSave:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

	public static function init() {
		if (!__eventAdded) {
			onReloadSave.add(function() {
				if (highscoreSave != null && highscoreSave.isBound) highscoreSave.close();
				highscoreSave = new CodenameSave();
				highscoreSave.bind('highscores');
				highscoreSave.autoSave = false;  // cuz autoSave doesnt update the fields, so we do it manually  - Nex

				load();
			});

			Lib.application.onExit.add((_) -> {
				trace('Saving mod save data...');
				flush();
			});

			__eventAdded = true;
		}
	}

	public static function reloadSaves() {
		#if FLX_DEBUG
		@:privateAccess
		if (flixel.system.debug.FlxDebugger.save == null)
			flixel.system.debug.FlxDebugger.save = {
				var save = new CodenameSave();
				save.bindGlobal("debug");
				save;
			}
		#end

		if (FlxG.save.isBound) FlxG.save.close(); // calls flush
		@:privateAccess FlxG.save = new CodenameSave();
		FlxG.save.bind("data");

		onReloadSave.dispatch();
	}

	/**
	 * Returns the high-score for a song.
	 * @param name Song name
	 * @param diff Song difficulty
	 * @param changes Changes made to that song in freeplay.
	 */
	public static inline function getSongHighscore(name:String, diff:String, ?gameMode:HighscoreGameMode) {
		if (gameMode == null) {
			var temp = FreeplayGameMode.generateDefault();
			gameMode = {modeID: temp.modeID, fields: temp.fields};
		}

		return safeGetHighscore({name: name.toLowerCase(), difficulty: diff.toLowerCase(), type: "codename.song", gameMode: gameMode}).data;
	}

	public static inline function setSongHighscore(name:String, diff:String, highscore:HighscoreData, ?gameMode:HighscoreGameMode) {
		if (gameMode == null) {
			var temp = FreeplayGameMode.generateDefault();
			gameMode = {modeID: temp.modeID, fields: temp.fields};
		}

		if (safeRegisterHighscore({name: name.toLowerCase(), difficulty: diff.toLowerCase(), type: "codename.song", gameMode: gameMode}, highscore)) {
			flush();
			return true;
		}
		return false;
	}

	public static inline function getWeekHighscore(name:String, diff:String)
		return safeGetHighscore({name: name.toLowerCase(), difficulty: diff.toLowerCase(), type: "codename.week"}).data;

	public static inline function setWeekHighscore(name:String, diff:String, highscore:HighscoreData) {
		if (safeRegisterHighscore({name: name.toLowerCase(), difficulty: diff.toLowerCase(), type: "codename.week"}, highscore)) {
			flush();
			return true;
		}
		return false;
	}

	private static function safeGetHighscore(entry:HighscoreEntry):Highscore {
		for (highscore in highscores) {
			var stored = highscore.entry;
			if (stored.name == entry.name && stored.difficulty == entry.difficulty && stored.type == entry.type &&
				((stored.gameMode == null && entry.gameMode == null) || (stored.gameMode.modeID == entry.gameMode.modeID
				/*&& stored.gameMode.fields == entry.gameMode.fields*/)))  // cant really do differently because of typedefs  - Nex
				return highscore;
		}

		return {
			entry: entry,
			data: {
				score: 0,
				accuracy: 0,
				misses: 0,
				date: null
			}
		};
	}

	private static function safeRegisterHighscore(entry:HighscoreEntry, data:HighscoreData) {
		var oldHigh = safeGetHighscore(entry);
		if (oldHigh.data.date == null || oldHigh.data.score < data.score) {
			highscores.remove(oldHigh);
			highscores.push({entry: entry, data: data});
			return true;
		}
		return false;
	}
	#end

	// Backwards compat
	@:dox(hide) @:doNotSave
	public static var save(get, never):FlxSave;
	private static function get_save() return FlxG.save;
}

typedef Highscore = {
	var entry:HighscoreEntry;
	var data:HighscoreData;
}

typedef HighscoreEntry = {
	var name:String;
	var difficulty:String;
	var type:String;  // mods can also customize this btw, example: codename.week or codename.song  - Nex
	var ?gameMode:HighscoreGameMode;
}

typedef HighscoreGameMode = {
	var modeID:String;
	var ?fields:Dynamic;
}

typedef HighscoreData = {
	var score:Int;
	var accuracy:Float;
	var misses:Int;
	var date:Date;
}