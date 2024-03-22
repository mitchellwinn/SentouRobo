extends Sprite2D

var flavorWord: String
var frame_ = 5.0
var formattedFrame: String

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if flavorWord == "":
		return
	frame_ += delta * 60
	formattedFrame = "%05d" % [int(frame_)]
	#print("formatted frame: "+str(formattedFrame))
	texture = load("res://Assets/3DTextFX/renders/"+flavorWord+"_RENDER/"+flavorWord+"_RENDER_"+str(formattedFrame)+".png")
	if frame_ >= 119:
		queue_free()
