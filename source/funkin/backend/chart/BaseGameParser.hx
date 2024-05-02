package funkin.backend.chart;

import funkin.backend.chart.ChartData.ChartMetaData;

// These new structures are kinda a mess to port, i love and hate them at the same time; why the hell are every difficulty in the same file???  - Nex
class BaseGameParser {
	public static function parseChart(data:Dynamic, metaData:Dynamic, result:ChartData) {
		// TO DO
	}

	public static function parseMeta(data:Dynamic, result:ChartMetaData) {
		var data:SwagMetadata = data;
		result.name = data.songName;

		var firstTimeChng:SwagTimeChange = data.timeChanges[0];
		result.bpm = firstTimeChng.bpm;
		result.beatsPerMeasure = firstTimeChng.b != null ? firstTimeChng.b : 4;

		result.difficulties = data.playData.difficulties;
	}

	public static function encodeMeta(meta:ChartMetaData):SwagMetadata {
		// TO DO
		return null;
	}

	public static function encodeChart(chart:ChartData):NewSwagSong {
		// TO DO
		return null;
	}
}

// METADATA STRUCTURES
typedef SwagMetadata =
{
	var timeFormat:String;
	var artist:String;
	var songName:String;
	var playData:SwagPlayData;
	var timeChanges:Array<SwagTimeChange>;
	var generatedBy:String;
	var looped:Bool;
	var version:String;
}

typedef SwagTimeChange =
{
	var d:Int;  // Time Signature Den
	var n:Int;  // Time Signature Num
	var t:Int;  // Time Stamp
	var ?b:Int;  // Beat Time
	var bt:Array<Int>;  // Beat Tuplets
	var bpm:Float;
}

typedef SwagPlayData =
{
	var album:String;
	var previewStart:Int;
	var previewEnd:Int;
	var stage:String;
	var characters:SwagCharactersList;
	var songVariations:Array<String>;
	var difficulties:Array<String>;
	var noteStyle:String;
}

typedef SwagCharactersList =
{
	var player:String;
	var girlfriend:String;
	var opponent:String;
}

// CHART STRUCTURE
typedef NewSwagSong =
{
	var version:String;
	var scrollSpeed:Dynamic;  // Map<String, Float>
	var events:Array<SwagEvent>;
	var notes:Dynamic;  // Map<String, Array<SwagNote>>
	var generatedBy:String;
}

typedef SwagEvent =
{
	var t:Float;  // Time
	var e:String;  // Event Kind
	var v:Dynamic;  // Value (Map<String, Dynamic>)
}

typedef SwagNote =
{
	var t:Float;  // Time
	var d:Int;  // Data
	var l:Float;  // Length
	var k:String;  // Kind
}