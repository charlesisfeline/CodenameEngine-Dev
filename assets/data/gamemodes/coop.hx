//
function changedGameModeScript(enabled:Bool) for (str in strumLines) {
	if (str.data.type != 2) str.cpu = false;
	str.controls = enabled ? (str.data.type == 1 ? controlsP1 : controlsP2) : controls;
}