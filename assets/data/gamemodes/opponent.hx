//
function changedGameModeScript(enabled:Bool) for (str in strumLines) {
	if (str.data.type != 2) str.cpu = enabled ? str.data.type == 1 : str.data.type == 0;
	if (str.controls == controlsP1 || str.controls == controlsP2) str.controls = (str.type == 1) != enabled ? controlsP1 : controlsP2;
	switchHealthbarColors(enabled);
}

function postCreate()
	switchHealthbarColors(true);

function switchHealthbarColors(enabled:Bool) if (healthBar != null && !Options.colorHealthBar) {
	healthBar.createFilledBar(enabled ? 0xFF66FF33 : 0xFFFF0000, enabled ? 0xFFFF0000 : 0xFF66FF33);
	healthBar.updateBar();
}

// By default the game places already the character that should die, the only special case is when resetting  - Nex
function onGameOver(event) if (controls.RESET) {
	event.x = dad.x;
	event.y = dad.y;
	event.character = dad;
	event.deathCharID = dad.gameOverCharacter;
	event.isPlayer = dad.isPlayer;
}