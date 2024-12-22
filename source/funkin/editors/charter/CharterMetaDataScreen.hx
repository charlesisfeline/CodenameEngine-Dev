package funkin.editors.charter;

import flixel.math.FlxPoint;
import funkin.backend.chart.ChartData.ChartMetaData;
import funkin.editors.extra.PropertyButton;

using StringTools;

class CharterMetaDataScreen extends UISubstateWindow {
	public var metadata:ChartMetaData;
	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public var songNameTextBox:UITextBox;
	public var bpmStepper:UINumericStepper;
	public var beatsPerMeasureStepper:UINumericStepper;
	public var stepsPerBeatStepper :UINumericStepper;
	public var customPropertiesButtonList:UIButtonList<PropertyButton>;

	public var displayNameTextBox:UITextBox;
	public var iconTextBox:UITextBox;
	public var iconSprite:FlxSprite;
	public var excludedGameModesList:UIAutoCompleteButtonList;
	public var colorWheel:UIColorwheel;
	public var difficultiesTextBox:UITextBox;

	public function new(metadata:ChartMetaData) {
		super();
		this.metadata = metadata;
	}

	public override function create() {
		winTitle = "Edit Metadata";
		winWidth = 1056;
		winHeight = 520;

		super.create();

		FlxG.sound.music.pause();
		Charter.instance.vocals.pause();
		for (strumLine in Charter.instance.strumLines.members) strumLine.vocals.pause();

		function addLabelOn(ui:UISprite, text:String)
			add(new UIText(ui.x, ui.y - 24, 0, text));

		var title:UIText;
		add(title = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, "Song Data", 28));

		songNameTextBox = new UITextBox(title.x, title.y + title.height + 36, metadata.name);
		add(songNameTextBox);
		addLabelOn(songNameTextBox, "Song Name");

		bpmStepper = new UINumericStepper(songNameTextBox.x + 320 + 26, songNameTextBox.y, metadata.bpm, 1, 2, 1, null, 90);
		add(bpmStepper);
		addLabelOn(bpmStepper, "BPM");

		beatsPerMeasureStepper = new UINumericStepper(bpmStepper.x + 60 + 26, bpmStepper.y, metadata.beatsPerMeasure, 1, 0, 1, null, 54);
		add(beatsPerMeasureStepper);
		addLabelOn(beatsPerMeasureStepper, "Time Signature");

		add(new UIText(beatsPerMeasureStepper.x + 30, beatsPerMeasureStepper.y + 3, 0, "/", 22));

		stepsPerBeatStepper = new UINumericStepper(beatsPerMeasureStepper.x + 30 + 24, beatsPerMeasureStepper.y, metadata.stepsPerBeat, 1, 0, 1, null, 54);
		add(stepsPerBeatStepper);

		add(title = new UIText(songNameTextBox.x, songNameTextBox.y + 10 + 46, 0, "Menus Data (Freeplay/Story)", 28));

		displayNameTextBox = new UITextBox(title.x, title.y + title.height + 36, metadata.displayName);
		add(displayNameTextBox);
		addLabelOn(displayNameTextBox, "Display Name");

		iconTextBox = new UITextBox(displayNameTextBox.x + 320 + 26, displayNameTextBox.y, metadata.icon, 150);
		iconTextBox.onChange = (newIcon:String) -> {updateIcon(newIcon);}
		add(iconTextBox);
		addLabelOn(iconTextBox, "Icon");

		updateIcon(metadata.icon);

		add(excludedGameModesList = new UIAutoCompleteButtonList(displayNameTextBox.x, iconTextBox.y + 62, Std.int(displayNameTextBox.bWidth), 100, "", [for (mode in funkin.menus.FreeplayState.FreeplayGameMode.get()) mode.modeID]));
		excludedGameModesList.frames = Paths.getFrames('editors/ui/inputbox');
		excludedGameModesList.cameraSpacing = 0;
		addLabelOn(excludedGameModesList, "Excluded Game Modes (IDs)");
		for (mode in metadata.excludedGameModes)
			excludedGameModesList.add(new UIAutoCompleteButtonList.UIAutoCompleteButton(0, 0, excludedGameModesList, excludedGameModesList.suggestItems, mode));

		colorWheel = new UIColorwheel(iconTextBox.x, excludedGameModesList.y, metadata.parsedColor);
		add(colorWheel);
		addLabelOn(colorWheel, "Color");

		difficultiesTextBox = new UITextBox(excludedGameModesList.x, excludedGameModesList.y + excludedGameModesList.bHeight + 32, metadata.difficulties.join(", "));
		add(difficultiesTextBox);
		addLabelOn(difficultiesTextBox, "Difficulties");

		customPropertiesButtonList = new UIButtonList<PropertyButton>(stepsPerBeatStepper.x + 80 + 26 + 105, songNameTextBox.y, 290, 316, '', FlxPoint.get(280, 35), null, 5);
		customPropertiesButtonList.frames = Paths.getFrames('editors/ui/inputbox');
		customPropertiesButtonList.cameraSpacing = 0;
		customPropertiesButtonList.addButton.callback = function() {
			customPropertiesButtonList.add(new PropertyButton("newProperty", "valueHere", customPropertiesButtonList));
		}
		for (val in Reflect.fields(metadata.customValues))
			customPropertiesButtonList.add(new PropertyButton(val, Reflect.field(metadata.customValues, val), customPropertiesButtonList));
		add(customPropertiesButtonList);
		addLabelOn(customPropertiesButtonList, "Custom Values (Advanced)");

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y + windowSpr.bHeight - 20, "Save & Close", function() {
			saveMeta();
			close();
		}, 125);
		saveButton.x -= saveButton.bWidth;
		saveButton.y -= saveButton.bHeight;

		closeButton = new UIButton(saveButton.x - 20, saveButton.y, "Close", function() {
			close();
		}, 125);
		closeButton.color = 0xFFFF0000;
		closeButton.x -= closeButton.bWidth;
		//closeButton.y -= closeButton.bHeight;
		add(closeButton);
		add(saveButton);
	}

	function updateIcon(icon:String) {
		if (iconSprite == null) add(iconSprite = new FlxSprite());

		if (iconSprite.animation.exists(icon)) return;
		@:privateAccess iconSprite.animation.clearAnimations();

		var path:String = Paths.image('icons/$icon');
		if (!Assets.exists(path)) path = Paths.image('icons/' + Flags.DEFAULT_HEALTH_ICON);

		iconSprite.loadGraphic(path, true, 150, 150);
		iconSprite.animation.add(icon, [0], 0, false);
		iconSprite.antialiasing = true;
		iconSprite.animation.play(icon);

		iconSprite.scale.set(0.5, 0.5);
		iconSprite.updateHitbox();
		iconSprite.setPosition(iconTextBox.x + 150 + 8, (iconTextBox.y + 16) - (iconSprite.height/2));
	}

	public function saveMeta() {
		for (stepper in [bpmStepper, beatsPerMeasureStepper, stepsPerBeatStepper])
			@:privateAccess stepper.__onChange(stepper.label.text);

		var customVals = {};
		for (vals in customPropertiesButtonList.buttons.members) {
			Reflect.setProperty(customVals, vals.propertyText.label.text, vals.valueText.label.text);
		}

		PlayState.SONG.meta = {
			name: songNameTextBox.label.text,
			bpm: bpmStepper.value,
			beatsPerMeasure: Std.int(beatsPerMeasureStepper.value),
			stepsPerBeat: Std.int(stepsPerBeatStepper.value),
			displayName: displayNameTextBox.label.text,
			icon: iconTextBox.label.text,
			color: colorWheel.curColorString,
			parsedColor: colorWheel.curColor,
			excludedGameModes: [for (button in excludedGameModesList.buttons.members) button.textBox.label.text.trim()],
			difficulties: [for (diff in difficultiesTextBox.label.text.split(",")) diff.trim()],
			customValues: customVals,
		};

		Charter.instance.updateBPMEvents();
	}
}