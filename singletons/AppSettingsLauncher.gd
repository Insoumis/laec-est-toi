extends Object

# THIS IS NOT A SINGLETON OR IS IT?
# ITS ROLE IS TO LAUCH APPSETTINGS WITHOUT BEING PRELOADED
# IT ALLOWS TO PROTECT OUR APP SINGLETON FROM REFERENCING
# ANOTHER ONE

func launch():
	print("AppSettings from launcher ", AppSettings)
	AppSettings.boot({
		'video': {
			'screen': {
				'fullscreen': {
					'title': tr("Fullscreen"),
					'type': 'boolean',
					'project': 'display/window/size/fullscreen',
					# We may also provide a custom script here
#					'script': 'res://mything.gd',
					# Both are checked
					# 'res://appsettings/settings/video/screen/fullscreen.gd'
					# 'res://addons/open-hexes.appsettings/presets/default/video/screen/fullscreen.gd'
				},
				# Changing the resolution would be nice, but it creates trouble with camera zoom
#				'resolution': {
#					'title': tr("Resolution"),
#					'type': "select",
#					'options': [
#						{
#							'title': '800x600 (4:3)',
#							'value': Vector2(800, 600),
#						},
#						{
#							'title': '1024x600 (16:9)',
#							'value': Vector2(1024, 600),
#						},
#						{
#							'title': '1024x768 (4:3)',
#							'value': Vector2(1024, 768),
#						},
#						{
#							'title': '1280x720 (16:9)',
#							'value': Vector2(1280, 720),
#						},
#						{
#							'title': '1280x800 (16:10)',
#							'value': Vector2(1280, 800),
#						},
#						{
#							'title': '1280x1024 (5:4)',
#							'value': Vector2(1280, 1024),
#						},
#						{
#							'title': '1440x900 (5:4)',
#							'value': Vector2(1440, 900),
#						},
#						{
#							'title': '1440x1080 (4:3)',
#							'value': Vector2(1440, 1080),
#						},
#						{
#							'title': '1536x864 (16:9)',
#							'value': Vector2(1536, 864),
#						},
#						{
#							'title': '1600x900 (16:9)',
#							'value': Vector2(1600, 900),
#						},
#						{
#							'title': '1680x1050 (16:10)',
#							'value': Vector2(1680, 1050),
#						},
#						{
#							'title': '1920x1080 (16:9)',
#							'value': Vector2(1920, 1080),
#						},
#						{
#							'title': '1920x1200 (16:10)',
#							'value': Vector2(1920, 1200),
#						},
#						{
#							'title': '2048x1152 (16:9)',
#							'value': Vector2(2048, 1152),
#						},
#					],
#					'default': Vector2(1024, 600),
#				},
				'vsync': {
					'title': tr("Vertical Sync"),
					'type': 'boolean',
					'project': "display/window/vsync/use_vsync",
				},
			},
			
		},
		"audio":{
			"volume":{
				"master": {
					"title": tr("Master Volume"),
					"type": "range",
					"minimum": 0,
					"maximum": 100,
					"step": 1,
					"default": 75,
					"initialize": true,
				},
				"music": {
					"title": tr("Music Volume"),
					"type": "range",
					"minimum": 0,
					"maximum": 100,
					"step": 1,
					"default": 75,
					"initialize": true,
				},
#				"interface": {
#					"title": tr("UI Volume"),
#					"type": "range",
#					"minimum": 0,
#					"maximum": 100,
#					"step": 1,
#					"default": 40,
#				},
				"effect": {
					"title": tr("Effects Volume"),
					"type": "range",
					"minimum": 0,
					"maximum": 100,
					"step": 1,
					"default": 75,
					"initialize": true,
				},
			},
		},
		'accessibility': {
			'visual': {
				'screenshake': {
					'title': tr("Screenshake"),
					'type': 'boolean',
					'default': true,
				},
			},
		},
		"controls": {
			"dragstick": {
				"speed": {
					"title": tr("Dragstick Speed"),
					"type": "range",
					"minimum": 0,
					"maximum": 100,
					"step": 1,
					"default": 20,
				},
			},
		},
	})
