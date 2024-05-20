package funkin.backend.shaders;

import funkin.backend.scripting.events.shader.*;
import funkin.backend.scripting.Script;

/**
 * Class for scriptable shaders (extends the custom shaders class).
 *
 * To script a `CustomShader` just add the script file inside the `shaders` folder, named exactly like the vert/frag file(s) one.
 */
class ScriptableShader extends CustomShader {
	public var script:Script;

	/**
	 * Creates a new scriptable shader
	 * @param name Name of the frag/vert/script files.
	 * @param glslVersion GLSL version to use. Defaults to `120`.
	 */
	public function new(name:String, glslVersion:String = "120") {
		super(name, glslVersion);

		script = Script.create(Paths.script('shaders/$name'));
		script.setParent(this);
		script.load();
		script.call("create");

		FlxG.signals.preUpdate.add(function() this.update(FlxG.elapsed));
	}

	public function update(elapsed:Float) script.call("update", [elapsed]);

	@:noCompletion override private function __processGLData(source:String, storageType:String):Void {
		var event = EventManager.get(ShaderProcessEvent).recycle(source, storageType);
		script.call("process", [event]);
		if(!event.cancelled) super.__processGLData(event.source, event.storageType);
	}

	public function destroy() {
		script.call("destroy");
		script.destroy();
	}
}