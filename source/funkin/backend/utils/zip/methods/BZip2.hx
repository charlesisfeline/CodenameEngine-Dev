package funkin.backend.utils.zip.methods;

import haxe.io.Bytes;
import funkin.backend.utils.zip.BitInput;
import haxe.io.UInt8Array;
import haxe.io.UInt32Array;


typedef ByteUInt = #if cpp cpp.UInt8 #else UInt #end;

typedef HuffmanGroup = {
	var permute:UInt32Array;
	var base:UInt32Array;
	var limit:UInt32Array;
	var minLen:Int;
	var maxLen:Int;
}

// Based on https://github.com/antimatter15/bzip2.js/blob/master/bzip2.js
class BZip2 {
	// TODO: allow specifying the size to prevent memory allocations
	public static function decompress(i:InputAdapter) {
		var bits = new BitInput(i);
		var size = header(bits);
		var all = new haxe.io.BytesOutput();
		var chunk = null;
		do {
			if(chunk != null)
				all.write(chunk);
			chunk = _decompress(bits, size, 0);
		} while(chunk != null);
		return all.getBytes();
	}

	public static function header(bits:BitInput) {
		var magic:UInt = bits.bits(24);
		trace("Magic: " + StringTools.hex(magic) + " (" + Bytes.ofHex(StringTools.hex(magic)).toString() + ")");

		if(magic != 0x425A68) throw "Error: Invalid BZip2 magic number detected";
		var i = bits.bits(8) - '0'.code;
		if(i < 1 || i > 9) throw "Error: Input is not a valid BZIP archive";
		return i;
	}

	private static function _decompress(bits:BitInput, size:Int, len:Null<Int>) {
		final MAX_HUFCODE_BITS = 20;
		final MAX_SYMBOLS = 258;
		final SYMBOL_RUNA = 0;
		final SYMBOL_RUNB = 1;
		final GROUP_SIZE = 50;

		var bufsize = 100000 * size;
		{
			var byte0 = bits.bits(8);
			var byte1 = bits.bits(8);
			var byte2 = bits.bits(8);
			var byte3 = bits.bits(8);
			var byte4 = bits.bits(8);
			var byte5 = bits.bits(8);

			if (byte0 == 0x17 && byte1 == 0x72 && byte2 == 0x45 &&
				byte3 == 0x38 && byte4 == 0x50 && byte5 == 0x90) {
				return null; // Last block
			}
			if (byte0 != 0x31 && byte1 != 0x41 && byte2 != 0x59 &&
				byte3 != 0x26 && byte4 != 0x53 && byte5 != 0x59) {
				throw "Error: Corrupted or invalid BZip2 data";
			}
		}
		bits.bits(32); // ignore CRC codes
		if(bits.bits(1) != 0) throw "Error: Obsolete BZip2 version is not supported";
		var origPtr = bits.bits(24);
		if(origPtr > bufsize) throw "Error: Initial pointer exceeds buffer size";
		var t = bits.bits(16);
		var symToByte = new UInt8Array(256);
		var symTotal = 0;
		for (i in 0...16) {
			if(t & (1 << (15 - i)) != 0) {
				var k = bits.bits(16);
				for(j in 0...16){
					if(k & (1 << (15 - j)) != 0) {
						symToByte[symTotal++] = (16 * i) + j;
					}
				}
			}
		}


		var groupCount = bits.bits(3);
		trace("Group Count: " + groupCount);
		if(groupCount < 2 || groupCount > 6) throw "Error: Invalid group count in BZip2 data";
		final nSelectors = bits.bits(15);
		if(nSelectors == 0) throw "Error: Selector count is zero";
		var mtfSymbol = []; // TODO: change to a typed array
		for(i in 0...groupCount) mtfSymbol[i] = i;
		var selectors = new UInt8Array(32768);

		for(i in 0...nSelectors) {
			var j = 0;
			while (bits.bits(1) != 0) {
				if (j >= groupCount)
					throw "Error: Selector index out of range during MTF transform";
				j++;
			}

			var uc = mtfSymbol[j];
			mtfSymbol.splice(j, 1); //this is a probably inefficient MTF transform
			mtfSymbol.insert(0, uc);
			//mtfSymbol.splice(0, 0, uc);
			selectors[i] = uc;
		}

		final symCount = symTotal + 2;
		final groups:Array<HuffmanGroup> = [];
		for(j in 0...groupCount) {
			var length = new UInt8Array(MAX_SYMBOLS);
			var temp = new UInt8Array(MAX_HUFCODE_BITS+1);
			t = bits.bits(5); //lengths
			for(i in 0...symCount) {
				while(true) {
					if (t < 1 || t > MAX_HUFCODE_BITS) throw "Error: Huffman code length out of range";
					if(bits.bits(1) == 0) break;
					if(bits.bits(1) == 0) t++;
					else t--;
				}
				length[i] = t;
			}

			var maxLen:Int = length[0];
			var minLen:Int = length[0];
			for(i in 1...symCount) {
				if(length[i] > maxLen) maxLen = length[i];
				else if(length[i] < minLen) minLen = length[i];
			}
			var hufGroup:HuffmanGroup = {
				permute: new UInt32Array(MAX_SYMBOLS),
				limit: new UInt32Array(MAX_HUFCODE_BITS + 1),
				base: new UInt32Array(MAX_HUFCODE_BITS + 1),
				minLen: minLen,
				maxLen: maxLen
			};
			groups[j] = hufGroup;
			var base = hufGroup.base.subarray(1);
			var limit = hufGroup.limit.subarray(1);
			var pp = 0;
			for(i in minLen...maxLen+1)
				for(t in 0...symCount)
					if(length[t] == i) hufGroup.permute[pp++] = t;
			for(i in minLen...maxLen+1) {
				limit[i] = 0;
				temp[i] = 0;
			}
			for(i in 0...symCount) temp[length[i]]++;
			pp = t = 0;
			for(i in minLen...maxLen+1) {
				pp += temp[i];
				limit[i] = pp - 1;
				pp <<= 1;
				base[i+1] = pp - (t += temp[i]);
			}
			limit[maxLen]=pp+temp[maxLen]-1;
			base[minLen]=0;
		}
		var byteCount = new UInt32Array(256);
		for(i in 0...256) mtfSymbol[i] = i;
		var runPos:Int = 0, count:Int = 0, symCount:Int = 0, selector:Int = 0;
		var hufGroup:HuffmanGroup = null;
		var base:UInt32Array = null;
		var limit:UInt32Array = null;
		var buf = new UInt32Array(bufsize);
		while(true) {
			if((symCount--) == 0) {
				symCount = GROUP_SIZE - 1;
				if(selector >= nSelectors) throw "Error: Selector index out of bounds";
				hufGroup = groups[selectors[selector++]];
				base = hufGroup.base.subarray(1);
				limit = hufGroup.limit.subarray(1);
			}
			// hufGroup wont be null
			// base and limit wont be null
			var i = hufGroup.minLen;
			var j = bits.bits(i);
			while(true) {
				if(i > hufGroup.maxLen) throw "Error: Huffman code length exceeded maximum limit";
				if(j <= limit[i]) break;
				i++;
				j = (j << 1) | bits.bits(1);
			}
			j -= base[i];
			if(j < 0 || j >= MAX_SYMBOLS) throw "Error: Symbol index is invalid";
			var nextSym = hufGroup.permute[j];
			if (nextSym == SYMBOL_RUNA || nextSym == SYMBOL_RUNB) {
				if(runPos == 0) {
					runPos = 1;
					t = 0;
				}
				if(nextSym == SYMBOL_RUNA) t += runPos;
				else t += 2 * runPos;
				runPos <<= 1;
				continue;
			}
			if(runPos != 0) {
				runPos = 0;
				if(count + t >= bufsize) throw "Error: Buffer overflow detected during decoding";
				var uc = symToByte[mtfSymbol[0]];
				byteCount[uc] += t;
				while(t-- != 0) buf[count++] = uc;
			}
			if(nextSym > symTotal) break;
			if(count >= bufsize) throw "Error: Data buffer overflow";
			var i = nextSym -1;
			var uc = mtfSymbol[i];
			mtfSymbol.splice(i, 1);
			mtfSymbol.insert(0, uc);
			//mtfSymbol.splice(0, 0, uc);
			uc = symToByte[uc];
			byteCount[uc]++;
			buf[count++] = uc;
		}
		if(origPtr < 0 || origPtr >= count) throw "Error: Original pointer is out of bounds in buffer";
		var j = 0;
		for(i in 0...256) {
			var k = j + byteCount[i];
			byteCount[i] = j;
			j = k;
		}
		for(i in 0...count) {
			var uc = buf[i] & 0xff;
			buf[byteCount[uc]] |= (i << 8);
			byteCount[uc]++;
		}
		var pos = 0, current = 0, run = 0;
		if(count != 0) {
			pos = buf[origPtr];
			current = (pos & 0xff);
			pos >>= 8;
			run = -1;
		}
		//count = count;
		var output = new haxe.io.BytesOutput();
		var copies, previous, outbyte;
		var isLimited = len != null;
		//if(len == 0) len = 0xfffffff; // Math.POSITIVE_INFINITY;
		while(count != 0) {
			count--;
			previous = current;
			pos = buf[pos];
			current = pos & 0xff;
			pos >>= 8;
			if(run++ == 3) {
				copies = current;
				outbyte = previous;
				current = -1;
			}else{
				copies = 1;
				outbyte = current;
			}
			while(copies-- != 0) {
				output.writeByte(outbyte);
				if(isLimited && --len == 0) return output.getBytes();
			}
			if(current != previous) run = 0;
		}
		return output.getBytes();
	}
}