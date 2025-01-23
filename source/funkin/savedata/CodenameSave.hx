package funkin.savedata;

import flixel.util.FlxSignal.FlxTypedSignal;
import binserializer.Serializer as BinSerializer;
import binserializer.Unserializer as BinUnserializer;
import openfl.filesystem.File;
import funkin.backend.assets.ModsFolder;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import openfl.errors.Error;
import openfl.net.SharedObject;
import openfl.net.SharedObjectFlushStatus;
import flixel.util.FlxSave;

class CodenameSave extends FlxSave
{
	/**
	 * Called when the unserialization fails
	 */
	public static var onFailedToLoad:FlxTypedSignal<(name:String, path:String) -> Void> = new FlxTypedSignal();

	public function new()
	{
		super();
	}

	/**
	 * Automatically creates or reconnects to locally saved data.
	 *
	 * @param   name  The name of the save (should be the same each time to access old data).
	 *                May not contain spaces or any of the following characters:
	 *                `~ % & \ ; : " ' , < > ? #`
	 * @param   path  The full or partial path to the file that created the shared object.
	 *                Mainly used to differentiate from other FlxSaves. The default will be used `CodenameCrew/CodenameEngine`.
	 * @return  Whether or not you successfully connected to the save data.
	 */
	public override function bind(name:String, ?path:String):Bool
	{
		var currentModFolder = ModsFolder.currentModFolder;
		var modName = currentModFolder != null ? currentModFolder : Flags.DEFAULT_MODS_SAVE_FOLDER;

		return _bind(modName + "/" + name, path);
	}

	@:dox(hide)
	public function bindGlobal(name:String, ?path:String):Bool
	{
		return _bind(name, path);
	}

	private function _bind(name:String, ?path:String):Bool
	{
		destroy();

		name = FlxSave.validateAndWarn(name, "name");
		if (path != null)
			path = FlxSave.validateAndWarn(path, "path");

		try
		{
			try
			{
				_sharedObject = CodenameSharedObject.getLocal(name, path);
				status = BOUND(name, path);
			}
			catch (e:InvalidFormatError)
			{
				_sharedObject = FlxSharedObject.getLocal(name, path);
				status = BOUND(name, path);
			}
		}
		catch (e:Error)
		{
			Logs.trace('[CodenameSave] Error: Failed to bind: "$name", path:"$path" (${e.message}).', ERROR);
			FlxG.log.error('Error:${e.message} name:"$name", path:"$path".');
			destroy();
			return false;
		}
		data = _sharedObject.data;
		return true;
	}

	/**
	 * Creates a new FlxSave and copies the data from old to new,
	 * flushes the new save (if changed) and then optionally erases the old save.
	 *
	 * @param   name         The name of the save.
	 * @param   path         The full or partial path to the file that created the save.
	 * @param   overwrite    Whether the data should overwrite, should the 2 saves share data fields. defaults to false.
	 * @param   eraseSave    Whether to erase the save after successfully migrating the data. defaults to true.
	 * @param   minFileSize  If you need X amount of space for your save, specify it here.
	 * @return  Whether or not you successfully found, merged and flushed data.
	 */
	public override function mergeDataFrom(name:String, ?path:String, overwrite = false, eraseSave = true, minFileSize = 0):Bool
	{
		if (!checkStatus())
			return false;

		final oldSave = new CodenameSave();
		// check old save location
		if (oldSave.bind(name, path))
		{
			final success = mergeData(oldSave.data, overwrite, minFileSize);

			if (eraseSave)
				oldSave.erase();
			oldSave.destroy();

			// save changes, if there are any
			return success;
		}

		oldSave.destroy();

		return false;
	}

	public override function flush(minFileSize:Int = 0):Bool
	{
		if (!checkStatus())
			return false;

		try
		{
			var result = _sharedObject.flush(minFileSize);

			if (result != FLUSHED)
				status = ERROR("CodenameSave is requesting extra storage space.");
		}
		catch (e:Error)
		{
			status = ERROR("There was an problem saving the save data.");
		}

		checkStatus();

		return isBound;
	}

	override function checkStatus():Bool
	{
		switch (status)
		{
			case EMPTY:
				FlxG.log.warn("You must call CodenameSave.bind() before you can read or write data.");
			case ERROR(msg):
				FlxG.log.error(msg);
			default:
				return true;
		}
		return false;
	}
}

@:access(openfl.net.SharedObject)
@:access(flixel.util.FlxSave)
class CodenameSharedObject extends SharedObject implements IDisposable
{
	static var all:Map<String, CodenameSharedObject>;

	var allId:String;

	public static function getSaves():Map<String, CodenameSharedObject>
	{
		var allSaves:Map<String, CodenameSharedObject> = new Map();
		for (id => saveObject in all) {
			if (!["/controls", "/contributors", "/options"].contains(id)) {
				allSaves.set(id, saveObject);
			}
		}
		return allSaves;
	}

	static function init()
	{
		if (all == null)
		{
			all = new Map();

			var app = lime.app.Application.current;
			if (app != null)
				app.onExit.add(onExit);
		}
	}

	public function dispose()
	{
		if (all != null && all.exists(allId))
			all.remove(allId);
	}

	static function onExit(_)
	{
		for (sharedObject in all)
			sharedObject.flush();
	}

	/**
	 * Make it return the Mods folder name
	 */
	static function getModsFolderName()
	{
		var currentModFolder = ModsFolder.currentModFolder;
		var path = currentModFolder != null ? currentModFolder : Flags.DEFAULT_MODS_SAVE_FOLDER;

		return FlxSave.validate(path);
	}

	/**
	 * Returns the company name listed in the Project.xml
	 */
	static function getDefaultLocalPath()
	{
		return FlxSave.validate(Flags.SAVEDATA_FOLDER);
	}

	public static function makeEmptySharedObject(name:String, localPath:String):CodenameSharedObject
	{
		final sharedObject = new CodenameSharedObject();
		sharedObject.data = {};
		sharedObject.__localPath = localPath;
		sharedObject.__name = name;

		return sharedObject;
	}

	static dynamic function getResolver():Dynamic
	{
		return {resolveEnum: Type.resolveEnum, resolveClass: SharedObject.__resolveClass};
	}

	public static function parseV1(name:String, localPath:String, encodedData:haxe.io.Bytes):CodenameSharedObject
	{
		final sharedObject = new CodenameSharedObject();
		sharedObject.data = {};
		sharedObject.__localPath = localPath;
		sharedObject.__name = name;

		try
		{
			final unserializer = new BinUnserializer(encodedData);
			unserializer.setResolver(getResolver());
			sharedObject.data = unserializer.unserialize();
		}
		catch (e:Dynamic)
		{
		}

		return sharedObject;
	}

	// Saves to like %APPDATA%/CodenameCrew/CodenameEngine/my-mod/highscores.2025-01-01_00-00-00.bak to avoid overwriting
	private static function backup(name:String, localPath:String, encodedData:haxe.io.Bytes):String
	{
		final now = Date.now();
		final path = getPath(localPath, name, "");
		final backupName = '${path}.${DateTools.format(now, "%Y-%m-%d_%H-%M-%S")}.bak';
		#if !(js && html5)
		try
			sys.FileSystem.rename(path, backupName)
		catch (e)
			Logs.trace('[CodenameSave] Error: Failed to backup: "$name", path:"$path" (${e.message}).', ERROR);
		#else
		final storage = js.Browser.getLocalStorage();
		if (storage != null)
			storage.setItem(backupName, encodedData);
		#end

		return backupName;
	}

	public static function getLocal(name:String, ?localPath:String):SharedObject
	{
		if (name == null || name == "")
			throw new Error('Error: Invalid name:"$name".');

		if (localPath == null)
			localPath = "";

		var id = localPath + "/" + name;

		init();

		if (!all.exists(id))
		{
			var encodedData = null;

			if (~/(?:^|\/)\.\.\//.match(localPath))
			{
				// Stripping the ../ from the path
				throw new Error("../ not allowed in localPath");
			}

			try
			{
				encodedData = getBytesData(name, localPath);
			}
			catch (e:Dynamic)
			{
			}

			var sharedObject:CodenameSharedObject = null;

			// since goto doesn't exist
			while (true)
			{
				if (encodedData == null || encodedData.length == 0)
				{
					sharedObject = makeEmptySharedObject(name, localPath);
					break;
				}

				if (encodedData.getString(0, 10) == "CNESAVEv1:")
				{
					sharedObject = parseV1(name, localPath, encodedData.sub(10, encodedData.length - 10));
					if (sharedObject == null)
					{
						var backupName = backup(name, localPath, encodedData);
						CodenameSave.onFailedToLoad.dispatch(name, getPath(localPath, name));

						// Make a empty save file
						sharedObject = makeEmptySharedObject(name, localPath);
					}
					break;
				}

				break;
			}

			if (sharedObject == null)
				throw new InvalidFormatError("Not a Codename Engine save file.");

			sharedObject.allId = id;
			all.set(id, sharedObject);
		}

		return all.get(id);
	}

	// Web has data stored as base64 since it's not possible to store binary data in localStorage
	#if (js && html5)
	static function getBytesData(name:String, ?localPath:String, ext:String = ".cns")
	{
		final storage = js.Browser.getLocalStorage();
		if (storage == null)
			return null;

		function get(path:String)
		{
			var res = storage.getItem(path + ":" + name);
			if (res == null)
				return null;
			if (!res.startsWith("CNESAVEv1:"))
				return res;
			res = res.substr("CNESAVEv1:".length);
			return haxe.crypto.Base64.decode(res);
		}

		// do not check for legacy saves when path is provided
		if (localPath != "")
			return get(localPath);

		var encodedData:String;
		// check default localPath
		encodedData = get(getDefaultLocalPath());
		if (encodedData != null)
			return encodedData;

		// check pre-5.0.0 default local path
		return get(js.Browser.window.location.pathname);
	}

	public static function exists(name:String, ?localPath:String, ext:String = ".cns")
	{
		final storage = js.Browser.getLocalStorage();

		if (storage == null)
			return false;

		inline function has(path:String)
		{
			return storage.getItem(path + ":" + name) != null;
		}

		return has(localPath) || has(getDefaultLocalPath()) || has(js.Browser.window.location.pathname);
	}

	// should include every sys target
	#else
	static function getBytesData(name:String, ?localPath:String, ext:String = ".cns")
	{
		var path = getPath(localPath, name, ext);
		if (sys.FileSystem.exists(path))
			return sys.io.File.getBytes(path);

		return null;
	}

	static function getPath(localPath:String, name:String, ext:String = ".cns"):String
	{
		// Avoid ever putting .sol files directly in AppData
		if (localPath == "")
			localPath = getDefaultLocalPath();

		var directory = lime.system.System.applicationStorageDirectory;
		var path = haxe.io.Path.normalize('$directory/../../../$localPath') + "/";

		name = StringTools.replace(name, "//", "/");
		name = StringTools.replace(name, "//", "/");

		if (StringTools.startsWith(name, "/"))
		{
			name = name.substr(1);
		}

		if (StringTools.endsWith(name, "/"))
		{
			name = name.substring(0, name.length - 1);
		}

		// Don't add the # automatically
		/*if (name.indexOf("/") > -1)
		{
			var split = name.split("/");
			name = "";

			for (i in 0...(split.length - 1))
			{
				name += "#" + split[i] + "/";
			}

			name += split[split.length - 1];
		}*/

		return path + name + ext;
	}

	/**
	 * Whether the save exists.
	 */
	public static inline function exists(name:String, ?localPath:String, ext:String = ".cns")
	{
		return sys.FileSystem.exists(getPath(localPath, name, ext));
	}

	override function flush(minDiskSpace:Int = 0)
	{
		if (Reflect.fields(data).length == 0)
		{
			return SharedObjectFlushStatus.FLUSHED;
		}

		var encodedData = BinSerializer.run(data);

		try
		{
			var path = getPath(__localPath, __name);
			var directory = haxe.io.Path.directory(path);

			if (!sys.FileSystem.exists(directory))
				SharedObject.__mkdir(directory);

			trace('Writing to ${path}...');
			trace("Size: " + encodedData.length);
			var output = sys.io.File.write(path, true);
			output.writeString("CNESAVEv1:");
			output.write(encodedData);
			output.close();
		}
		catch (e:Dynamic)
		{
			return SharedObjectFlushStatus.PENDING;
		}

		return SharedObjectFlushStatus.FLUSHED;
	}

	override function clear()
	{
		data = {};

		try
		{
			var path = getPath(__localPath, __name);

			if (sys.FileSystem.exists(path))
				sys.FileSystem.deleteFile(path);
		}
		catch (e:Dynamic)
		{
		}
	}
	#end
}

class InvalidFormatError extends Error
{
	public function new(message:String)
	{
		super(message);
	}
}
