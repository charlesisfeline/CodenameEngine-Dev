package funkin.options.categories;

class GameplayAdvancedOptions extends OptionsScreen {
	public override function new() {
		super("Advanced Gameplay", "Change Advanced Gameplay options such as Hit Windows...");
		add(new NumOption(
			"Average hit window",
			"Change the average hit window for when you hit notes (this affects every judgement)",
			200,
			300,
			1,
			"hitWindow"));
	}
}