extends Resource
class_name MigrationData

# AppSettings reads migration_version_array from user:// and res://project.godot
# then determine how the one from the user is outdated compared to the one from
# res://project.godot


# AppSettings will then start to compare both migration_version_array to know
# which migration from which version has to be applied
# When AppSettings sees a différence on migration_version_array it will start
# to read each MigrationDatum to know
# which fields has to be created/erased/updated/renamed
export var migration_version_array : Array # Array of MigrationDatum

# Current version is just used to know when the migration file has been updated
export var current_version_string : String
