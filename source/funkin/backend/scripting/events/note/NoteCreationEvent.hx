package funkin.backend.scripting.events.note;

import funkin.game.Note;
import funkin.game.Note.NoteObject;

final class NoteCreationEvent extends CancellableEvent {
	/**
	 * Note that is being created
	 */
	public var note:NoteObject;

	/**
	 * ID of the strum (from 0 to 3)
	 */
	public var strumID:Int;

	/**
	 * Note Type (ex: "My Super Cool Note", or "Mine")
	 */
	public var noteType:String;

	/**
	 * ID of the note type.
	 */
	public var noteTypeID:Int;

	/**
	 * ID of the player.
	 */
	public var strumLineID:Int;

	/**
	 * Whenever the note will need to be hit by the player
	 */
	public var mustHit:Bool;

	/**
	 * Note sprite, if you only want to replace the sprite.
	 */
	public var noteSprite:String;

	/**
	 * Note scale, if you only want to replace the scale.
	 */
	public var noteScale:Float;

	/**
	 * Note splash, if you only want to replace the splash.
	 */
	public var noteSplash:String;

	/**
	 * Sing animation suffix. "-alt" for alt anim or "" for normal notes.
	 */
	public var animSuffix:String;

	/**
	 * Note animation prefix.
	 */
	public var noteAnimPrefix:String = null;

	/**
	 * Sustain animation prefix.
	 */
	public var sustainAnimPrefix:String = null;

	/**
	 * Sustain End animation prefix.
	 */
	public var sustainEndAnimPrefix:String = null;
}