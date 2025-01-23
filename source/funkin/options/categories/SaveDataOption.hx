package funkin.options.categories;

import funkin.savedata.CodenameSave.CodenameSharedObject;

class SaveDataOption extends OptionsScreen {
	inline function formatSaveName(name:String):String {
		return [for (word in name.replace("-", " ").split(" ")) word.charAt(0).toUpperCase() + word.substring(1)].join(" ");
	}
	function convertSaveMap(pathMap:Map<String, CodenameSharedObject>):Map<String, Map<String, CodenameSharedObject>> {
        var modSaveMap = new Map<String, Map<String, CodenameSharedObject>>();
        
        for (path in pathMap.keys()) {
            // Split the path and remove empty strings
            var parts = path.split("/").filter(part -> part != "");
            
            if (parts.length >= 2) {
                var modId = parts[0];
                var saveId = parts[1];
                
                // Initialize array if this is the first save for this mod
                if (!modSaveMap.exists(modId)) {
                    modSaveMap.set(modId, []);
                }
                
                // Add the save ID to the mod's array
                modSaveMap.get(modId).set(saveId, pathMap.get(path));
            }
        }
        
        return modSaveMap;
    }
	public override function new(?mod:String = null, ?saveMap:Map<String, CodenameSharedObject>) {
		var titleLabel = mod != null ? formatSaveName(mod) : 'Reset Mod Data';
		var descLabel = mod != null ? 'Use this menu to reset data for "${formatSaveName(mod)}".' : "Use this menu to reset mod data.";
		super(titleLabel, descLabel);

		if (mod != null)
		{
			if (saveMap == null)
				saveMap = convertSaveMap(CodenameSharedObject.getSaves()).get(mod);

			for (saveId => saveObject in saveMap)
			{
				var saveName = formatSaveName(saveId);
				var saveOption = new TextOption(
					'$saveName',
					'Reset Save Object "$saveName"! This option has confirmation',
					null
				);
				saveOption.selectCallback = function() {
					if (saveObject == null) {
						return;
					}
					FlxG.state.openSubState(
						new funkin.editors.ui.UIWarningSubstate("Save Deletion Process",
						[
							'Are you really sure you want to delete Save Object "$saveId" from ${formatSaveName(mod)}?',
							'This CANNOT be undone!!',
							'',
							'This is going to be the last confirmation'
						].join("\n"),
						[
							{
								label: "Cancel",
								onClick: function(t) {}
							},
							{
								label: "OK",
								color: 0xFF0000,
								onClick: function(t) {
									members.remove(saveOption);
									changeSelection(0, true);
									saveObject.dispose();
									saveObject.clear();
									trace('Goodbye /$mod/$saveId');
								}
							}
						],
						false)
					);
				};
				add(saveOption);
			}
		} else {
			var sortedSaves:Map<String, Map<String, CodenameSharedObject>> = convertSaveMap(CodenameSharedObject.getSaves());
			for (mod => saveMap in sortedSaves)
			{
				var modName = formatSaveName(mod);
				add(new TextOption(
					'$modName >',
					'Use this menu to reset data for "$modName".',
					function() {
						treeParent.optionsTree.add(new SaveDataOption(mod, saveMap));
					}
				));
			}
		}
	}
}
