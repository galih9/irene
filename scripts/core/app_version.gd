class_name AppVersion
extends RefCounted

## Centralized version and build number registry for Project Irene.
## Started at Version 1.0.8, Build 8.

const MAJOR: int = 1
const MINOR: int = 0
const PATCH: int = 9
const BUILD: int = 19

const APP_NAME: String = "All You Can Merge"
const VERSION_NAME: String = "1.0.8"

static func get_version_string() -> String:
	return "v%s (Build %d)" % [VERSION_NAME, BUILD]

static func get_short_version() -> String:
	return "v%s" % VERSION_NAME

static func get_build_string() -> String:
	return "Build %d" % BUILD

static func get_full_display() -> String:
	return "Version %s • Build %d" % [VERSION_NAME, BUILD]
