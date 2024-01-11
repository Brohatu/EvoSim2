extends CanvasLayer


signal generate

func _on_button_pressed():
	generate.emit()
