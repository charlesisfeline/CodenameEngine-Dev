package funkin.game;

import flixel.FlxTypes.ByteInt;
import flixel.util.typeLimit.OneOfTwo;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import funkin.backend.chart.ChartData;
import funkin.backend.scripting.events.note.NoteCreationEvent;
import funkin.backend.system.Conductor;

using StringTools;

typedef NoteObject = OneOfTwo<Note, OptimizedNote>;

@:allow(funkin.game.PlayState)
class Note extends FlxSprite
{
	public var extra:Map<String, Dynamic> = [];

	public var strumTime:Float = 0;

	public var mustPress(get, never):Bool;
	public var strumLine(default, set):StrumLine;
	private function set_strumLine(strLine:StrumLine) {
		if (this.strumLine != null) {
			if (this.strumLine.notes != null)
				this.strumLine.notes.remove(this, true);
			strLine.notes.add(this);
			strLine.notes.sortNotes();
		}
		return strumLine = strLine;
	}

	private inline function get_mustPress():Bool {
		return false;
	}
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;

	/**
	 * Whenever that note should be avoided by Botplay.
	 */
	public var avoid:Bool = false;

	/**
	 * The note that comes before this one (sustain and not)
	 */
	public var prevNote:Note;
	/**
	 * The note that comes after this one (sustain and not)
	 */
	public var nextNote:Note;
	/**
	 * The next sustain after this one
	 */
	public var nextSustain:Note;

	/**
	 * Name of the splash.
	 */
	public var splash:String = "default";

	public var strumID(get, never):Int;
	private function get_strumID() {
		var id = noteData % strumLine.members.length;
		if (id < 0) id = 0;
		return id;
	}

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var flipSustain:Bool = true;

	public var noteTypeID:Int = 0;

	// TO APPLY THOSE ON A SINGLE NOTE
	public var scrollSpeed:Null<Float> = null;
	public var noteAngle:Null<Float> = null;

	public var noteType(get, never):String;

	@:dox(hide) public var __strumCameras:Array<FlxCamera> = null;
	@:dox(hide) public var __strum:Strum = null;
	@:dox(hide) public var __noteAngle:Float = 0;

	private function get_noteType() {
		if (PlayState.instance == null) return null;
		return PlayState.instance.getNoteType(noteTypeID);
	}

	public static var swagWidth:Float = 160 * 0.7; // TODO: remove this

	private static var __customNoteTypeExists:Map<String, Bool> = [];

	public var animSuffix:String = null;


	private static function customTypePathExists(path:String) {
		if (__customNoteTypeExists.exists(path))
			return __customNoteTypeExists[path];
		return __customNoteTypeExists[path] = Assets.exists(path);
	}

	static var DEFAULT_FIELDS:Array<String> = ["time", "id", "type", "sLen"];

	public function new(strumLine:StrumLine, noteData:ChartNote, sustain:Bool = false, sustainLength:Float = 0, sustainOffset:Float = 0, ?prev:Note)
	{
		super();

		moves = false;

		if(prev != null)
			this.prevNote = prev;
		else
			this.prevNote = strumLine.notes.members.last();

		if (this.prevNote != null) this.prevNote.nextNote = this;
		this.noteTypeID = noteData.type.getDefault(0);
		this.isSustainNote = sustain;
		this.sustainLength = sustainLength;
		this.strumLine = strumLine;
		for(field in Reflect.fields(noteData)) if(!DEFAULT_FIELDS.contains(field))
			this.extra.set(field, Reflect.field(noteData, field));

		x += 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;

		this.strumTime = noteData.time.getDefault(0) + sustainOffset;
		this.noteData = noteData.id.getDefault(0);

		var customType = Paths.image('game/notes/${this.noteType}');
		var event = EventManager.get(NoteCreationEvent).recycle(this, strumID, this.noteType, noteTypeID, PlayState.instance.strumLines.members.indexOf(strumLine), mustPress,
			(this.noteType != null && customTypePathExists(customType)) ? 'game/notes/${this.noteType}' : 'game/notes/default', @:privateAccess strumLine.strumScale * Flags.DEFAULT_NOTE_SCALE, "default", animSuffix, null, null, null);

		if (PlayState.instance != null)
			event = PlayState.instance.gameAndCharsEvent("onNoteCreation", event);

		this.animSuffix = event.animSuffix;
		if (!event.cancelled) {
			if (event.noteSplash != "default") splash = event.noteSplash;

			switch (event.noteType)
			{
				// case "My Custom Note Type": // hardcoding note types
				default:
					frames = Paths.getFrames(event.noteSprite);

					animation.addByPrefix('scroll', event.noteAnimPrefix != null ? event.noteAnimPrefix : Flags.DEFAULT_NOTE_ANIM_PREFIXES[event.strumID % 4]);
					animation.addByPrefix('hold', event.sustainAnimPrefix != null ? event.sustainAnimPrefix : Flags.DEFAULT_NOTE_SUSTAIN_ANIM_PREFIXES[event.strumID % 4]);
					animation.addByPrefix('holdend', event.sustainEndAnimPrefix != null ? event.sustainEndAnimPrefix : Flags.DEFAULT_NOTE_SUSTAIN_END_ANIM_PREFIXES[event.strumID % 4]);

					scale.set(event.noteScale, event.noteScale);
					antialiasing = true;
			}
		}

		updateHitbox();

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			animation.play('holdend');

			updateHitbox();

			if (prevNote.isSustainNote)
			{
				prevNote.nextSustain = this;
				prevNote.animation.play('hold');
			}
		} else {
			animation.play("scroll");
		}

		if (PlayState.instance != null) {
			PlayState.instance.splashHandler.getSplashGroup(splash);
			PlayState.instance.gameAndCharsEvent("onPostNoteCreation", event);
		}
	}

	public var lastScrollSpeed:Null<Float> = null;
	public var gapFix:Single = 0;
	public var useAntialiasingFix(get, set):Bool;
	inline function set_useAntialiasingFix(v:Bool) {
		if(v != useAntialiasingFix) {
			gapFix = v ? 1 : 0;
		}
		return v;
	}
	inline function get_useAntialiasingFix() {
		return gapFix>0;
	}

	/**
	 * Whenever the position of the note should be relative to the strum position or not.
	 * For example, if this is true, a note at the position 0; 0 will be on the strum, instead of at the top left of the screen.
	 */
	public var strumRelativePos:Bool = true;

	override function drawComplex(camera:FlxCamera) {
		var downscrollCam = (camera is HudCamera ? ({var _:HudCamera=cast camera;_;}).downscroll : false);
		flipY = (isSustainNote && flipSustain) && (downscrollCam != (__strum != null && __strum.getScrollSpeed(this) < 0));
		if (downscrollCam) {
			frameOffset.y += __notePosFrameOffset.y * 2;
			super.drawComplex(camera);
			frameOffset.y -= __notePosFrameOffset.y * 2;
		} else
			super.drawComplex(camera);
	}

	static var __notePosFrameOffset:FlxPoint = new FlxPoint();
	static var __posPoint:FlxPoint = new FlxPoint();

	override function draw() {
		@:privateAccess var oldDefaultCameras = FlxCamera._defaultCameras;
		@:privateAccess if (__strumCameras != null) FlxCamera._defaultCameras = __strumCameras;

		var negativeScroll = isSustainNote && nextSustain != null && lastScrollSpeed < 0;
		if (negativeScroll)	offset.y *= -1;

		if (__strum != null && strumRelativePos) {
			var pos = __posPoint.set(x, y);

			setPosition(__strum.x, __strum.y);

			__notePosFrameOffset.set(pos.x / scale.x, pos.y / scale.y);

			frameOffset.x -= __notePosFrameOffset.x;
			frameOffset.y -= __notePosFrameOffset.y;

			this.frameOffsetAngle = __noteAngle;

			super.draw();

			this.frameOffsetAngle = 0;

			frameOffset.x += __notePosFrameOffset.x;
			frameOffset.y += __notePosFrameOffset.y;

			setPosition(pos.x, pos.y);
			//pos.put();
		} else {
			__notePosFrameOffset.set(0, 0);
			super.draw();
		}

		if (negativeScroll)	offset.y *= -1;
		@:privateAccess FlxCamera._defaultCameras = oldDefaultCameras;
	}

	// The * 0.5 is so that it's easier to hit them too late, instead of too early
	public var earlyPressWindow:Float = 0.5;
	public var latePressWindow:Float = 1;

	public function updateSustain(strum:Strum) {
		var scrollSpeed = strum.getScrollSpeed(this);

		var len = 0.45 * CoolUtil.quantize(scrollSpeed, 100);

		if (nextSustain != null && lastScrollSpeed != scrollSpeed) {
			// is long sustain
			lastScrollSpeed = scrollSpeed;

			scale.y = (sustainLength * len) / frameHeight;
			updateHitbox();
			scale.y += gapFix / frameHeight;
		}

		if (!wasGoodHit) return;
		var t = CoolUtil.bound((Conductor.songPosition - strumTime) / (height) * len, 0, 1);
		var swagRect = this.clipRect == null ? new FlxRect() : this.clipRect;
		swagRect.x = 0;
		swagRect.y = t * frameHeight;
		swagRect.width = frameWidth;
		swagRect.height = frameHeight;

		setClipRect(swagRect);
	}

	public inline function setClipRect(rect:FlxRect) {
		this.clipRect = rect;
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}

	public override function destroy() {
		super.destroy();
	}
}




class OptimizedNote {
	public var strumTime:Float;
	public var strumID:ByteInt;
	public var noteTypeID:ByteInt;
	public var sustainLength:Single;

	public var noteDrawID:ByteInt;

	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;

	public function new() {}
}
class NoteDrawInfo {
	public var strumID:ByteInt;
	public var scale:Float = 0.7;
	public var sprite:String = 'game/notes/default';
	public var splash:String = "default"; //maybe move this out of draw info

	public var noteSprite:FlxSprite;
	public var sustainSprite:FlxSprite;
	public var sustainEndSprite:FlxSprite;

	public function drawNote(note:OptimizedNote, strumLine:StrumLine) {
		var strum = strumLine.members[note.strumID];
		if (strum == null) return;

		noteSprite.setPosition(strum.x + (strum.width - noteSprite.width) / 2, strum.y + (note.strumTime - Conductor.songPosition) * (0.45 * CoolUtil.quantize(strum.getScrollSpeed(), 100)));
		noteSprite.scrollFactor.set(strum.scrollFactor.x, strum.scrollFactor.y);
		noteSprite.cameras = strumLine.cameras;
		noteSprite.draw();
	}

	public function new() {}
}
class NoteTypeInfo {
	public var animSuffix:String = null;
	public var avoid:Bool = false;
	public var lateHitWindow:Float = 1.0;
	public var earlyHitWindow:Float = 0.5;
}

class OptimizedNoteManager {
	private static var noteDrawInfos:Array<NoteDrawInfo> = [];

	public static function reset() {
		for (info in noteDrawInfos) {
			info.noteSprite.destroy();
		}
		noteDrawInfos.splice(0, noteDrawInfos.length);
	}

	public static inline function getNoteDrawInfo(id:Int) { return OptimizedNoteManager.noteDrawInfos[id];}
	public static function generateNoteDrawInfoID(event:NoteCreationEvent) {
		for (i => info in OptimizedNoteManager.noteDrawInfos) {
			if (event.noteSprite == info.sprite //make turn this into a func on the draw info so you dont have to update this when a new var is added
				&& event.noteSplash == info.splash
				&& event.strumID == info.strumID
			) {
				return i;
			}
		}

		var drawInfo = new NoteDrawInfo();
		drawInfo.strumID = event.strumID;
		drawInfo.scale = event.noteScale;
		drawInfo.sprite = event.noteSprite;
		drawInfo.splash = event.noteSplash;
		OptimizedNoteManager.noteDrawInfos.push(drawInfo);


		var noteSprite = drawInfo.noteSprite = new FlxSprite();
		noteSprite.frames = Paths.getFrames(event.noteSprite);
		noteSprite.animation.addByPrefix('scroll', event.noteAnimPrefix != null ? event.noteAnimPrefix : Flags.DEFAULT_NOTE_ANIM_PREFIXES[event.strumID % 4]);
		noteSprite.animation.play("scroll");
		noteSprite.scale.set(event.noteScale, event.noteScale);
		noteSprite.antialiasing = true;
		noteSprite.updateHitbox();

		//preload sprites
		if (PlayState.instance != null) {
			PlayState.instance.splashHandler.getSplashGroup(drawInfo.splash);
		}

		trace(noteDrawInfos.length-1);
		return OptimizedNoteManager.noteDrawInfos.length-1;
	}
	
	private static inline function getNoteType(id:Int) {
		if (PlayState.instance == null) return null;
		return PlayState.instance.getNoteType(id);
	}



	public static function createNote(strumLine:StrumLine, noteData:ChartNote) {
		var note = new OptimizedNote();

		note.strumTime = noteData.time.getDefault(0);
		note.strumID = noteData.id.getDefault(0);
		note.noteTypeID = noteData.type.getDefault(0);
		note.sustainLength = noteData.sLen.getDefault(0);
		note.noteDrawID = 0;
		
		var customType = Paths.image('game/notes/${getNoteType(note.noteTypeID)}');
		var event = EventManager.get(NoteCreationEvent).recycle(null,
			note.strumID,
			getNoteType(note.noteTypeID), 
			note.noteTypeID, 
			PlayState.instance.strumLines.members.indexOf(strumLine), 
			false,
			(getNoteType(note.noteTypeID) != null && @:privateAccess Note.customTypePathExists(customType)) ? 'game/notes/${getNoteType(note.noteTypeID)}' : 'game/notes/default', 
			@:privateAccess strumLine.strumScale * Flags.DEFAULT_NOTE_SCALE, 
			"default",
			"",
			null, null, null
		);

		if (PlayState.instance != null)
			event = PlayState.instance.gameAndCharsEvent("onNoteCreation", event);

		//this.animSuffix = event.animSuffix;
		if (!event.cancelled) {
			note.noteDrawID = OptimizedNoteManager.generateNoteDrawInfoID(event);
		}

		if (PlayState.instance != null) {
			PlayState.instance.gameAndCharsEvent("onPostNoteCreation", event);
		}

		return note;
	}
}