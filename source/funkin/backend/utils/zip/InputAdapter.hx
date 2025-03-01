package funkin.backend.utils.zip;

@:dox(hide)
enum ZipFileSeek {
	SeekBegin;
	SeekCur;
	SeekEnd;
}

@:dox(hide)
class InputAdapter {
	public var length:Int;
	public var i:haxe.io.Input;

	public function new(i:haxe.io.Input) {
		this.i = i;
	}

	public static function fromInput(i:haxe.io.Input):InputAdapter {
		#if sys
		if((i is sys.io.FileInput)) {
			return new FileInputAdapter(cast i);
		}
		#end
		if((i is haxe.io.BytesInput)) {
			return new BytesInputAdapter(cast i);
		}
		throw "Unsupported input type " + Type.getClass(i);
	}

	public function close() {}

	public function tell() {
		return 0;
	}

	public function seek(p:Int, pos:ZipFileSeek) {

	}

	public inline function read(len:Int) return i.read(len);
	public inline function readByte() return i.readByte();
	public inline function readInt24() return i.readInt24();
	public inline function readInt32() return i.readInt32();
	public inline function readUInt16() return i.readUInt16();
	public inline function readString(len:Int) return i.readString(len);
}

#if sys
@:dox(hide)
class FileInputAdapter extends InputAdapter {
	var f:sys.io.FileInput;
	public function new(f:sys.io.FileInput) {
		super(f);
		this.f = f;

		var old = f.tell();
		f.seek(0, SeekEnd);
		length = f.tell();
		f.seek(old, SeekBegin);
	}

	public override function close() {
		f.close();
	}

	override public function tell() {
		return f.tell();
	}

	override public function seek(p:Int, pos:ZipFileSeek) {
		f.seek(p, switch(pos) {
			case SeekBegin: sys.io.FileSeek.SeekBegin;
			case SeekCur: sys.io.FileSeek.SeekCur;
			case SeekEnd: sys.io.FileSeek.SeekEnd;
		});
	}
}
#end

@:dox(hide)
class BytesInputAdapter extends InputAdapter{
	var b:haxe.io.BytesInput;
	public function new(b:haxe.io.BytesInput) {
		super(b);
		this.b = b;

		this.length = b.length;
	}

	public override function close() {
		b.close();
	}

	override public function tell() {
		return b.position;
	}

	override public function seek(p:Int, pos:ZipFileSeek) {
		switch(pos) {
			case SeekBegin: b.position = p;
			case SeekCur: b.position += p;
			case SeekEnd: b.position = b.length - p;
		}
	}
}
