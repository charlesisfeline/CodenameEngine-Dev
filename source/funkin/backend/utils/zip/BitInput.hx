package funkin.backend.utils.zip;

class BitInput {
	var i:InputAdapter;

	var bit:Int = 0;
	var byte:Int = 0;
  	static var BITMASK = [0, 0x01, 0x03, 0x07, 0x0F, 0x1F, 0x3F, 0x7F, 0xFF ];

	public function new(i:InputAdapter) {
		this.i = i;
		this.byte = i.tell();
	}

	public function readByteAt(pos:Int) {
		var old = i.tell();
		i.seek(pos, SeekBegin);
		var b = i.readByte();
		i.seek(old, SeekBegin);
		return b;
	}

	public function bits(n:Int) {
		var result = 0;
		while(n > 0) {
			var left = 8 - bit;
			if(n >= left) {
				result <<= left;
				result |= (BITMASK[left] & readByteAt(byte++));
				bit = 0;
				n -= left;
			} else {
				result <<= n;
				result |= ((readByteAt(byte) & (BITMASK[n] << (8 - n - bit))) >> (8 - n - bit));
				bit += n;
				n = 0;
			}
		}
		return result;
	}
}