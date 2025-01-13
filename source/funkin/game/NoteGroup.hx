package funkin.game;

import funkin.game.Note.OptimizedNoteManager;
import funkin.game.Note.OptimizedNote;
import flixel.util.FlxSort;
import funkin.backend.system.Conductor;

/**
 * Group of notes, that handles updating and rendering only the visible notes.
 * To only get the visible notes you gotta do `group.forEach()` or `group.forEachAlive()` instead of `group.members`.
**/
class NoteGroup extends FlxTypedGroup<Note> {
	var __loopSprite:Note;
	var i:Int = 0;
	var __currentlyLooping:Bool = false;
	var __time:Float = -1.0;

	/**
	 * How many milliseconds it should show a note before it should be hit
	 **/
	public var limit:Float = Flags.DEFAULT_NOTE_MS_LIMIT;

	/**
	 * Preallocates the members array with nulls, but if theres anything in the array already it clears it
	 **/
	public inline function preallocate(len:Int) {
		members = cast new haxe.ds.Vector<Note>(len);
		length = len;
	}

	/**
	 * Adds an array of notes to the group, and sorts them.
	**/
	public inline function addNotes(notes:Array<Note>) {
		for(e in notes) add(e);
		sortNotes();
	}

	/**
	 * Sorts the notes in the group.
	**/
	public inline function sortNotes() {
		sort(function(i, n1, n2) {
			if (n1.strumTime == n2.strumTime)
				return n1.isSustainNote ? 1 : -1;
			return FlxSort.byValues(FlxSort.DESCENDING, n1.strumTime, n2.strumTime);
		});
	}

	@:dox(hide) public var __forcedSongPos:Null<Float> = null;

	@:dox(hide) private inline function __getSongPos()
		return __forcedSongPos == null ? Conductor.songPosition : __forcedSongPos;

	public override function update(elapsed:Float) {
		i = length-1;
		__loopSprite = null;
		__time = __getSongPos();
		while(i >= 0) {
			__loopSprite = members[i--];
			if (__loopSprite == null || !__loopSprite.exists || !__loopSprite.active) {
				continue;
			}
			if (__loopSprite.strumTime - __time > limit)
				break;
			__loopSprite.update(elapsed);
		}
	}

	public override function draw() @:privateAccess {
		var oldDefaultCameras = FlxCamera._defaultCameras;
		if (_cameras != null) FlxCamera._defaultCameras = _cameras;

		var oldCur = __currentlyLooping;
		__currentlyLooping = true;

		i = length-1;
		__loopSprite = null;
		__time = __getSongPos();
		while(i >= 0) {
			__loopSprite = members[i--];
			if (__loopSprite == null || !__loopSprite.exists || !__loopSprite.visible)
				continue;
			if (__loopSprite.strumTime - __time > limit) break;
			__loopSprite.draw();
		}
		__currentlyLooping = oldCur;

		FlxCamera._defaultCameras = oldDefaultCameras;
	}

	/**
	 * Gets the correct order of notes
	 **/
	public function get(id:Int) {
		return members[length - 1 - id];
	}

	public override function forEach(noteFunc:Note->Void, recursive:Bool = false) {
		i = length-1;
		__loopSprite = null;
		__time = __getSongPos();

		var oldCur = __currentlyLooping;
		__currentlyLooping = true;

		while(i >= 0) {
			__loopSprite = members[i--];
			if (__loopSprite == null || !__loopSprite.exists)
				continue;
			if (__loopSprite.strumTime - __time > limit) break;
			noteFunc(__loopSprite);
		}
		__currentlyLooping = oldCur;
	}
	public override function forEachAlive(noteFunc:Note->Void, recursive:Bool = false) {
		forEach(function(note) {
			if (note.alive) noteFunc(note);
		}, recursive);
	}

	public override function remove(Object:Note, Splice:Bool = false):Note
	{
		if (members == null)
			return null;

		var index:Int = members.lastIndexOf(Object);

		if (index < 0)
			return null;

		// doesn't prevent looping from breaking
		if (Splice && __currentlyLooping && i >= index)
			i++;

		if (Splice)
		{
			members.splice(index, 1);
			length--;
		}
		else
			members[index] = null;

		if (_memberRemoved != null)
			_memberRemoved.dispatch(Object);

		return Object;
	}
}


class OptimizedNoteGroup extends FlxBasic {

	private var strumLine:StrumLine;

	/**
	 * `Array` of all the members in this group.
	 */
	public var members(default, null):Array<OptimizedNote>;

	/**
	 * The number of entries in the members array. For performance and safety you should check this
	 * variable instead of `members.length` unless you really know what you're doing!
	*/
	public var length(default, null):Int = 0;

	public function new(strumLine:StrumLine)
	{
		super();
		this.strumLine = strumLine;
		members = [];
	}

	var __loopSprite:OptimizedNote;
	var i:Int = 0;
	var __currentlyLooping:Bool = false;
	var __time:Float = -1.0;

	/**
	 * How many milliseconds it should show a note before it should be hit
	 **/
	public var limit:Float = Flags.DEFAULT_NOTE_MS_LIMIT;

	/**
	 * Preallocates the members array with nulls, but if theres anything in the array already it clears it
	 **/
	public inline function preallocate(len:Int) {
		members = cast new haxe.ds.Vector<OptimizedNote>(len);
		length = len;
	}

	/**
	 * Adds an array of notes to the group, and sorts them.
	**/
	public inline function addNotes(notes:Array<OptimizedNote>) {
		for(e in notes) add(e);
		sortNotes();
	}

	/**
	 * Sorts the notes in the group.
	**/
	public inline function sortNotes() {
		sort(function(i, n1, n2) {
			return FlxSort.byValues(FlxSort.DESCENDING, n1.strumTime, n2.strumTime);
		});
	}

	@:dox(hide) public var __forcedSongPos:Null<Float> = null;

	@:dox(hide) private inline function __getSongPos()
		return __forcedSongPos == null ? Conductor.songPosition : __forcedSongPos;

	public override function update(elapsed:Float) {
		i = length-1;
		__loopSprite = null;
		__time = __getSongPos();
		while(i >= 0) {
			__loopSprite = members[i--];
			if (__loopSprite == null) {
				continue;
			}
			if (__loopSprite.strumTime - __time > limit)
				break;
			
			//update here, can update note sprites for animations
		}
	}

	public override function draw() @:privateAccess {
		var oldDefaultCameras = FlxCamera._defaultCameras;
		if (_cameras != null) FlxCamera._defaultCameras = _cameras;

		var oldCur = __currentlyLooping;
		__currentlyLooping = true;

		i = length-1;
		__loopSprite = null;
		__time = __getSongPos();
		while(i >= 0) {
			__loopSprite = members[i--];
			if (__loopSprite == null)
				continue;
			if (__loopSprite.strumTime - __time > limit) break;
		
			//draw here
			var drawInfo = OptimizedNoteManager.getNoteDrawInfo(__loopSprite.noteDrawID);
			if (__loopSprite.noteDrawID < 128) drawInfo.drawNote(__loopSprite, strumLine);
		}
		__currentlyLooping = oldCur;

		FlxCamera._defaultCameras = oldDefaultCameras;
	}

	/**
	 * Gets the correct order of notes
	 **/
	public function get(id:Int) {
		return members[length - 1 - id];
	}

	public function forEach(noteFunc:OptimizedNote->Void, recursive:Bool = false) {
		i = length-1;
		__loopSprite = null;
		__time = __getSongPos();

		var oldCur = __currentlyLooping;
		__currentlyLooping = true;

		while(i >= 0) {
			__loopSprite = members[i--];
			if (__loopSprite == null)
				continue;
			if (__loopSprite.strumTime - __time > limit) break;
			noteFunc(__loopSprite);
		}
		__currentlyLooping = oldCur;
	}

	public function remove(Object:OptimizedNote, Splice:Bool = false):OptimizedNote
	{
		if (members == null)
			return null;

		var index:Int = members.lastIndexOf(Object);

		if (index < 0)
			return null;

		// doesn't prevent looping from breaking
		if (Splice && __currentlyLooping && i >= index)
			i++;

		if (Splice)
		{
			members.splice(index, 1);
			length--;
		}
		else
			members[index] = null;

		return Object;
	}


	override public function destroy():Void
	{
		super.destroy();

		if (members != null)
		{
			var i:Int = 0;
			var basic:OptimizedNote = null;

			/*while (i < length)
			{
				members[i++] = null;
			}*/

			members = null;
		}
	}


	public function add(Object:OptimizedNote):OptimizedNote
	{
		if (Object == null)
		{
			return null;
		}

		// Don't bother adding an object twice.
		if (members.indexOf(Object) >= 0)
			return Object;

		// First, look for a null entry where we can add the object.
		var index:Int = getFirstNull();
		if (index != -1)
		{
			members[index] = Object;

			if (index >= length)
			{
				length = index + 1;
			}

			return Object;
		}

		// If we made it this far, we need to add the object to the group.
		members.push(Object);
		length++;

		return Object;
	}

	public function insert(position:Int, object:OptimizedNote):OptimizedNote
	{
		if (object == null)
		{
			return null;
		}

		// Don't bother inserting an object twice.
		if (members.indexOf(object) >= 0)
			return object;

		// First, look if the member at position is null, so we can directly assign the object at the position.
		if (position < length && members[position] == null)
		{
			members[position] = object;

			return object;
		}

		// If we made it this far, we need to insert the object into the group at the specified position.
		members.insert(position, object);
		length++;

		return object;
	}

	public inline function sort(Function:Int->OptimizedNote->OptimizedNote->Int, Order:Int = FlxSort.ASCENDING):Void
	{
		members.sort(Function.bind(Order));
	}

	public function getFirstNull():Int
	{
		var i:Int = 0;

		while (i < length)
		{
			if (members[i] == null)
				return i;
			i++;
		}

		return -1;
	}
}