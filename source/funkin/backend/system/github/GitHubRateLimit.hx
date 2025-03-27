package funkin.backend.system.github;

typedef GitHubRateLimit = {
	var resources:GitHubRateLimitResources;
	var rate:GitHubRateLimitInfos;
}

typedef GitHubRateLimitResources = {
	var core:GitHubRateLimitInfos;
	var ?graphql:GitHubRateLimitInfos;
	var search:GitHubRateLimitInfos;
	var ?code_search:GitHubRateLimitInfos;
	var ?source_import:GitHubRateLimitInfos;
	var ?integration_manifest:GitHubRateLimitInfos;
	var ?code_scanning_upload:GitHubRateLimitInfos;
	var ?actions_runner_registration:GitHubRateLimitInfos;
	var ?scim:GitHubRateLimitInfos;
	var ?dependency_snapshots:GitHubRateLimitInfos;
	var ?code_scanning_autofix:GitHubRateLimitInfos;
}

typedef GitHubRateLimitInfos = {
	var limit:Int;
	var remaining:Int;
	var reset:Int;
	var used:Int;
	var ?resource:String;
}