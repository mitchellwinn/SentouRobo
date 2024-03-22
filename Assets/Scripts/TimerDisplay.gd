extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var time = GameManager.gameTimer
		
	var mils = fmod(time,1)*1000
	var secs = fmod(time,60)
	var mins = fmod(time, 60*60) / 60
	var hr = fmod(fmod(time,3600 * 60) / 3600,24)
	var dy = fmod(time,12960000) / 86400
	
	var time_passed = "%02d:%02d:%03d" % [mins,secs,mils]
	text = "[right]"+time_passed# + " : " + var2str(time)
	
	pass
