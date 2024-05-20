import openfl.display.ShaderParameter;

// Took the one inside the BaseGame source as a base  - Nex
var rainShader:CustomShader = null;
// var blurFilter:BlurFilter = new BlurFilter(6, 6);

// var rainSndAmbience:FunkinSound;

// as song goes on, these are used to make the rain more intense throught the song
// these values are also used for the rain sound effect volume intensity!
public var rainShaderStartIntensity:Float = 0;
public var rainShaderEndIntensity:Float = 0.1;

static final RAINSHADER_MAX_LIGHTS:Int = 8;
public var rainShaderLights:Array<{ position:Float, color:Float, radius:Float }>;

var rainEffectTime:Float = 1;
function set_time(value:Float):Float
{
	rainShader?.uTime = value;
	return rainEffectTime = value;
}

// The scale of the rain depends on the world coordinate system, so higher resolution makes
// the raindrops smaller. This parameter can be used to adjust the total scale of the scene.
// The size of the raindrops is proportional to the value of this parameter.
public var rainEffectScale:Float = 1;
function set_scale(value:Float):Float
{
	rainShader?.uScale = value;
	return rainEffectScale = value;
}

// The intensity of the rain. Zero means no rain and one means the maximum amount of rain.
public var rainEffectIntensity:Float = 0.5;
function set_intensity(value:Float):Float
{
	rainShader?.uIntensity = value;
	return rainEffectIntensity = value;
}

// the y coord of the puddle, used to mirror things
public var rainEffectPuddleY:Float = 0;
function set_puddleY(value:Float):Float
{
	rainShader?.uPuddleY = value;
	return rainEffectPuddleY = value;
}

// the y scale of the puddle, the less this value the more the puddle effects squished
public var rainEffectPuddleScaleY:Float = 0;
function set_puddleScaleY(value:Float):Float
{
	rainShader?.uPuddleScaleY = value;
	return rainEffectPuddleScaleY = value;
}

public var rainEffectBlurredScreen:BitmapData;
function set_blurredScreen(value:BitmapData):BitmapData
{
	rainShader?.uBlurredScreen = value;
	return rainEffectBlurredScreen = value;
}

public var rainEffectMask:BitmapData;
function set_mask(value:BitmapData):BitmapData
{
	rainShader?.uMask = value;
	return rainEffectMask = value;
}

public var rainEffectLightMap:BitmapData;
function set_lightMap(value:BitmapData):BitmapData
{
	rainShader?.uLightMap = value;
	return rainEffectLightMap = value;
}

public var rainEffectNumLights:Int = 0; // swag heads, we have never been more back (needs different name purely for hashlink casting fix)
function set_numLightsSwag(value:Int):Int
{
	rainShader?.numLights = value;
	return rainEffectNumLights = value;
}

function postCreate()
{
	if(!Options.gameplayShaders)
	{
		disableScript();
		return;
	}

	// rainSndAmbience = FunkinSound.load(Paths.sound("rainAmbience", "weekend1"), true, false, true);
	// rainSndAmbience.volume = 0;
	// rainSndAmbience.play(false, FlxG.random.float(0, rainSndAmbience.length));

	camGame.addShader(rainShader = new CustomShader('rainShader'));
	// puddleMap = Assets.getBitmapData(Paths.image("phillyStreets/puddle"));
	rainEffectScale = FlxG.height / 200; // adjust this value so that the rain looks nice
	rainEffectIntensity = rainShaderStartIntensity;
	FlxG.console.registerObject("rainShader", rainShader);

	// camGame.addShader(new openfl.filters.BlurFilter(16,16));

	// set the shader input
	//rainShader.mask = frameBufferMan.getFrameBuffer("mask");
	//rainShader.lightMap = frameBufferMan.getFrameBuffer("lightmap");
}

/*function setupFrameBuffers()
{
	//frameBufferMan.createFrameBuffer("mask", 0xFF000000);
	//frameBufferMan.createFrameBuffer("lightmap", 0xFF000000);
}

var screen:FixedBitmapData;
function draw(_)
{
	//screen = grabScreen(false);
	//BitmapDataUtil.applyFilter(screen, blurFilter);
	//blurredScreen = screen;
}*/

function update(elapsed:Float)
{
	rainEffectIntensity = FlxMath.remapToRange(Conductor.songPosition, 0, FlxG.sound.music != null ? FlxG.sound.music.length : 0.0, rainShaderStartIntensity, rainShaderEndIntensity);
	rainEffectTime += elapsed;

	// if (rainSndAmbience != null) {
	// 	rainSndAmbience.volume = Math.min(0.3, remappedIntensityValue * 2);
	// }
}

function onGameOver(_)
{
	// Make it so the rain shader doesn't show over the game over screen
	if (rainShader != null) FlxG.camera.removeShader(rainShader);
}

/*function onStageNodeParsed(event)
{
	if (event.sprite is FunkinSprite && event.sprite.name == "puddle" && rainShader != null)
	{
		rainShader.puddleY = event.sprite.y + 80;
		rainShader.puddleScaleY = 0.3;
		//frameBufferMan.copySpriteTo("mask", event.sprite, 0xFFFFFF);
	}
	else
	{
		//frameBufferMan.copySpriteTo("mask", event.sprite, 0x000000);
	}
}

function addCharacter(character:BaseCharacter, charType:CharacterType)
{
	// add to the mask so that characters hide puddles
	// frameBufferMan.copySpriteTo("mask", character, 0x000000);
}

function destroy()
{
	// Fully stop ambiance.
	// if (rainSndAmbience != null) rainSndAmbience.stop();
}*/

/*class RuntimeRainShader extends RuntimePostEffectShader
{
  override function __processGLData(source:String, storageType:String):Void
  {
    super.__processGLData(source, storageType);
    if (storageType == 'uniform')
    {
      lights = [
        for (i in 0...MAX_LIGHTS)
          {
            position: addFloatUniform('lights[$i].position', 2),
            color: addFloatUniform('lights[$i].color', 3),
            radius: addFloatUniform('lights[$i].radius', 1),
          }
      ];
    }
  }

  @:access(openfl.display.ShaderParameter)
  function addFloatUniform(name:String, length:Int):ShaderParameter<Float>
  {
    final res = new ShaderParameter<Float>();
    res.name = name;
    res.type = [null, FLOAT, FLOAT2, FLOAT3, FLOAT4][length];
    res.__arrayLength = 1;
    res.__isFloat = true;
    res.__isUniform = true;
    res.__length = length;
    __paramFloat.push(res);
    return res;
  }
}*/