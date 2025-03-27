package funkin.backend.system.github;

#if GITHUB_API
import haxe.Json;
#end
import haxe.Exception;

// TODO: Document further and perhaps make this a Haxelib.
class GitHub {
	private static var __cachedRateLimit(default, set):GitHubRateLimit;  // avoiding making the engine download everytime  - Nex
	private static var __lastUpdate:Float = 0;
	private static function set___cachedRateLimit(value:GitHubRateLimit) {
		__lastUpdate = Date.now().getTime();
		return __cachedRateLimit = value;
	}

	/**
	 * Checks if the GitHub's API is useable without getting rate limited (IP based) and already decreases (locally) the remaining uses.
	 * @param uses How many uses to decrease from the remaining uses.
	 * @return Whether the API can be used or not.
	 */
	public static function checkAndUseApi(uses:Int = 1):Bool {
		#if GITHUB_API
		if (__cachedRateLimit == null || Date.now().getTime() > __lastUpdate + 120000)  // updates anyways every two minutes  - Nex
			__cachedRateLimit = getRateLimit();

		if (__cachedRateLimit != null && __cachedRateLimit.rate.remaining >= uses) {
			for (info in [__cachedRateLimit.rate, __cachedRateLimit.resources.core]) {
				info.remaining -= uses;
				info.used += uses;
			}

			return canUseApi(false);
		}
		#end
		return false;
	}

	/**
	 * Checks if the GitHub's API is useable without getting rate limited (IP based).
	 * @return Whether the API can be used or not.
	 */
	public static inline function canUseApi(download:Bool = true):Bool {
		#if GITHUB_API
		if (download) __cachedRateLimit = getRateLimit();
		return __cachedRateLimit != null && __cachedRateLimit.rate.remaining > 0;
		#else
		return false;
		#end
	}

	/**
	 * Gets the user IP's rate limit from the GitHub API.
	 * @return Rate Limits
	 */
	public static function getRateLimit(?onError:Exception->Void):GitHubRateLimit {
		#if GITHUB_API
		try {
			var data = Json.parse(HttpUtil.requestText('https://api.github.com/rate_limit'));
			if (Reflect.hasField(data, "documentation_url"))
				throw __parseGitHubException(data);

			return data;
		} catch(e) {
			if (onError != null)
				onError(e);
		}
		#end
		return null;
	}

	/**
	 * Gets all the releases from a specific GitHub repository using the GitHub API.
	 * @param user The user/organization that owns the repository
	 * @param repository The repository name
	 * @param onError Error Callback
	 * @return Releases
	 */
	public static function getReleases(user:String, repository:String, ?onError:Exception->Void, checkRateLimit:Bool = true):Array<GitHubRelease> {
		#if GITHUB_API
		try {
			if (checkRateLimit && !checkAndUseApi())
				throw new Exception("[GitHubException] You've got rate limited!");

			var data = Json.parse(HttpUtil.requestText('https://api.github.com/repos/${user}/${repository}/releases'));
			if (!(data is Array))
				throw __parseGitHubException(data);

			return data;
		} catch(e) {
			if (onError != null)
				onError(e);
		}
		#end
		return [];
	}

	/**
	 * Gets the contributors list from a specific GitHub repository using the GitHub API.
	 * @param user The user/organization that owns the repository
	 * @param repository The repository name
	 * @param onError Error Callback
	 * @return Contributors List
	 */
	public static function getContributors(user:String, repository:String, ?onError:Exception->Void, checkRateLimit:Bool = true):Array<GitHubContributor> {
		#if GITHUB_API
		try {
			if (checkRateLimit && !checkAndUseApi())
				throw new Exception("[GitHubException] You've got rate limited!");

			var data = Json.parse(HttpUtil.requestText('https://api.github.com/repos/${user}/${repository}/contributors'));
			if (!(data is Array))
				throw __parseGitHubException(data);

			return data;
		} catch(e) {
			if (onError != null)
				onError(e);
		}
		#end
		return [];
	}

	/**
	 * Gets a specific GitHub organization using the GitHub API.
	 * @param org The organization to get
	 * @param onError Error Callback
	 * @return Organization
	 */
	public static function getOrganization(org:String, ?onError:Exception->Void, checkRateLimit:Bool = true):GitHubOrganization {
		#if GITHUB_API
		try {
			if (checkRateLimit && !checkAndUseApi())
				throw new Exception("[GitHubException] You've got rate limited!");

			var data = Json.parse(HttpUtil.requestText('https://api.github.com/orgs/$org'));
			if (Reflect.hasField(data, "documentation_url"))
				throw __parseGitHubException(data);

			return data;
		} catch(e) {
			if (onError != null)
				onError(e);
		}
		#end
		return null;
	}

	/**
	 * Gets the members list from a specific GitHub organization using the GitHub API.
	 * NOTE: Members use Contributors' structure!
	 * @param org The organization to get the members from
	 * @param onError Error Callback
	 * @return Members List
	 */
	public static function getOrganizationMembers(org:String, ?onError:Exception->Void, checkRateLimit:Bool = true):Array<GitHubContributor> {
		#if GITHUB_API
		try {
			if (checkRateLimit && !checkAndUseApi())
				throw new Exception("[GitHubException] You've got rate limited!");

			var data = Json.parse(HttpUtil.requestText('https://api.github.com/orgs/$org/members'));
			if (Reflect.hasField(data, "documentation_url"))
				throw __parseGitHubException(data);

			return data;
		} catch(e) {
			if (onError != null)
				onError(e);
		}
		#end
		return [];
	}

	/**
	 * Gets a specific GitHub user/organization using the GitHub API.
	 * NOTE: If organization, it will be returned with the structure of a normal user; use `getOrganization` if you specifically want an organization!
	 * @param user The user/organization to get
	 * @param onError Error Callback
	 * @return User/Organization
	 */
	public static function getUser(user:String, ?onError:Exception->Void, checkRateLimit:Bool = true):GitHubUser {
		#if GITHUB_API
		try {
			if (checkRateLimit && !checkAndUseApi())
				throw new Exception("[GitHubException] You've got rate limited!");

			var data = Json.parse(HttpUtil.requestText('https://api.github.com/users/$user'));
			if (Reflect.hasField(data, "documentation_url"))
				throw __parseGitHubException(data);

			return data;
		} catch(e) {
			if (onError != null)
				onError(e);
		}
		#end
		return null;
	}

	/**
	 * Filters all releases gotten by `getReleases`
	 * @param releases Releases
	 * @param keepPrereleases Whenever to keep Pre-Releases.
	 * @param keepDrafts Whenever to keep Drafts.
	 * @return Filtered releases.
	 */
	public static inline function filterReleases(releases:Array<GitHubRelease>, keepPrereleases:Bool = true, keepDrafts:Bool = false)
		return #if GITHUB_API [for(release in releases) if (release != null && (!release.prerelease || (release.prerelease && keepPrereleases)) && (!release.draft || (release.draft && keepDrafts))) release] #else releases #end;

	private static function __parseGitHubException(obj:Dynamic):GitHubException {
		#if GITHUB_API
		var msg:String = "(No message)";
		var url:String = "(No API url)";
		if (Reflect.hasField(obj, "message"))
			msg = Reflect.field(obj, "message");
		if (Reflect.hasField(obj, "documentation_url"))
			url = Reflect.field(obj, "documentation_url");
		return new GitHubException(msg, url);
		#else
		return null;
		#end
	}
}