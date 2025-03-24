package funkin.backend.system.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class FieldName
{
	public var name:String;
	public var saveField:String;

	public function new(name:String, saveField:String)
	{
		this.name = name;
		this.saveField = saveField;
	}
}

/**
 * Macro that automatically generates flush and load functions.
 */
class FunkinSaveMacro
{
	/**
	 * Generates flush and load functions.
	 * @param saveFieldName Name of the save field (`save`) or `null` to not have a default save field
	 * @param saveFuncName Name of the save func (`flush`)
	 * @param loadFuncName Name of the load func (`load`)
	 * @return Array<Field>
	 */
	public static function build(saveFieldName:Null<String>, saveFuncName:String = "flush", loadFuncName:String = "load"):Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();

		var fieldNames:Array<FieldName> = [];
		for (field in fields)
		{
			if (!field.access.contains(AStatic))
				continue;

			switch (field.kind)
			{
				case FVar(type, expr):
					if (saveFieldName != null && field.name == saveFieldName)
						continue;
					var valid:Bool = true;
					var customSaveFieldName:Null<String> = saveFieldName;
					if (field.meta != null)
					{
						for (m in field.meta)
						{
							if (m.name == ":doNotSave")
								valid = false;
							if (m.name == ":saveField")
								customSaveFieldName = meta_extractIdent(m);
						}
					}
					if(customSaveFieldName == null)
						Context.error("Field " + field.name + " is not marked with @:saveField", field.pos);
					if (valid)
						fieldNames.push(new FieldName(field.name, customSaveFieldName));
				default:
					continue;
			}
		}

		var _allSaveFields:Array<String> = [for (f in fieldNames) f.saveField];
		if(saveFieldName != null)
			_allSaveFields.push(saveFieldName);
		var __allSaveFields:Map<String, Bool> = [];
		for (f in _allSaveFields) __allSaveFields.set(f, true);
		var allSaveFields:Array<String> = [];
		for (f in __allSaveFields.keys()) allSaveFields.push(f);

		/**
		 * SAVE FUNCTION
		 */
		var saveFuncBlocks:Array<Expr> = [for (f in fieldNames) {
			var name:String = f.name;
			macro $i{f.saveField}.data.$name = $i{name};
		}];

		for (f in allSaveFields)
			saveFuncBlocks.push(macro $i{f}.flush());

		fields.push({
			pos: Context.currentPos(),
			name: saveFuncName,
			kind: FFun({
				args: [],
				expr: {
					pos: Context.currentPos(),
					expr: EBlock(saveFuncBlocks)
				}
			}),
			access: [APublic, AStatic]
		});

		/**
		 * LOAD FUNCTION
		 */
		fields.push({
			pos: Context.currentPos(),
			name: loadFuncName,
			kind: FFun({
				args: [],
				expr: {
					pos: Context.currentPos(),
					expr: EBlock([
						for (f in fieldNames) {
							var name:String = f.name;
							macro if ($i{f.saveField}.data.$name != null) $i{f.name} = $i{f.saveField}.data.$name;
						}
					])
				}
			}),
			access: [APublic, AStatic]
		});

		return fields;
	}

	public static function meta_extractIdent(meta:MetadataEntry):Null<String> {
		if (meta == null || meta.params == null || meta.params.length == 0)
			throw "Expected an identifier";
		switch (meta.params[0].expr) {
			case EConst(CIdent(s)):
				return s;
			default:
		}
		throw "Expected an identifier";
	}
}
#end
