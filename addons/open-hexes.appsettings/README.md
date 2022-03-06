

## Goal

Reduce the amount of time and effort required to add new settings in Godot games and apps.

- Generates the scene that the user interacts with
- Provides a GUI in the editor to add new settings


## Example usage


### Register settings metadata


```gdscript

AppSettings.register_metadata({
    'video': {
        'screen': {
            'fullscreen': {
                'title': "Fullscreen",
                'type': 'boolean',
                'default': false,
                # You may also specify a custom script here
				# 'script': 'res://mything.gd'
                # If empty, the kernel will look for these scripts in order and use the first found
                # 'res://appsettings/settings/video/screen/fullscreen.gd'
                # 'res://addons/open-hexes.appsettings/presets/default/video/screen/fullscreen.gd'
                # 'res://addons/open-hexes.appsettings/type/BooleanInputField.gd' ← does exist
            },
            'resolution': {
                'title': "Resolution",
                'type': "select",
                'options': [
                    {
                        'title': '800x600',
                        'value': Vector2(800, 600),
                    },
                    {
                        'title': '1024x768',
                        'value': Vector2(1024, 768),
                    },
                    {
                        'title': '1280x1024',
                        'value': Vector2(1280, 1024),
                    },
                ],
                'default': Vector2(1024, 768),
            },
            'vsync': {
                'title': "Vertical Sync",
                'hint': "Requires reboot of The Internet Box©",
                'type': 'boolean',
                'default': false,
            },
        },
        
    },
    "audio":{
        "volume":{
            "master": {
                "title": "Master\nVolume",
                "type": "range",
                "minimum": 0,
                "maximum": 100,
                "step": 1,
                "default": 40,
            },
            "music": {
                "title": "Music\nVolume",
                "type": "range",
                "minimum": 0,
                "maximum": 100,
                "step": 1,
                "default": 40,
            },
        },
    },
})

# Hydrate the settings from the stored file
# We aim to remove this, and hydrate lazily
AppSettings.load_from_file()

```


### Get a setting value

```gdscript

AppSettings.get_value("video", "screen", "resolution")

```


### Pack the settings scene to embed it in your game

```gdscript
const PackerOptions = preload("res://addons/open-hexes.appsettings/presets/PackerOptions.gd")
var packer_options = PackerOptions.new()
var settings_scene = AppSettings.pack_scene(packer_options)
```






## Settings Types

### Boolean
### Select
### Range

