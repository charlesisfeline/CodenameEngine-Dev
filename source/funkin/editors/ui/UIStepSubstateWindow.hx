package funkin.editors.ui;

import flixel.group.FlxGroup;

class UIStepSubstateWindow extends UISubstateWindow {
	private var stepsName:String;
	public var finishText:String;
	public var onFinish:Void->Void;

	public var backButton:UIButton;
	public var finishButton:UIButton;
	public var closeButton:UIButton;

	public var pages:Array<FlxGroup> = [];
	public var pageSizes:Array<FlxPoint> = [];
	public var curPage:Int = 0;

	public function new(finishText:String = "Finish & Close", ?onFinish:Void->Void) {
		super();
		this.finishText = finishText;
		if(onFinish != null) this.onFinish = onFinish;
	}

	public override function createPost() {
		add(finishButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, finishText, function() {
			if (curPage == pages.length-1) {
				if(onFinish != null) onFinish();
				close();
			} else {
				curPage++;
				refreshPages();
			}

			updatePagesTexts();
		}, 125));

		add(backButton = new UIButton(finishButton.x - 20 - finishButton.bWidth, finishButton.y, "< Back", function() {
			curPage--;
			refreshPages();

			updatePagesTexts();
		}, 125));

		add(closeButton = new UIButton(backButton.x - 20 - finishButton.bWidth, finishButton.y, "Cancel", close, 125));
		closeButton.color = 0xFFFF0000;

		stepsName = titleSpr.text;
		refreshPages();
		updatePagesTexts();

		super.createPost();
	}

	public function addPage(page:FlxGroup, ?size:FlxPoint) {
		pages.push(cast add(page));
		pageSizes.push(size != null ? size : FlxPoint.get(winWidth, winHeight));
	}

	public override function update(elapsed:Float) {
		finishButton.alpha = finishButton.field.alpha = finishButton.selectable ? 1 : 0.4;
		super.update(elapsed);
	}

	function refreshPages() {
		for (i=>page in pages)
			page.visible = page.exists = i == curPage;
	}

	function updatePagesTexts() {
		windowSpr.bWidth = Std.int(pageSizes[curPage].x);
		windowSpr.bHeight = Std.int(pageSizes[curPage].y);

		finishButton.field.text = curPage == pages.length-1 ? finishText : 'Next >';
		titleSpr.text = '$stepsName (${curPage+1}/${pages.length})';

		backButton.field.text = '< Back';
		backButton.visible = backButton.exists = curPage > 0;

		backButton.x = (finishButton.x = windowSpr.x + windowSpr.bWidth - 20 - 125) - 20 - finishButton.bWidth;
		closeButton.x = (curPage > 0 ? backButton : finishButton).x - 20 - finishButton.bWidth;

		for (button in [finishButton, backButton, closeButton])
			button.y = windowSpr.y + windowSpr.bHeight - 16 - 32;
	}
}