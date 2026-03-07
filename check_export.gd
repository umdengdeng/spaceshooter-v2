@tool
extends SceneTree

func _init():
	print("=== CHECK EXPORT START ===")

	# 1. export_presets.cfg 파싱
	var config = ConfigFile.new()
	var err = config.load("res://export_presets.cfg")
	print("Export presets load result: ", err, " (0=OK)")
	if err == OK:
		for section in config.get_sections():
			print("Section: ", section)
			for key in config.get_section_keys(section):
				print("  ", key, " = ", config.get_value(section, key))
	else:
		print("FAILED to load export_presets.cfg!")

	# 2. 키스토어 파일 확인
	for path in ["/root/debug.keystore", "/root/.android/debug.keystore"]:
		var fa: FileAccess = FileAccess.open(path, FileAccess.READ)
		print("Keystore at ", path, ": ", fa != null)
		if fa:
			fa.close()

	# 3. 템플릿 파일 확인
	for tpl in ["android_debug.apk", "android_release.apk"]:
		var tpl_path: String = "/root/.local/share/godot/export_templates/4.6.1.stable/" + tpl
		var fa2: FileAccess = FileAccess.open(tpl_path, FileAccess.READ)
		print("Template ", tpl, ": ", fa2 != null)
		if fa2:
			fa2.close()

	# 4. Editor hint 확인
	print("Is editor hint: ", Engine.is_editor_hint())

	print("=== CHECK EXPORT END ===")
	quit()
