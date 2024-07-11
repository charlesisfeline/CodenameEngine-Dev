package funkin.backend.utils;

import funkin.backend.scripting.MultiThreadedScript;
import funkin.backend.scripting.Script;

class EngineUtil {
	/**
	 * Starts a new multithreaded script.
	 * This script will share all the variables with the current one, which means already existing callbacks will be replaced by new ones on conflict.
	 * @param path
	 */
	public static function startMultithreadedScript(path:String) {
		return new MultiThreadedScript(path, Script.curScript);
	}

	/**
	 * Returns the current time in milliseconds.
	**/
	public static function getTime():Float @:privateAccess {
		#if (kha && !macro)
		return kha.System.time * 1000;
		#elseif flash
		return flash.Lib.getTimer();
		#elseif ((js && !nodejs) || electron)
		return js.Browser.window.performance.now();
		//#elseif (lime_cffi && !macro)
		//return cast lime._internal.backend.native.NativeCFFI.lime_system_get_timer();
		#elseif cpp
		return untyped __global__.__time_stamp() * 1000;
		#elseif sys
		return Sys.time() * 1000;
		#else
		return 0.0;
		#end
	}
}