tool
extends Node

func dump_objects(log_id, log_path, log_slug, dump_connections=false, dump_properties=false):
	var f = File.new()
	var id_string = String(log_id)
	var inst_string_buffer
	f.open(log_path + log_slug + id_string + ".log", File.WRITE)
	for i in range(10000):
		
		
		var object = instance_from_id ( i )
		
		if object:
#			print(object.get_class())
#			yield(get_tree(), "idle_frame")
			if not object:
				break
				continue
			if object is BulletPhysicsDirectBodyState:
				continue
			if object is Physics2DDirectBodyStateSW:
				continue
#			if object.get_class() == "ScriptEditorDebuggerInspectedObject":
#				continue
			if object is GDScriptFunctionState:
				continue	
				


				
#			var inst_dict = inst2dict(object)
			inst_string_buffer = "\nOBJECT %d: %s" % [i, object.get_class()]
			f.store_string(inst_string_buffer + "\n")
			
			# node debugger
			if object.has_method("get_name"):
				if object.get_name() != "":
					inst_string_buffer = "NAME: %s" % object.get_name()
					f.store_string(inst_string_buffer + "\n")
			
			if object.has_method("get_parent"):
				if object.get_parent():
					inst_string_buffer = "PARENT: %d: %s" %  [object.get_parent().get_instance_id(), object.get_parent().get_name()]
					f.store_string(inst_string_buffer + "\n")
			if object.has_method("is_inside_tree"):
				inst_string_buffer = "IS INSIDE TREE: %s" %  [object.is_inside_tree()]
				f.store_string(inst_string_buffer + "\n")
			if dump_connections:
				#signals debugger
				if(object.get_incoming_connections().size() > 0):
					inst_string_buffer = "CONNECTION LIST :"
					f.store_string(inst_string_buffer + "\n")
					for j in range(object.get_incoming_connections().size()):
						inst_string_buffer = "%s" % String(object.get_incoming_connections()[j])
						f.store_string(inst_string_buffer + "\n")
			
			if dump_properties:
				# so... the second arg here can't be given to false even if it would make more sense without having a crash
				if(object.get_property_list().size() > 0):  
					inst_string_buffer = "PROPERTY LIST :"
					f.store_string(inst_string_buffer + "\n")
					if object.has_method("is_inside_tree"):
						if object.is_inside_tree():
							for j in range(object.get_property_list().size()): # ...but can here, WTF!?
								var property_dict = object.get_property_list()[j]
								inst_string_buffer = "%s: %s" % [ str(property_dict.name),str(ClassDB.class_get_property(object, property_dict.name)) ]
								f.store_string(inst_string_buffer + "\n")
						else:
							f.store_string("OBJECT NOT INSIDE THE TREE")
					else:
						for j in range(object.get_property_list().size()):
							var property_dict = object.get_property_list()[j]
							if property_dict.name != "refuse_new_network_connections":
								inst_string_buffer = "%s: %s" % [ str(property_dict.name),str(ClassDB.class_get_property(object, property_dict.name)) ]
							else:
								inst_string_buffer = "%s: %s" % [ str(property_dict.name), "DUMPING THIS ONE GENERATE ERROR" ]
							f.store_string(inst_string_buffer + "\n")
	f.close()
var log_id = 0
var is_dumping = false

func _input(event : InputEvent):
	print(event)
	if event is InputEventKey and not is_dumping:
		if event.get_scancode_with_modifiers() == KEY_MASK_CTRL + KEY_MASK_SHIFT + KEY_M:
			print("dumping please wait")
			is_dumping = true
			dump_objects(log_id,"res://", "object", false, true)
			log_id += 1
			print("done")
