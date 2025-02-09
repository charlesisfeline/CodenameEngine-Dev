//
public var botplayTxt:FunkinText = null;  // i rather make a new text for this instead of reusing the score text  - Nex

private var nonCpuStrums:Array<StrumLine> = [];
private var visibleTxts:Array<Bool> = [];

function changedGameModeScript(enabled:Bool) {
	if (enabled) initBotplayShits();
	else {
		remove(botplayTxt);
		botplayTxt.destroy();
		for (i => txt in [scoreTxt, missesTxt, accuracyTxt]) txt?.visible = visibleTxts[i];
		for (strum in nonCpuStrums) strum.cpu = false;
	}
}

function postCreate() initBotplayShits();  // imma do it here too just to make sure, this might not get called everytime, depends if the game mode is changed midsong  - Nex

function initBotplayShits() {
	storeShits();
	for (strum in nonCpuStrums) strum.cpu = true;

	botplayTxt?.destroy();  // something bad happens if i dont destroy it first everytime, brah  - Nex
	botplayTxt = new FunkinText(0, 0, 0, "Botplay Mode Enabled");
	for (txt in [accuracyTxt, missesTxt]) txt?.visible = false;
	if (scoreTxt != null) {
		scoreTxt.visible = false;
		botplayTxt.setFormat(scoreTxt.font, scoreTxt.size, scoreTxt.color, scoreTxt.alignment, scoreTxt.borderStyle, scoreTxt.borderColor);
		botplayTxt.fieldWidth = scoreTxt.fieldWidth;
		botplayTxt.setPosition(scoreTxt.x, scoreTxt.y);
		botplayTxt.antialiasing = scoreTxt.antialiasing;
		botplayTxt.alpha = scoreTxt.alpha;
		botplayTxt._cameras = scoreTxt._cameras;
		botplayTxt.scrollFactor.set(scoreTxt.scrollFactor.x, scoreTxt.scrollFactor.y);
		add(botplayTxt);
	}
}

function storeShits() {
	if (nonCpuStrums == null || nonCpuStrums.length < 1) nonCpuStrums = [for (strum in strumLines) if (strum != null && !strum.cpu) strum];  // old classic way as !strum?.cpu might not work as intended here  - Nex
	if (visibleTxts.length < 1) for (i => txt in [scoreTxt, missesTxt, accuracyTxt]) if (txt != null) visibleTxts[i] = txt.visible;
}