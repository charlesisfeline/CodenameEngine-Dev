package funkin.options.categories;

class AppearanceAdvancedOptions extends OptionsScreen {
	public override function new() {
		super("Advanced Appearance", "Change Appearance options such as Flashing menus...");
		add(new ArrayOption(
			"Overall quality",
			"Automatically adjusts some quality settings depending on which value you choose",
			["low", "high", "custom"],
			["Low", "High", "Custom"],
			"overallQuality"));
		add(new Separator());
		add(new Checkbox(
			"Antialiasing",
			"If unchecked, will disable antialiasing on every sprite. Can boost performances at the cost of more obvious pixels.",
			"antialiasing"));
		add(new Checkbox(
			"Shaders",
			"If unchecked, shaders wont be loaded; this may be helpful on weak devices.",
			"gameplayShaders"));
		add(new Checkbox(
			"Low Memory Mode",
			"If checked, will disable certain background elements in stages to reduce memory usage.",
			"lowMemoryMode"));
	}
}