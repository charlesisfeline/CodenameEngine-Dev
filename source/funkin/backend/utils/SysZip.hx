package funkin.backend.utils;

#if sys
import funkin.backend.utils.zip.ZipReader.CompressionMethod;
import funkin.backend.utils.zip.ZipReader.EndOfCentralDirectory;
import funkin.backend.utils.zip.ZipReader.ExtraField;
import funkin.backend.utils.zip.ZipReader.FileHeader;
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
	public function readEntryData(e:FileHeader) {
		return e.data;
	}

	/**
	 * Unzips and returns all of the data present in an entry.
	 * @param e Entry to read from.
	 */
	public function unzipEntry(e:FileHeader) {
		return e.data;
	}

	public function read():List<FileHeader> {
		return zipReader.read();
	}

	public function dispose() {
		if(zipReader != null) {
			zipReader.close();
			zipReader = null;
		}
	}

	public inline function close() {
		dispose();
	}
}
#end