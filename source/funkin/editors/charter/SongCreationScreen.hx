package funkin.editors.charter;

import haxe.io.Bytes;
import flixel.group.FlxGroup;
import flixel.text.FlxText.FlxTextFormat;
import funkin.editors.charter.CharterSelection.SongCreationData;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import funkin.backend.chart.ChartData.ChartMetaData;

class SongCreationScreen extends UIStepSubstateWindow {
	private var onSave:Null<SongCreationData> -> Void = null;

	public var songNameTextBox:UITextBox;
	public var bpmStepper:UINumericStepper;
	public var beatsPerMeasureStepper:UINumericStepper;
	public var stepsPerBeatStepper:UINumericStepper;
	public var instExplorer:UIFileExplorer;
	public var voicesExplorer:UIButtonList<UIFileExplorer>;

	public var displayNameTextBox:UITextBox;
	public var iconTextBox:UITextBox;
	public var iconSprite:FlxSprite;
	public var opponentModeCheckbox:UICheckbox;
	public var coopAllowedCheckbox:UICheckbox;
	public var colorWheel:UIColorwheel;
	public var difficulitesTextBox:UITextBox;

	public var songDataGroup:FlxGroup = new FlxGroup();
	public var menuDataGroup:FlxGroup = new FlxGroup();

	public function new(?onSave:SongCreationData->Void) {
		if(onSave != null) this.onSave = onSave;
		super("Save & Close", saveSongInfo);
	}

	public override function create() {
		winTitle = "Creating New Song";

		winWidth = 748 - 32 + 40;
		winHeight = 520;

		super.create();

		function addLabelOn(ui:UISprite, text:String):UIText {
			var text:UIText = new UIText(ui.x, ui.y - 24, 0, text);
			ui.members.push(text);
			return text;
		}

		var songTitle:UIText;
		songDataGroup.add(songTitle = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, "Song Info", 28));

		songNameTextBox = new UITextBox(songTitle.x, songTitle.y + songTitle.height + 36, "Song Name");
		songDataGroup.add(songNameTextBox);
		addLabelOn(songNameTextBox, "Song Name");

		bpmStepper = new UINumericStepper(songNameTextBox.x + 320 + 26, songNameTextBox.y, 100, 1, 2, 1, null, 90);
		songDataGroup.add(bpmStepper);
		addLabelOn(bpmStepper, "BPM");

		beatsPerMeasureStepper = new UINumericStepper(bpmStepper.x + 60 + 26, bpmStepper.y, 4, 1, 0, 1, null, 54);
		songDataGroup.add(beatsPerMeasureStepper);
		addLabelOn(beatsPerMeasureStepper, "Time Signature");

		songDataGroup.add(new UIText(beatsPerMeasureStepper.x + 30, beatsPerMeasureStepper.y + 3, 0, "/", 22));

		stepsPerBeatStepper = new UINumericStepper(beatsPerMeasureStepper.x + 30 + 24, beatsPerMeasureStepper.y, 4, 1, 0, 1, null, 54);
		songDataGroup.add(stepsPerBeatStepper);

		instExplorer = new UIFileExplorer(songNameTextBox.x, songNameTextBox.y + 32 + 36, null, null, Constants.SOUND_EXT, function (res) {
			instExplorer.members.push(instExplorer.uiElement = new UIAudioPlayer(0, 0, res));
			instExplorer.uiOffset.set(8, 8);
		});
		songDataGroup.add(instExplorer);
		addLabelOn(instExplorer, "Inst Audio File").applyMarkup(
			"Inst Audio File $* Required$",
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);

		function makeCoolExplorer():UIFileExplorer {
			var explorer:UIFileExplorer = null; explorer = new UIFileExplorer(0, 0, null, null, Constants.SOUND_EXT, function(res) {
				explorer.members.push(explorer.uiElement = new UIAudioPlayer(0, 0, res));
				explorer.uiOffset.set(8, 8);
			});
			return explorer;
		}

		songDataGroup.add(voicesExplorer = new UIButtonList<UIFileExplorer>(instExplorer.x + 320 + 26, instExplorer.y - 24, 340, 120, "Vocal Audio File", FlxPoint.get(320, 45)));
		voicesExplorer.members.remove(voicesExplorer.addIcon); voicesExplorer.addIcon = FlxDestroyUtil.destroy(voicesExplorer.addIcon); voicesExplorer.members.remove(voicesExplorer.addButton); voicesExplorer.addButton = FlxDestroyUtil.destroy(voicesExplorer.addButton); voicesExplorer.addButton = makeCoolExplorer();
		voicesExplorer.addButton.callback = function() voicesExplorer.add(makeCoolExplorer());
		voicesExplorer.members.push(voicesExplorer.addButton);

		var menuTitle:UIText;
		menuDataGroup.add(menuTitle = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, "Menus Data (Freeplay/Story)", 28));

		displayNameTextBox = new UITextBox(menuTitle.x, menuTitle.y + menuTitle.height + 36, "Display Name");
		menuDataGroup.add(displayNameTextBox);
		addLabelOn(displayNameTextBox, "Display Name");

		iconTextBox = new UITextBox(displayNameTextBox.x + 320 + 26, displayNameTextBox.y, "Icon", 150);
		iconTextBox.onChange = (newIcon:String) -> {updateIcon(newIcon);}
		menuDataGroup.add(iconTextBox);
		addLabelOn(iconTextBox, "Icon");

		updateIcon("Icon");

		opponentModeCheckbox = new UICheckbox(displayNameTextBox.x, iconTextBox.y + 10 + 32 + 26, "Opponent Mode", true);
		menuDataGroup.add(opponentModeCheckbox);
		addLabelOn(opponentModeCheckbox, "Modes Allowed");

		coopAllowedCheckbox = new UICheckbox(opponentModeCheckbox.x + 150 + 26, opponentModeCheckbox.y, "Co-op Mode", true);
		menuDataGroup.add(coopAllowedCheckbox);

		colorWheel = new UIColorwheel(iconTextBox.x, coopAllowedCheckbox.y, 0xFFFFFF);
		menuDataGroup.add(colorWheel);
		addLabelOn(colorWheel, "Color");

		difficulitesTextBox = new UITextBox(opponentModeCheckbox.x, opponentModeCheckbox.y + 6 + 32 + 26, "");
		menuDataGroup.add(difficulitesTextBox);
		addLabelOn(difficulitesTextBox, "Difficulties");

		for (checkbox in [opponentModeCheckbox, coopAllowedCheckbox])
			{checkbox.y += 6; checkbox.x += 4;}

		addPage(songDataGroup, FlxPoint.get(winWidth, 340));
		addPage(menuDataGroup, FlxPoint.get(winWidth, 400));
	}

	public override function update(elapsed:Float) {
		finishButton.selectable = curPage == 0 ? instExplorer.file != null : true;
		super.update(elapsed);
	}

	function updateIcon(icon:String) {
		if (iconSprite == null) menuDataGroup.add(iconSprite = new FlxSprite());

		if (iconSprite.animation.exists(icon)) return;
		@:privateAccess iconSprite.animation.clearAnimations();

		var path:String = Paths.image('icons/$icon');
		if (!Assets.exists(path)) path = Paths.image('icons/face');

		iconSprite.loadGraphic(path, true, 150, 150);
		iconSprite.animation.add(icon, [0], 0, false);
		iconSprite.antialiasing = true;
		iconSprite.animation.play(icon);

		iconSprite.scale.set(0.5, 0.5);
		iconSprite.updateHitbox();
		iconSprite.setPosition(iconTextBox.x + 150 + 8, (iconTextBox.y + 16) - (iconSprite.height/2));
	}

	function saveSongInfo() {
		for (stepper in [bpmStepper, beatsPerMeasureStepper, stepsPerBeatStepper])
			@:privateAccess stepper.__onChange(stepper.label.text);

		var meta:ChartMetaData = {
			name: songNameTextBox.label.text,
			bpm: bpmStepper.value,
			beatsPerMeasure: Std.int(beatsPerMeasureStepper.value),
			stepsPerBeat: Std.int(stepsPerBeatStepper.value),
			displayName: displayNameTextBox.label.text,
			icon: iconTextBox.label.text,
			color: colorWheel.curColorString,
			parsedColor: colorWheel.curColor,
			opponentModeAllowed: opponentModeCheckbox.checked,
			coopAllowed: coopAllowedCheckbox.checked,
			difficulties: [for (diff in difficulitesTextBox.label.text.split(",")) diff.trim()],
		};

		var voices:Map<String, Bytes> = [];
		for(button in voicesExplorer.buttons) if(button.file != null) voices.set("yes", button.file);

		if (onSave != null) onSave({
			meta: meta,
			instBytes: instExplorer.file,
			voicesBytes: voices
		});
	}

}