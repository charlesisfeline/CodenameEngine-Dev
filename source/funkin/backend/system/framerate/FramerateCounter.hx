package funkin.backend.system.framerate;

import lime.app.Application;
import haxe.ds.Vector;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

inline final FRAME_TIME_HISTORY = 20;

class FramerateCounter extends Sprite {
	public var fpsNum:TextField;
	public var fpsLabel:TextField;

	public var fpsHistoryIndex:Int = 0;
	public var fpsHistory:Vector<Float>;
	public var cpuHistory:Vector<Float>;

	public function new() {
		super();

		fpsHistory = new Vector(FRAME_TIME_HISTORY);
		cpuHistory = new Vector(FRAME_TIME_HISTORY);
		// Initialize to 60 FPS, so that the initial estimation until we get enough data is always reasonable.
		for(i in 0...FRAME_TIME_HISTORY) {
			fpsHistory[i] = 1000.0 / 60.0;
			cpuHistory[i] = 1000.0 / 60.0;
		}

		fpsNum = new TextField();
		fpsLabel = new TextField();

		for(label in [fpsNum, fpsLabel]) {
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 0;
			label.text = "FPS";
			label.multiline = label.wordWrap = false;
			label.defaultTextFormat = new TextFormat(Framerate.fontName, label == fpsNum ? 18 : 12, -1);
			addChild(label);
		}
	}

	public var iii = 0;

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		super.__enterFrame(t);

		var gpuTimeFrame:Float;
		var cpuTimeFrame:Float;

		//#if cpp
		var app = FlxG.stage;//@:privateAccess Application.current.__backend;
		//gpuTimeFrame = app.lastRenderEnd - app.lastRenderStart;
		cpuTimeFrame = app.latestUpdate - app.lastUpdate;
		gpuTimeFrame = app.lastRenderEnd - app.lastRenderStart;
		//trace(gpuTimeFrame, app.curRenderEnd, app.lastRenderStart);
		//#else
		//gpuTimeFrame = FlxG.elapsed * 1000;
		//#end

		fpsHistory[fpsHistoryIndex] = gpuTimeFrame;
		cpuHistory[fpsHistoryIndex] = cpuTimeFrame;
		fpsHistoryIndex = (fpsHistoryIndex + 1) % FRAME_TIME_HISTORY;

		// Calculate average frame time.
		// Code based on Godot's FPS counter.
		var frameTime = 0.0;
		var cpuTime = 0.0;
		for(i in 0...FRAME_TIME_HISTORY) {
			frameTime += fpsHistory[i];
			cpuTime += cpuHistory[i];
		}
		frameTime /= FRAME_TIME_HISTORY;
		cpuTime /= FRAME_TIME_HISTORY;
		frameTime = Math.max(0.01, frameTime); // Prevent unrealistically low values.
		cpuTime = Math.max(0.01, cpuTime);

		fpsNum.text = Std.string(Math.floor(1000.0 / frameTime)) + "\nCPU: " + Math.floor(1000.0 / cpuTime) + "fps\nframe:" + iii++ + "\nCPU Start: " + app.latestUpdate + "\nCPU End: " + app.lastUpdate + "\nGPU Start: " + app.lastRenderStart + "\nGPU End: " + app.lastRenderEnd;
		fpsLabel.x = fpsNum.x + fpsNum.width;
		fpsLabel.y = (fpsNum.y + fpsNum.height) - fpsLabel.height;
	}
}