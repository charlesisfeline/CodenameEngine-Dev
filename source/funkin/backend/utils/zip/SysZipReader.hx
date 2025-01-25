package funkin.backend.utils.zip;

import funkin.backend.utils.zip.methods.BZip2;
import funkin.backend.utils.zip.methods.Huffman;
import funkin.backend.utils.zip.methods.InflateImpl;
import haxe.ds.List;
import haxe.io.Input;

class EndOfCentralDirectory {
	public var address:Int;
	/**
	 * End of central directory signature
	**/
	public var headerSignature:Int;
	/**
	 * Number of this disk
	**/
	public var diskNum:Int;
	/**
	 * Disk where central directory starts
	**/
	public var diskStart:Int;
	/**
	 * Number of central directory records on this disk
	**/
	public var CDRCount:Int;
	/**
	 * Total number of entries in the central directory
	**/
	public var CentralDirectoryRecordCount:Int;
	/**
	 * Size of central directory (bytes)
	**/
	public var CDSize:Int;
	/**
	 * Offset of start of central directory, relative to start of archive
	**/
	public var CDOffset:Int;
	/**
	 * Comment
	**/
	public var comment:String;

	public function new(i:InputAdapter, address:Int) {
		this.address = address;
		var old = i.tell();
		i.seek(address, SeekBegin);
		this.headerSignature = i.readInt32();
		this.diskNum = i.readUInt16();
		this.diskStart = i.readUInt16();
		this.CDRCount = i.readUInt16();
		this.CentralDirectoryRecordCount = i.readUInt16();
		this.CDSize = i.readInt32();
		this.CDOffset = i.readInt32();
		this.comment = i.readString(i.readUInt16());
		i.seek(old, SeekBegin);
	}
}

class GeneralPurposeBitFlags {
	public var encrypted:Bool;
	public var compressionOptions:Int;
	public var crcAndSizesInCDAndDataDescriptor:Bool;
	public var enhancedDeflating:Bool;
	public var patchedData:Bool;
	public var strongEncryption:Bool;
	public var unused:Int;
	public var filenameAndCommentAreUtf8:Bool;
	public var reservedPKWARE_0:Bool;
	public var centralDirectoryEncrypted:Bool;
	public var reservedPKWARE_1:Int;

	public function new(value:Int) {
		this.encrypted = (value & 0x1) != 0;
		this.compressionOptions = (value >> 1) & 0x3;
		this.crcAndSizesInCDAndDataDescriptor = (value >> 3) & 0x1 != 0;
		this.enhancedDeflating = (value >> 4) & 0x1 != 0;
		this.patchedData = (value >> 5) & 0x1 != 0;
		this.strongEncryption = (value >> 6) & 0x1 != 0;
		this.unused = (value >> 7) & 0xF;
		this.filenameAndCommentAreUtf8 = (value >> 11) & 0x1 != 0;
		this.reservedPKWARE_0 = (value >> 12) & 0x1 != 0;
		this.centralDirectoryEncrypted = (value >> 13) & 0x1 != 0;
		this.reservedPKWARE_1 = (value >> 14) & 0x3;
	}
}

enum abstract CompressionMethod(Int) from Int to Int {
	var None = 0;
	var Shrunk = 1;
	var Factor1 = 2;
	var Factor2 = 3;
	var Factor3 = 4;
	var Factor4 = 5;
	var Implode = 6;
	// var ? = 7;  // Reserved for Tokenizing compression algorithm
	var Deflate = 8;
	var Deflate64 = 9;
	var PKWARE = 10;
	// var ? = 11;  // Reserved by PKWARE
	var BZIP2 = 12;
	// var ? = 13;  // Reserved by PKWARE
	var LZMA = 14;
	// var ? = 15;  // Reserved by PKWARE
	var CMPSC = 16;
	// var ? = 17;  // Reserved by PKWARE
	var IBMTERSE = 18;
	var LZ77 = 19;
	var ZSTD = 93;
	var MP3 = 94;
	var XZ = 95;
	var JPEG = 96;
	var WavPack = 97;
	var PPMd = 98;
	var AE_x = 99;

	public static function toReadable(i:CompressionMethod):String {
		return switch(i) {
			case CompressionMethod.None: "None";
			case CompressionMethod.Shrunk: "Shrunk";
			case CompressionMethod.Factor1: "Factor1";
			case CompressionMethod.Factor2: "Factor2";
			case CompressionMethod.Factor3: "Factor3";
			case CompressionMethod.Factor4: "Factor4";
			case CompressionMethod.Implode: "Implode";
			case CompressionMethod.Deflate: "Deflate";
			case CompressionMethod.Deflate64: "Deflate64";
			case CompressionMethod.PKWARE: "PKWARE";
			case CompressionMethod.BZIP2: "BZIP2";
			case CompressionMethod.LZMA: "LZMA";
			case CompressionMethod.CMPSC: "CMPSC";
			case CompressionMethod.IBMTERSE: "IBMTERSE";
			case CompressionMethod.LZ77: "LZ77";
			case CompressionMethod.ZSTD: "ZSTD";
			case CompressionMethod.MP3: "MP3";
			case CompressionMethod.XZ: "XZ";
			case CompressionMethod.JPEG: "JPEG";
			case CompressionMethod.WavPack: "WavPack";
			case CompressionMethod.PPMd: "PPMd";
			case CompressionMethod.AE_x: "AE_x";
		}
	}
}

class ExtraFieldData {
}

class ExtraFieldPadding extends ExtraFieldData{
	public var bytes:haxe.io.Bytes;
	public function new(i:InputAdapter, size:Int) {
		this.bytes = i.read(size);
	}
}

class ExtraField {
	public var tag:Int;
	public var size:Int;
	public var data:ExtraFieldData;

	public function new(i:InputAdapter) {
		this.tag = i.readUInt16();
		this.size = i.readUInt16();

		switch(tag) {
			// case 0x5455: // Extended Timestamp
			// case 0x000a: // NTFS FileTimes
			// case 0x7855: // Info-ZIP Unix Extra Field
			// case 0x5855: // Info-ZIP Unix Extra Field
			default: data = new ExtraFieldPadding(i, size);
		}
	}
}

class LocalFileHeader {
	public var headerSignature:Int;
	public var version:Int;
	public var generalPurposeBitFlags:GeneralPurposeBitFlags;
	public var compressionMethod:CompressionMethod;
	public var lastModifyTime:Int;
	public var lastModifyDate:Int;
	public var crc32:Int;
	public var compressedSize:Int;
	public var uncompressedSize:Int;
	public var fileName:String;
	public var extraFields:List<ExtraField>;
	public var data(get, null):haxe.io.Bytes = null;
	private var dataPos:Int;
	private var i:InputAdapter;

	public function new(i:InputAdapter, location:Int) {
		var old = i.tell();
		i.seek(location, SeekBegin);
		this.headerSignature = i.readInt32();
		this.version = i.readUInt16();
		this.generalPurposeBitFlags = new GeneralPurposeBitFlags(i.readUInt16());
		this.compressionMethod = i.readUInt16();
		this.lastModifyTime = i.readUInt16();
		this.lastModifyDate = i.readUInt16();
		this.crc32 = i.readInt32();
		this.compressedSize = i.readInt32();
		this.uncompressedSize = i.readInt32();
		var fileNameLength = i.readUInt16();
		var extraFieldLength = i.readUInt16();
		this.fileName = i.readString(fileNameLength);
		var extraEnd = i.tell() + extraFieldLength;
		this.extraFields = new List();
		while(i.tell() < extraEnd) {
			extraFields.add(new ExtraField(i));
		}
		this.dataPos = i.tell();
		this.i = i;
		i.seek(old, SeekBegin);
	}

	inline function get_data() {
		var old = i.tell();
		i.seek(dataPos, SeekBegin);
		trace("Seek: " + dataPos);
		trace("Compression: " + CompressionMethod.toReadable(compressionMethod) + " (" + compressedSize + " bytes)");
		var res = switch(compressionMethod) {
			case CompressionMethod.None: i.read(compressedSize);
			case CompressionMethod.Deflate: {
				final bufSize = 65536;
				var tmp = haxe.io.Bytes.alloc(bufSize);
				var out = new haxe.io.BytesBuffer();
				var z = new InflateImpl(i.i, false, false);
				while (true) {
					var n = z.readBytes(tmp, 0, bufSize);
					out.addBytes(tmp, 0, n);
					if (n < bufSize)
						break;
				}
				out.getBytes();
			}
			case BZIP2: BZip2.decompress(i);
			// TODO: support lzma
			// TODO: support zstd
			default: throw "Unsupported compression method: " + CompressionMethod.toReadable(compressionMethod);
		}
		i.seek(old, SeekBegin);
		return res;
	}

	/**
	 * To reduce memory usage.
	**/
	public function clearData() {
		data = null;
	}


	/*struct LocalFileHeader {
		u32 headerSignature [[name("LCF PK\\3\\4")]];
		u16 version [[ comment("The minimum supported ZIP specification version needed to extract the file") ]];
		GeneralPurposeBitFlags generalPurposeBitFlags  [[ comment("General purpose bit flag") ]];
		CompressionMethod compressionMethod [[ comment("Compression method") ]];
		u16 lastModifyTime [[ comment("File last modification time") ]];
		u16 lastModifyDate [[ comment("File last modification date") ]];
		u32 crc32 [[ comment("CRC-32") ]];
		u32 compressedSize [[ comment("Compressed size") ]];
		u32 uncompressedSize [[ comment("Uncompressed size") ]];
		u16 fileNameLength [[ comment("File name length (n)") ]];
		u16 extraFieldLength [[ comment("Extra field length (m)") ]];
		char fileName[fileNameLength] [[ comment("File Name") ]];
		u64 extraEnd = $ + extraFieldLength;
		extra::ExtraField extraFields[while ($ < extraEnd)] [[comment("Extra Fields")]];
		u8 data[compressedSize] [[name("File Data")]];
	};*/
}

class FileHeader {
	/**
	 * Central directory file header signature
	**/
	public var headerSignature:Int; // Size: 4
	/**
	 * Version made by
	**/
	public var versionMade:Int; // Size: 2
	/**
	 * Version needed to extract
	**/
	public var versionExtract:Int; // Size: 2
	/**
	 * General purpose bit flag
	**/
	public var generalPurposeBitFlags:GeneralPurposeBitFlags; // Size: 2
	/**
	 * Compression method
	**/
	public var compressionMethod:CompressionMethod; // Size: 2
	/**
	 * File last modification time
	**/
	public var fileLastModifyTime:Int; // Size: 2
	/**
	 * File last modification date
	**/
	public var fileLastModifyDate:Int; // Size: 2
	/**
	 * CRC-32 of uncompressed data
	**/
	public var crc32:Int; // Size: 4
	/**
	 * Compressed size
	**/
	public var compressedSize:Int; // Size: 4
	/**
	 * Uncompressed size
	**/
	public var uncompressedSize:Int; // Size: 4
	/**
	 * Disk number where file starts
	**/
	public var diskNumber:Int; // Size: 2
	/**
	 * Internal file attributes
	**/
	public var internalFileAttributes:Int; // Size: 2
	/**
	 * External file attributes
	**/
	public var externalFileAttributes:Int; // Size: 4
	public var localFile:LocalFileHeader;
	/**
	 * File name
	**/
	public var fileName:String; // Size: fileNameLength
	/**
	 * Extra fields
	**/
	public var extraFields:List<ExtraField>; // Size: extraFieldLength
	/**
	 * File comment
	**/
	public var comment:String; // Size: fileCommentLength

	public var data(get, never):haxe.io.Bytes;
	private inline function get_data() {
		return localFile.data;
	}

	public function new(i:InputAdapter) {
		this.headerSignature = i.readInt32();
		this.versionMade = i.readUInt16();
		this.versionExtract = i.readUInt16();
		this.generalPurposeBitFlags = new GeneralPurposeBitFlags(i.readUInt16());
		this.compressionMethod = i.readUInt16();
		this.fileLastModifyTime = i.readUInt16();
		this.fileLastModifyDate = i.readUInt16();
		this.crc32 = i.readInt32();
		this.compressedSize = i.readInt32();
		this.uncompressedSize = i.readInt32();
		var fileNameLength = i.readUInt16();
		var extraFieldLength = i.readUInt16();
		var fileCommentLength = i.readUInt16();
		this.diskNumber = i.readUInt16();
		this.internalFileAttributes = i.readUInt16();
		this.externalFileAttributes = i.readInt32();
		this.localFile = new LocalFileHeader(i, i.readInt32());
		this.fileName = i.readString(fileNameLength);
		var extraEnd = i.tell() + extraFieldLength;
		this.extraFields = new List();
		while(i.tell() < extraEnd) {
			extraFields.add(new ExtraField(i));
		}
		this.comment = i.readString(fileCommentLength);
	}
}

// see http://www.pkware.com/documents/casestudies/APPNOTE.TXT
class SysZipReader {
	var i:InputAdapter;
	var len:Int;
	public var eocd:EndOfCentralDirectory;

	public function new(i:haxe.io.Input) {
		this.i = InputAdapter.fromInput(i);

		this.len = this.i.length;
	}

	public function close() {
		i.close();
	}

	/*function readZipDate() {
		var t = i.readUInt16();
		var hour = (t >> 11) & 31;
		var min = (t >> 5) & 63;
		var sec = t & 31;
		var d = i.readUInt16();
		var year = d >> 9;
		var month = (d >> 5) & 15;
		var day = d & 31;
		return new Date(year + 1980, month - 1, day, hour, min, sec << 1);
	}*/
/*
	function readExtraFields(length) {
		var fields = new List();
		while (length > 0) {
			if (length < 4)
				throw "Invalid extra fields data";
			var tag = i.readUInt16();
			var len = i.readUInt16();
			if (length < len)
				throw "Invalid extra fields data";
			switch (tag) {
				case 0x7075:
					var version = i.readByte();
					if (version != 1) {
						var data = new haxe.io.BytesBuffer();
						data.addByte(version);
						data.add(i.read(len - 1));
						fields.add(FUnknown(tag, data.getBytes()));
					} else {
						var crc = i.readInt32();
						var name = i.read(len - 5).toString();
						fields.add(FInfoZipUnicodePath(name, crc));
					}
				default:
					fields.add(FUnknown(tag, i.read(len)));
			}
			length -= 4 + len;
		}
		return fields;
	}*/

	public function readByteAt(pos:Int) {
		var old = i.tell();
		i.seek(pos, SeekBegin);
		var r = i.readByte();
		i.seek(old, SeekBegin);
		return r;
	}

	public function readInt32At(pos:Int) {
		var old = i.tell();
		i.seek(pos, SeekBegin);
		var r = i.readInt32();
		i.seek(old, SeekBegin);
		return r;
	}

	// TODO: rewrite this to not use readByteAt
	public function findSequenceInRange(start:Int, end:Int, seq:Array<Int>) {
		var i = start;
		while(i < end) {
			var found = true;
			for(s in seq) {
				if(readByteAt(i) != s) {
					found = false;
					break;
				}
				i++;
			}
			if(found) return i;
		}
		return -1;
	}

	public function findEOCD() {
		if(readInt32At(len - 22) == 0x06054B50) {
			return new EndOfCentralDirectory(i, len - 22);
		}

		// If it's not there, then there's probably a zip comment;
		// search the last 64KB of the file for the signature.
		// TODO: support int64 sizes and int128 sizes
		var offsetSearchFrom = Std.int(Math.max(0, len - 65536 - 22));
		var prevAddress:Int = 0;

		while(true) {
			var old = i.tell();
			var currentAddress = findSequenceInRange(offsetSearchFrom, len, [0x50, 0x4B, 0x05, 0x06]);
			if(currentAddress == -1) {
				i.seek(old, SeekBegin);
				throw "Could not find EOCD in zip file.";
			}

			// Potential eocd found. Create a eocd struct
			var eocd = new EndOfCentralDirectory(i, currentAddress);

			// If central directory file header is valid, then we know the eocd offset is valid.
			if(readInt32At(eocd.CDOffset) == 0x2014B50) {
				return eocd;
			}

			offsetSearchFrom = currentAddress + 1;
			prevAddress = currentAddress;
		}
		throw "Could not find EOCD in zip file.";
	}

	public function readEOCD() {
		var eocd = findEOCD();
		trace("EOCD: " + haxe.Json.parse(haxe.Json.stringify(eocd))); // to print as json
		this.eocd = eocd;
	}

	public function readFileHeader():FileHeader {
		var i = this.i;
		//var h = i.readInt32();
		//if (h == 0x02014B50 || h == 0x06054B50)
		//	return null;
		//if (h != 0x04034B50)
		//	throw "Invalid Zip Data";
		//i.seek(-4, SeekCur);
		return new FileHeader(i);
	}

	public function read():List<FileHeader> {
		if(eocd == null) readEOCD();

		i.seek(eocd.CDOffset, SeekBegin);
		var total = eocd.CentralDirectoryRecordCount;

		var l = new List();
		var totalRead = 0;
		while (totalRead < total) {
			var e = readFileHeader();
			trace("File: " + haxe.Json.parse(haxe.Json.stringify(e))); // to print as json

			l.add(e);
			totalRead++;
		}
		return l;
	}

	public static function readZip(i:haxe.io.Input) {
		var r = new SysZipReader(i);
		return r.read();
	}

	/*public static function unzip(f:Entry) {
		if (!f.compressed)
			return f.data;
		var c = new haxe.zip.Uncompress(-15);
		var s = haxe.io.Bytes.alloc(f.fileSize);
		var r = c.execute(f.data, 0, s, 0);
		c.close();
		if (!r.done || r.read != f.data.length || r.write != f.fileSize)
			throw "Invalid compressed data for " + f.fileName;
		f.compressed = false;
		f.dataSize = f.fileSize;
		f.data = s;
		return f.data;
	}*/
}