package funkin.backend.assets;

#if MOD_SUPPORT
import funkin.backend.utils.zip.ZipReader;
import haxe.io.Path;
import lime.graphics.Image;
import lime.media.AudioBuffer;
import lime.text.Font;
import lime.utils.AssetLibrary;
import lime.utils.Bytes;

class ZipFolderLibrary extends AssetLibrary implements IModsAssetLibrary {
	public var zipPath:String;
	public var modName:String;
	public var libName:String;
	public var useImageCache:Bool = false;
	public var prefix = 'assets/';

	public var zip:ZipReader;
	public var assets:Map<String, FileHeader> = [];
	public var lowerCaseAssets:Map<String, FileHeader> = [];
	public var nameMap:Map<String, String> = [];

	public function new(zipPath:String, libName:String, ?modName:String) {
		this.zipPath = zipPath;
		this.libName = libName;

		this.modName = modName == null ? libName : modName;

		zip = ZipReader.openFile(zipPath);
		var entries = zip.read();
		for(entry in entries) {
			var lowerCaseName = entry.fileName.toLowerCase();
			lowerCaseAssets[lowerCaseName] = assets[lowerCaseName] = assets[entry.fileName] = entry;
			nameMap.set(lowerCaseName, entry.fileName);
		}

		super();
	}

	public var _parsedAsset:String;

	public override function getAudioBuffer(id:String):AudioBuffer {
		if (!exists(id, "SOUND"))
			return null;
		return AudioBuffer.fromBytes(unzip(assets[_parsedAsset]));
	}
	public override function getBytes(id:String):Bytes {
		if (!exists(id, "BINARY"))
			return null;
		return Bytes.fromBytes(unzip(assets[_parsedAsset]));
	}
	public override function getFont(id:String):Font {
		if (!exists(id, "FONT"))
			return null;
		return ModsFolder.registerFont(Font.fromBytes(unzip(assets[_parsedAsset])));
	}
	public override function getImage(id:String):Image {
		if (!exists(id, "IMAGE"))
			return null;
		return Image.fromBytes(unzip(assets[_parsedAsset]));
	}

	public override function getPath(id:String):String {
		if (!__parseAsset(id)) return null;
		return getAssetPath();
	}


	public inline function unzip(f:FileHeader) {
		if(f == null) return null;
		var data = f.data;
		f.clearData(); // reduce memory usage
		return data;
	}

	public function __parseAsset(asset:String):Bool {
		if (!asset.startsWith(prefix)) return false;
		_parsedAsset = asset.substr(prefix.length);
		if(ModsFolder.useLibFile) {
			var file = new haxe.io.Path(_parsedAsset);
			if(file.file.startsWith("LIB_")) {
				var library = file.file.substr(4);
				if(library != modName) return false;

				_parsedAsset = file.dir + "." + file.ext;
			}
		}

		_parsedAsset = _parsedAsset.toLowerCase();
		if(nameMap.exists(_parsedAsset))
			_parsedAsset = nameMap.get(_parsedAsset);
		return true;
	}

	public function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocal:Bool = false) {
		if (cache.exists(isLocal ? '$libName:$asset': asset)) return true;
		return false;
	}

	public override function exists(asset:String, type:String):Bool {
		if(!__parseAsset(asset)) return false;

		return assets[_parsedAsset] != null;
	}

	private function getAssetPath() {
		trace('[ZIP]$zipPath/$_parsedAsset');
		return '[ZIP]$zipPath/$_parsedAsset';
	}

	// TODO: rewrite this to 1 function, like ModsFolderLibrary
	public function getFiles(folder:String):Array<String> {
		if (!folder.endsWith("/")) folder += "/";
		if (!__parseAsset(folder)) return [];

		var content:Array<String> = [];

		var checkPath = _parsedAsset.toLowerCase();

		@:privateAccess
		for(k=>e in lowerCaseAssets) {
			if (k.toLowerCase().startsWith(checkPath)) {
				if(nameMap.exists(k))
					k = nameMap.get(k);
				var fileName = k.substr(_parsedAsset.length);
				if (fileName.length > 0 && !fileName.contains("/"))
					content.pushOnce(fileName);
			}
		}
		return content;
	}

	public function getFolders(folder:String):Array<String> {
		if (!folder.endsWith("/")) folder += "/";
		if (!__parseAsset(folder)) return [];

		var content:Array<String> = [];

		var checkPath = _parsedAsset.toLowerCase();

		@:privateAccess
		for(k=>e in lowerCaseAssets) {
			if (k.toLowerCase().startsWith(checkPath)) {
				if(nameMap.exists(k))
					k = nameMap.get(k);
				var fileName = k.substr(_parsedAsset.length);
				if(fileName.length > 0) {
					var index = fileName.indexOf("/");
					if (index != -1) {
						var s = fileName.substr(0, index);
						content.pushOnce(s);
					}
				}
			}
		}
		return content;
	}
}
#end