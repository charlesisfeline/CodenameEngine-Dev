package funkin.options;

import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;
import funkin.savedata.CodenameSave;
import openfl.Lib;

/**
 * The save data of the engine.
 * Mod save data is stored in `FlxG.save.data`.
**/
@:build(funkin.backend.system.macros.OptionsMacro.build())
@:build(funkin.backend.system.macros.FunkinSaveMacro.build("__save", "__flush", "__load"))
class Options
{
	@:dox(hide) @:doNotSave
	public static var __save:CodenameSave;
	@:dox(hide) @:doNotSave
	public static var __contributorsSave:CodenameSave;
	@:dox(hide) @:doNotSave
	public static var __controlsSave:CodenameSave;
	@:dox(hide) @:doNotSave
	private static var __eventAdded = false;

	/**
	 * SETTINGS
	 */
	public static var naughtyness:Bool = true;
	public static var downscroll:Bool = false;
	public static var ghostTapping:Bool = true;
	public static var flashingMenu:Bool = true;
	public static var camZoomOnBeat:Bool = true;
	public static var fpsCounter:Bool = true;
	public static var autoPause:Bool = true;
	public static var antialiasing:Bool = true;
	public static var volume:Float = 1;
	public static var mute:Bool = false;
	public static var week6PixelPerfect:Bool = true;
	public static var gameplayShaders:Bool = true;
	public static var colorHealthBar:Bool = true;
	public static var lowMemoryMode:Bool = false;
	public static var betaUpdates:Bool = false;
	public static var splashesEnabled:Bool = true;
	public static var hitWindow:Float = 250;
	public static var songOffset:Float = 0;
	public static var framerate:Int = 120;
	public static var gpuOnlyBitmaps:Bool = #if (mac || web) false #else true #end; // causes issues on mac and web

	public static var lastLoadedMod:String = null;

	/**
	 * EDITORS SETTINGS
	 */
	public static var intensiveBlur:Bool = true;
	public static var editorSFX:Bool = true;
	public static var editorPrettyPrint:Bool = false;
	public static var maxUndos:Int = 120;

	/**
	 * QOL FEATURES
	 */
	public static var mainmenuLastMenu:String = null;
	public static var storymodeLastWeek:String = null;
	public static var storymodeLastDifficulty:String = null;
	public static var freeplayLastSong:String = null;
	public static var freeplayLastDifficulty:String = null;
	public static var freeplayLastGameMode:String = null;

	/**
	 * CONTRIBUTORS
	**/
	@:saveField(__contributorsSave) public static var contributors:Array<funkin.backend.system.github.GitHubContributor.CreditsGitHubContributor> = [];
	@:saveField(__contributorsSave) public static var mainDevs:Array<Int> = [];  // IDs
	@:saveField(__contributorsSave) public static var lastUpdated:Null<Float>;

	/**
	 * CHARTER
	 */
	public static var charterMetronomeEnabled:Bool = false;
	public static var charterShowSections:Bool = true;
	public static var charterShowBeats:Bool = true;
	public static var charterEnablePlaytestScripts:Bool = true;
	public static var charterLowDetailWaveforms:Bool = false;
	public static var charterAutoSaves:Bool = true;
	public static var charterAutoSaveTime:Float = 60*5;
	public static var charterAutoSaveWarningTime:Float = 5;
	public static var charterAutoSavesSeparateFolder:Bool = false;

	/**
	 * PLAYER 1 CONTROLS
	 */
	@:saveField(__controlsSave) public static var P1_NOTE_LEFT:Array<FlxKey> = [A];
	@:saveField(__controlsSave) public static var P1_NOTE_DOWN:Array<FlxKey> = [S];
	@:saveField(__controlsSave) public static var P1_NOTE_UP:Array<FlxKey> = [W];
	@:saveField(__controlsSave) public static var P1_NOTE_RIGHT:Array<FlxKey> = [D];
	@:saveField(__controlsSave) public static var P1_LEFT:Array<FlxKey> = [A];
	@:saveField(__controlsSave) public static var P1_DOWN:Array<FlxKey> = [S];
	@:saveField(__controlsSave) public static var P1_UP:Array<FlxKey> = [W];
	@:saveField(__controlsSave) public static var P1_RIGHT:Array<FlxKey> = [D];
	@:saveField(__controlsSave) public static var P1_ACCEPT:Array<FlxKey> = [ENTER];
	@:saveField(__controlsSave) public static var P1_BACK:Array<FlxKey> = [BACKSPACE];
	@:saveField(__controlsSave) public static var P1_PAUSE:Array<FlxKey> = [ENTER];
	@:saveField(__controlsSave) public static var P1_RESET:Array<FlxKey> = [R];
	@:saveField(__controlsSave) public static var P1_SWITCHMOD:Array<FlxKey> = [TAB];

	/**
	 * PLAYER 2 CONTROLS (ALT)
	 */
	@:saveField(__controlsSave) public static var P2_NOTE_LEFT:Array<FlxKey> = [LEFT];
	@:saveField(__controlsSave) public static var P2_NOTE_DOWN:Array<FlxKey> = [DOWN];
	@:saveField(__controlsSave) public static var P2_NOTE_UP:Array<FlxKey> = [UP];
	@:saveField(__controlsSave) public static var P2_NOTE_RIGHT:Array<FlxKey> = [RIGHT];
	@:saveField(__controlsSave) public static var P2_LEFT:Array<FlxKey> = [LEFT];
	@:saveField(__controlsSave) public static var P2_DOWN:Array<FlxKey> = [DOWN];
	@:saveField(__controlsSave) public static var P2_UP:Array<FlxKey> = [UP];
	@:saveField(__controlsSave) public static var P2_RIGHT:Array<FlxKey> = [RIGHT];
	@:saveField(__controlsSave) public static var P2_ACCEPT:Array<FlxKey> = [SPACE];
	@:saveField(__controlsSave) public static var P2_BACK:Array<FlxKey> = [ESCAPE];
	@:saveField(__controlsSave) public static var P2_PAUSE:Array<FlxKey> = [ESCAPE];
	@:saveField(__controlsSave) public static var P2_RESET:Array<FlxKey> = [];
	@:saveField(__controlsSave) public static var P2_SWITCHMOD:Array<FlxKey> = [];

	/**
	 * SOLO GETTERS, these are auto-generated and not saved.
	 */
	public static var SOLO_NOTE_LEFT(get, never):Array<FlxKey>;
	public static var SOLO_NOTE_DOWN(get, never):Array<FlxKey>;
	public static var SOLO_NOTE_UP(get, never):Array<FlxKey>;
	public static var SOLO_NOTE_RIGHT(get, never):Array<FlxKey>;
	public static var SOLO_LEFT(get, never):Array<FlxKey>;
	public static var SOLO_DOWN(get, never):Array<FlxKey>;
	public static var SOLO_UP(get, never):Array<FlxKey>;
	public static var SOLO_RIGHT(get, never):Array<FlxKey>;
	public static var SOLO_ACCEPT(get, never):Array<FlxKey>;
	public static var SOLO_BACK(get, never):Array<FlxKey>;
	public static var SOLO_PAUSE(get, never):Array<FlxKey>;
	public static var SOLO_RESET(get, never):Array<FlxKey>;
	public static var SOLO_SWITCHMOD(get, never):Array<FlxKey>;

	private static function bindSave(save:CodenameSave, name:String) {
		if(save == null) save = new CodenameSave();
		save.bindGlobal(name);
		return save;
	}

	public static function load() {
		__save = bindSave(__save, "options");
		__contributorsSave = bindSave(__contributorsSave, "contributors");
		__controlsSave = bindSave(__controlsSave, "controls");
		__load();

		if (!__eventAdded) {
			Lib.application.onExit.add(function(i:Int) {
				trace("Saving settings...");
				save();
			});
			__eventAdded = true;
		}
		FlxG.sound.volume = volume;
		FlxG.sound.muted = mute;
		applySettings();
	}

	public static function applySettings() {
		applyKeybinds();
		FlxG.game.stage.quality = (FlxG.enableAntialiasing = antialiasing) ? LOW : BEST;
		FlxG.autoPause = autoPause;
		FlxG.drawFramerate = FlxG.updateFramerate = framerate;
	}

	public static function applyKeybinds() {
		PlayerSettings.solo.setKeyboardScheme(Solo);
		PlayerSettings.player1.setKeyboardScheme(Duo(true));
		PlayerSettings.player2.setKeyboardScheme(Duo(false));
	}

	public static function save() {
		volume = FlxG.sound.volume;
		mute = FlxG.sound.muted;
		__flush();
	}
}
