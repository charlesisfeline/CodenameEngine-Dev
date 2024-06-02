package funkin.editors.charter;

import flixel.group.FlxGroup;
import funkin.editors.charter.CharterSelection.SongCreationData;

class SongImportScreen extends UIStepSubstateWindow {
	private var onSave:Null<SongCreationData> -> Void = null;

	public var title:UIText;
	public var formats:UIButtonList<UIButton>;
	public var fullyImportCheckbox:UICheckbox;

	public var selectionDataGroup:FlxGroup = new FlxGroup();

	public function new(?onSave:SongCreationData->Void) {
		if(onSave != null) this.onSave = onSave;
		super("Import & Close");
	}

	public override function create() {
		winTitle = "Importing a Song";

		winWidth = 748 - 32 + 40;
		winHeight = 220;

		super.create();

		var daWidth = Std.int(winWidth / 2);
		selectionDataGroup.add(formats = new UIButtonList<UIButton>(20, 40, daWidth, winHeight - 60, "Select a format", FlxPoint.get(daWidth, 20)));
		formats.addButton.visible = false;

		selectionDataGroup.add(title = new UIText(formats.x + daWidth + 20, formats.y + 5, 0, "", 28));
		selectionDataGroup.add(fullyImportCheckbox = new UICheckbox(title.x - 5, title.y + title.height + 30, "Fully convert to Codename's Format", true));

		for(format in Constants.SUPPORTED_CHART_RUNTIME_FORMATS) {
			var button = new UIButton(0, 0, format, function() {
				title.text = format;
				fullyImportCheckbox.checkable = true;
				fullyImportCheckbox.field.alpha = 1;
			}, daWidth);
			button.autoAlpha = false;
			formats.add(button);
		}

		for(format in Constants.SUPPORTED_CHART_FORMATS) {
			var button = new UIButton(0, 0, format, function() {
				title.text = format;
				fullyImportCheckbox.checkable = !(fullyImportCheckbox.checked = true);
				fullyImportCheckbox.field.alpha = 0.5;
			}, daWidth);
			button.autoAlpha = false;
			formats.add(button);
		}

		var first = formats.buttons.getFirstAlive();
		if(first != null && first.callback != null) first.callback();

		addPage(selectionDataGroup);
	}
}