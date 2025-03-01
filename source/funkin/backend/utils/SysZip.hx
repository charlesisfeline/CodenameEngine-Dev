package funkin.backend.utils;

#if sys
import funkin.backend.utils.zip.ZipReader.ExtraField;
import funkin.backend.utils.zip.ZipReader.CompressionMethod;
import funkin.backend.utils.zip.ZipReader.EndOfCentralDirectory;
import funkin.backend.utils.zip.ZipReader.FileHeader;
import funkin.backend.utils.zip.ZipReader.GeneralPurposeBitFlags;
import funkin.backend.utils.zip.ZipReader.LocalFileHeader;
import funkin.backend.utils.zip.ZipReader;
import sys.io.File;
import sys.io.FileInput;

/**
 * Class that extends Reader allowing you to load ZIP entries without blowing your RAM up!!
 * Mock to redirect to funkin.backend.utils.zip.ZipReader, whilst keeping the same API
 */
class SysZip {
	var zipReader:ZipReader;

	var entries:List<SysZipEntry>;

	/**
	 * Opens a zip from a specified path.
	 * @param path Path to the zip file.
	 */
	public static function openFromFile(path:String) {
		return new SysZip(File.read(path, true));
	}

	/**
	 * Creates a new SysZip from a specified file input.
	 * @param input File input.
	 */
	public function new(input:FileInput) {
		zipReader = new ZipReader(input);
	}

	/**
	 * Reads all the data present in a specified entry.
	 * @param e Entry
	 */
	public function readEntryData(e:SysZipEntry) {
		return e.data;
	}

	/**
	 * Unzips and returns all of the data present in an entry.
	 * @param e Entry to read from.
	 */
	public function unzipEntry(e:SysZipEntry) {
		return e.data;
	}

	public function read():List<SysZipEntry> {
		if (entries != null) return entries;
		var list = zipReader.read();
		var newList:List<SysZipEntry> = new List();
		for(e in list)
			newList.add(new SysZipEntry(e));
		entries = newList;
		return newList;
	}

	public function dispose() {
		if(zipReader != null) {
			zipReader.close();
			zipReader = null;
		}
	}
}

class SysZipEntry {
	public var fileName(get, never):String;
	private inline function get_fileName() return realEntry.fileName;
	public var fileSize(get, never):Int;
	private inline function get_fileSize() return realEntry.uncompressedSize;
	public var fileTime(get, never):Date;
	private inline function get_fileTime() return realEntry.fileLastModifyDate;
	public var compressed(get, never):Bool;
	private inline function get_compressed() return realEntry.compressionMethod != CompressionMethod.None;
	public var dataSize(get, never):Int;
	private inline function get_dataSize() return realEntry.uncompressedSize;
	public var data(get, never):haxe.io.Bytes;
	private inline function get_data() return realEntry.data;
	public var crc32(get, never):Null<Int>;
	private inline function get_crc32() return realEntry.crc32;
	public var extraFields(get, never):List<ExtraField>;
	private inline function get_extraFields() return realEntry.extraFields;

	public var realEntry:FileHeader;

	public function new(e:FileHeader) {
		this.realEntry = e;
	}
}
#end