package funkin.editors.charter;

import funkin.editors.ui.UIAutoCompleteButtonList.UITypedAutoCompleteButtonList;
import funkin.editors.ui.UIAutoCompleteButtonList.UIAutoCompleteButton;
import flixel.math.FlxPoint;
import funkin.backend.chart.ChartData.ChartStrumLine;
import funkin.game.Character;
import funkin.game.HealthIcon;

class CharterStrumlineScreen extends UISubstateWindow {
	public var strumLineID:Int = -1;
	public var strumLine:ChartStrumLine;

	public var charactersList:UITypedAutoCompleteButtonList<CharacterButton>;
	public var typeDropdown:UIDropDown;
	public var vocalsSuffixDropDown:UIDropDown;
	public var stagePositionDropdown:UIDropDown;
	public var hudScaleStepper:UINumericStepper;
	public var hudXStepper:UINumericStepper;
	public var hudYStepper:UINumericStepper;
	public var visibleCheckbox:UICheckbox;
	public var scrollSpeedStepper:UINumericStepper;
	public var usesChartScrollSpeed:UICheckbox;

	public var saveButton:UIButton;
	public var closeButton:UIButton;

	private var onSave:ChartStrumLine -> Void = null;

	public function new(strumLineID:Int, strumLine:ChartStrumLine, ?onSave:ChartStrumLine->Void) {
		super();
		this.strumLineID = strumLineID;
		this.strumLine = strumLine;
		if (onSave != null) this.onSave = onSave;
	}

	public override function create() {
		var creatingStrumLine:Bool = strumLine == null;

		if (creatingStrumLine)
			strumLine = {
				characters: [Flags.DEFAULT_OPPONENT],
				type: OPPONENT,
				notes: [],
				position: "dad",
				visible: true
			};

		winTitle = creatingStrumLine ? 'Creating strumline #$strumLineID' : 'Editing strumline #$strumLineID properties';
		winWidth = 690; winHeight = 400;

		FlxG.sound.music.pause();
		Charter.instance.vocals.pause();
		for (strumLine in Charter.instance.strumLines.members) strumLine.vocals.pause();

		super.create();

		function addLabelOn(ui:UISprite, text:String)
			add(new UIText(ui.x, ui.y - 24, 0, text));

		var title:UIText;
		add(title = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, creatingStrumLine ? "Create New Strumline" : "Edit Strumline Properties", 28));

		var charFileList = Character.getList(true);
		if (charFileList.length == 0) charFileList = Character.getList(false);

		charactersList = new UITypedAutoCompleteButtonList<CharacterButton>(15, title.y + title.height + 36, 250, 269, "", FlxPoint.get(250, 54), null, 0);
		charactersList.addButton.callback = () -> charactersList.add(new CharacterButton(0, 0, "New Char", charFileList, charactersList));
		charactersList.cameraSpacing = 0;
		for (i in strumLine.characters)
			charactersList.add(new CharacterButton(0, 0, i, charFileList, charactersList));
		add(charactersList);
		addLabelOn(charactersList, "Characters");

		charactersList.frames = Paths.getFrames('editors/ui/inputbox');

		typeDropdown = new UIDropDown(charactersList.x + charactersList.bWidth + 16, charactersList.y, 200, 32, ["OPPONENT", "PLAYER", "ADDITIONAL"], strumLine.type);
		add(typeDropdown);
		addLabelOn(typeDropdown, "Type");

		usesChartScrollSpeed = new UICheckbox(typeDropdown.x + 104, typeDropdown.y + 135, "Uses charts scroll speed?", strumLine.scrollSpeed == null);
		usesChartScrollSpeed.onChecked = function(b) {
			if(b)
			{
				scrollSpeedStepper.value = PlayState.SONG.scrollSpeed;
				scrollSpeedStepper.selectable = false;
			} else {
				scrollSpeedStepper.selectable = true;
			}
		}
		add(usesChartScrollSpeed);

		scrollSpeedStepper = new UINumericStepper(typeDropdown.x, typeDropdown.y + 128, usesChartScrollSpeed.checked ? PlayState.SONG.scrollSpeed : strumLine.scrollSpeed, 0.1, 2, 0, 10, 82);
		if(usesChartScrollSpeed.checked)
		{
			scrollSpeedStepper.selectable = false;
		} else {
			scrollSpeedStepper.selectable = true;
		}
		add(scrollSpeedStepper);
		addLabelOn(scrollSpeedStepper, "Scroll Speed");

		var stagePositionI = strumLine.position == null ? strumLine.type : ["DAD", "BOYFRIEND", "GIRLFRIEND"].indexOf(strumLine.position.toUpperCase());

		stagePositionDropdown = new UIDropDown(typeDropdown.x + 200 - 32 + 26, typeDropdown.y, 200, 32, ["DAD", "BOYFRIEND", "GIRLFRIEND"], stagePositionI);
		add(stagePositionDropdown);
		addLabelOn(stagePositionDropdown, "Stage Position");

		hudScaleStepper = new UINumericStepper(typeDropdown.x, typeDropdown.y + 64, strumLine.strumScale == null ? 1 : strumLine.strumScale, 0.001, 2, null, null, 74);
		add(hudScaleStepper);
		addLabelOn(hudScaleStepper, "Scale");

		var strOffset:Float = strumLine.strumLinePos == null ? (strumLine.type == 1 ? 0.75 : 0.25) : strumLine.strumLinePos;

		var startingPos:FlxPoint = strumLine.strumPos == null ?
			FlxPoint.get(strOffset, 50) :
			FlxPoint.get(strOffset, strumLine.strumPos[1]);

		hudXStepper = new UINumericStepper(hudScaleStepper.x + 80 - 32 + 26, hudScaleStepper.y, startingPos.x, 0.01, 2, 0, 2, 84);
		add(hudXStepper);
		addLabelOn(hudXStepper, "Hud Position (X [Ratio 0-1],Y)");

		add(new UIText(hudXStepper.x + 84 - 32 + 0, hudXStepper.y + 9, 0, ",", 22));

		hudYStepper = new UINumericStepper(hudXStepper.x + 84 - 32 + 26, hudXStepper.y, startingPos.y, 0.001, 2, null, null, 84);
		add(hudYStepper);

		visibleCheckbox = new UICheckbox(hudYStepper.x + hudYStepper.bWidth + 42, hudYStepper.y + 9, "Visible?", strumLine.visible);
		add(visibleCheckbox);

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, "Save & Close", function() {
			saveStrumline();
			close();
		}, 125);
		add(saveButton);

		closeButton = new UIButton(saveButton.x - 20 - saveButton.bWidth, saveButton.y, creatingStrumLine ? "Cancel" : "Close", function() {
			if (creatingStrumLine && onSave != null) onSave(null);
			close();
		}, 125);
		add(closeButton);
		closeButton.color = 0xFFFF0000;

		var suffixList = ["NONE"];
		for (i in Paths.getFolderContent('songs/${Charter.__song.toLowerCase()}/song'))
		if (i.startsWith("Voices")) {
			i = haxe.io.Path.withoutExtension(i.substr("Voices".length));
			if (i == "") continue;
			for (j in PlayState.SONG.meta.difficulties) {
				if (i.endsWith('-${j.toLowerCase()}'))
					suffixList.pushOnce(i.substring(0, i.length - j.length));
				else
					suffixList.pushOnce(i);
			}
		}

		vocalsSuffixDropDown = new UIDropDown(typeDropdown.x, hudScaleStepper.y + 128, 200, 32, suffixList, strumLine.vocalsSuffix != null && strumLine.vocalsSuffix != "" ? suffixList.indexOf(strumLine.vocalsSuffix) : 0);
		add(vocalsSuffixDropDown);
		addLabelOn(vocalsSuffixDropDown, "Vocal Suffix");
	}

	function saveStrumline() {
		for (stepper in [hudXStepper, hudYStepper, hudScaleStepper])
			@:privateAccess stepper.__onChange(stepper.label.text);

		var newStrumLine:ChartStrumLine = {
			characters: [
				for (char in charactersList.buttons.members)
					char.textBox.label.text.trim()
			],
			type: typeDropdown.index,
			notes: strumLine.notes,
			position: ["DAD", "BOYFRIEND", "GIRLFRIEND"][stagePositionDropdown.index].toLowerCase(),
			visible: visibleCheckbox.checked,
			strumPos: [0, hudYStepper.value],
			strumLinePos: hudXStepper.value,
			strumScale: hudScaleStepper.value,
			vocalsSuffix: vocalsSuffixDropDown.options[vocalsSuffixDropDown.index] != "NONE" ? vocalsSuffixDropDown.options[vocalsSuffixDropDown.index] : ""
		};
		if(!usesChartScrollSpeed.checked) newStrumLine.scrollSpeed = scrollSpeedStepper.value;
		if (onSave != null) onSave(newStrumLine);
	}
}

class CharacterButton extends UIAutoCompleteButton {
	public var charIcon:HealthIcon;

	public function new(x:Float, y:Float, char:String, charsList:Array<String>, parent:UITypedAutoCompleteButtonList<CharacterButton>, iconScale:Float = 0.3, ?w:Int, ?h:Int, multiline:Bool = false) {
		super(x, y, cast parent, charsList, char, w, h, multiline);

		members.push(charIcon = new HealthIcon(Character.getIconFromCharName(char)));
		charIcon.scale.set(iconScale, iconScale);
		charIcon.updateHitbox();
		charIcon.setPosition(x + 10, bHeight / 2 - charIcon.height / 2);
		charIcon.scrollFactor.set(1, 1);

		var distance = 40 * iconScale;
		deleteButton.setPosition(bWidth - distance - deleteButton.bWidth, bHeight / 2 - distance);
		textBox.bWidth = Std.int(bWidth - charIcon.x - charIcon.width - distance - deleteButton.bWidth - distance - 10);
		textBox.setPosition(charIcon.x + charIcon.width + distance, bHeight / 2 - distance);
		textBox.onChange = (char:String) -> charIcon.setIcon(Character.getIconFromCharName(char));
	}

	override function update(elapsed) {
		charIcon.y = y + bHeight / 2 - charIcon.height / 2;
		super.update(elapsed);
	}
}