package funkin.backend.utils;

import haxe.zip.Entry;
import haxe.zip.Reader;

#if sys
#if (!macro && sys)
import openfl.display.BitmapData;
#end

import haxe.Exception;
import haxe.Json;
import haxe.crypto.Crc32;
import haxe.zip.Compress;
import haxe.zip.Tools;
import haxe.zip.Uncompress;
import haxe.zip.Writer;
import sys.FileSystem;
import sys.io.File;
import sys.thread.Thread;
import flixel.util.typeLimit.OneOfTwo;
import funkin.backend.utils.zip.ZipReader;

using StringTools;

class ZipUtil {
	public static var bannedNames:Array<String> = [".git", ".gitignore", ".github", ".vscode", ".gitattributes", "readme.txt"];

	/**
	 * [Description] Decompresses a `zip` into the `destFolder` folder
	 * @param zip
	 * @param destFolder
	 */
	public static function uncompressZip(zip:ZipReader, destFolder:String, ?prefix:String, ?prog:ZipProgress):ZipProgress {
		// we never know
		FileSystem.createDirectory(destFolder);

		var fields = zip.read();

		try {
			if (prefix != null) {
				var f = fields;
				fields = new List<FileHeader>();
				for(field in f) {
					if (field.fileName.startsWith(prefix)) {
						fields.push(field);
					}
				}
			}

			if (prog == null)
				prog = new ZipProgress();
			prog.fileCount = fields.length;
			for(k=>field in fields) {
				prog.curFile = k;
				var isFolder = field.fileName.endsWith("/") && field.fileSize == 0;
				if (isFolder) {
					FileSystem.createDirectory('${destFolder}/${field.fileName}');
				} else {
					var split = [for(e in field.fileName.split("/")) e.trim()];
					split.pop();
					FileSystem.createDirectory('${destFolder}/${split.join("/")}');

					var data = unzip(field);
					File.saveBytes('${destFolder}/${field.fileName}', data);
				}
			}
			prog.curFile = fields.length;
			prog.done = true;
		} catch(e) {
			prog.done = true;
			prog.error = e;
		}
		return prog;
	}

	#if (!macro && sys)
	public static function uncompressZipAsync(zip:ZipReader, destFolder:String, ?prog:ZipProgress, ?prefix:String):ZipProgress {
		if (prog == null)
			prog = new ZipProgress();
		Thread.create(function() {
			uncompressZip(zip, destFolder, prefix, prog);
		});
		return prog;
	}
	#end

	/**
	 * [Description] Returns a `funkin.backend.utils.zip.ZipReader` instance from path.
	 * @param zipPath
	 * @return ZipReader
	 */
	public static function openZip(zipPath:String):ZipReader {
		return new ZipReader(File.read(zipPath));
	}

	/**
	 * [Description] Copy of haxe's Zip unzip function cause lime replaced it.
	 * @param f Zip entry
	 */
	public static function unzip(f:FileHeader) {
		return f.data;
	}

	/**
	 * [Description] Creates a ZIP file at the specified location and returns the Writer.
	 * @param path
	 * @return Writer
	 */
	public static function createZipFile(path:String):ZipWriter {
		var output = File.write(path);
		return new ZipWriter(output);
	}

	/**
		[Description] Writes the entirety of a folder to a zip file.
		@param zip ZIP file to write to
		@param path Folder path
		@param prefix (Additional) allows you to set a prefix in the zip itself.
	**/
	public static function writeFolderToZip(zip:ZipWriter, path:String, ?prefix:String, ?prog:ZipProgress, ?whitelist:Array<String>):ZipProgress {
		if (prefix == null) prefix = "";
		if (whitelist == null) whitelist = [];
		if (prog == null) prog = new ZipProgress();

		try {
			var curPath:Array<String> = [path];
			var destPath:Array<String> = [];
			if (prefix != "") {
				prefix = prefix.replace("\\", "/");
				while(prefix.charCodeAt(0) == "/".code) prefix = prefix.substr(1);
				while(prefix.charCodeAt(prefix.length-1) == "/".code) prefix = prefix.substr(0, prefix.length-1);
				destPath.push(prefix);
			}

			var files:Array<StrNameLabel> = [];

			var doFolder:Void->Void = null;
			(doFolder = function() {
				var path = curPath.join("/");
				var zipPath = destPath.join("/");
				for(e in FileSystem.readDirectory(path)) {
					if (bannedNames.contains(e.toLowerCase()) && !whitelist.contains(e.toLowerCase())) continue;
					if (FileSystem.isDirectory('$path/$e')) {
						// is directory, so loop into that function again
						for(p in [curPath, destPath]) p.push(e);
						doFolder();
						for(p in [curPath, destPath]) p.pop();
					} else {
						// is file, put it in the list
						var zipPath = '$zipPath/$e';
						while(zipPath.charCodeAt(0) == "/".code) zipPath = zipPath.substr(1);
						files.push(new StrNameLabel('$path/$e', zipPath));
					}
				}
			})();

			prog.fileCount = files.length;
			for(k=>file in files) {
				prog.curFile = k;

				var fileContent = File.getBytes(file.name);
				var fileInfo = FileSystem.stat(file.name);
				var entry:Entry = {
					fileName: file.label,
					fileSize: fileInfo.size,
					fileTime: Date.now(),
					dataSize: 0,
					data: fileContent,
					crc32: Crc32.make(fileContent),
					compressed: false
				};
				Tools.compress(entry, 1);
				zip.writeFile(entry);
			}
			zip.writeCDR();
		} catch(e) {
			prog.error = e;
		}
		prog.done = true;
		return prog;
	}

	public static function writeFolderToZipAsync(zip:ZipWriter, path:String, ?prefix:String):ZipProgress {
		var zipProg = new ZipProgress();
		Thread.create(function() {
			writeFolderToZip(zip, path, prefix, zipProg);
		});
		return zipProg;
	}

	/**
	 * [Description] Converts an `Array<FileHeader>` to a `List<FileHeader>`.
	 * @param array
	 * @return List<FileHeader>
	 */
	public static function arrayToList(array:Array<FileHeader>):List<FileHeader> {
		var list = new List<FileHeader>();
		for(e in array) list.push(e);
		return list;
	}
}

class ZipProgress {
	public var error:Exception = null;

	public var curFile:Int = 0;
	public var fileCount:Int = 0;
	public var done:Bool = false;
	public var percentage(get, never):Float;

	private function get_percentage() {
		return fileCount <= 0 ? 0 : curFile / fileCount;
	}

	public function new() {}
}

class ZipWriter extends Writer {
	public function flush() {
		o.flush();
	}

	public function writeFile(entry:Entry) {
		writeEntryHeader(entry);
		o.writeFullBytes(entry.data, 0, entry.data.length);
	}

	public function writeFileHeader(entry:FileHeader) {
		writeEntryHeader({
			fileName: entry.fileName,
			fileSize: entry.uncompressedSize,
			fileTime: entry.fileTime,
			dataSize: entry.compressedSize,
			data: entry.data,
			crc32: entry.crc32,
			compressed: false
		});
		o.writeFullBytes(entry.data, 0, entry.data.length);
	}

	public function close() {
		o.close();
	}
}

class StrNameLabel {
	public var name:String;
	public var label:String;

	public function new(name:String, label:String) {
		this.name = name;
		this.label = label;
	}
}
#end