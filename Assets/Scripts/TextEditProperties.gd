extends TextEdit

@export var allowNewLine: bool
@export var allowSpace: bool


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_text_changed():
	if !allowNewLine:
		text = text.replace("\n", "")
	if !allowSpace:
		text = text.replace(" ", "")
	set_caret_column(text.length(),true)
	print (get_caret_column())

