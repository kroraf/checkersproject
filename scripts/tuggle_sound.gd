extends Button

var sfx_bus = AudioServer.get_bus_index("SFX")

func _on_toggled(toggled_on):
	AudioServer.set_bus_mute(sfx_bus, toggled_on)
