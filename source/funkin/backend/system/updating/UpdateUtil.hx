package funkin.backend.system.updating;

#if GITHUB_API
import sys.FileSystem;
import haxe.io.Path;
import github.api.structures.Release;
import github.api.GitHubAPI;
import lime.app.Application;

using github.api.GitHubAPI;

class UpdateUtil {
	public static final repoOwner:String = "YoshiCrafter29";
	public static final repoName:String = "CodenameTestRepo";

	public static function init() {
		// deletes old bak file if it exists
		#if sys
		var bakPath = '${Path.withoutExtension(Sys.programPath())}.bak';
		if (FileSystem.exists(bakPath))
			FileSystem.deleteFile(bakPath);
		#end
	}

	public static function checkForUpdates():UpdateCheckCallback {
		var curTag = 'v${Application.current.meta.get('version')}';
		trace(curTag);

		var error = false;

		var newUpdates = __doReleaseFiltering(GitHubAPI.getReleases(repoOwner, repoName, function(e) {
			error = true;
		}), curTag);

		if (error) return {
			success: false,
			newUpdate: false
		};

		if (newUpdates.length <= 0) {
			return {
				success: true,
				newUpdate: false
			};
		}

		return {
			success: true,
			newUpdate: true,
			currentVersionTag: curTag,
			newVersionTag: newUpdates.last().tag_name,
			updates: newUpdates
		};
	}

	static var __curVersionPos = -2;
	static function __doReleaseFiltering(releases:Array<Release>, currentVersionTag:String) {
		releases = releases.filterReleases(Options.commitUpdates, false);
		if (releases.length <= 0)
			return releases;

		var newArray:Array<Release> = [];

		var skipNextBinaryChecks:Bool = false;
		for(index in 0...releases.length) {
			var i = index;

			var release = releases[i];
			var containsBinary = skipNextBinaryChecks;
			if (!containsBinary) {
				for(asset in release.assets) {
					if (asset.name.toLowerCase() == AsyncUpdater.executableGitHubName.toLowerCase()) {
						containsBinary = true;
						break;
					}
				}
			}
			if (containsBinary) {
				skipNextBinaryChecks = true; // no need to check for older versions
				if (release.tag_name == currentVersionTag) {
					__curVersionPos = -1;
				}
				newArray.insert(0, release);
				if (__curVersionPos > -2)
					__curVersionPos++;
				trace(release.tag_name);
			}
		}
		if (__curVersionPos < -1)
			__curVersionPos = -1;

		return newArray.length <= 0 ? newArray : newArray.splice(__curVersionPos+1, newArray.length-(__curVersionPos+1));
	}
}

typedef UpdateCheckCallback = {
	var success:Bool;

	var newUpdate:Bool;

	@:optional var currentVersionTag:String;

	@:optional var newVersionTag:String;

	@:optional var updates:Array<Release>;
}
#end