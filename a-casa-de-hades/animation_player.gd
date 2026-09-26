extends AnimationPlayer

var lines = ["Os semideuses estão em guerra...", 
	"Gregos e Romanos, uns contra os outros, se esquecendo de seu maior inimigo..."]
var index = 0

func _process(delta):
   if Input.is_action_just_pressed("ui_accept"):
	   index += 1
	   if index < lines.size():
		   $DialogueLabel.text = lines[index]
	   else:
		   end_cutscene()
		
		
func end_cutscene():
   $CutsceneCam.current = false
   # Re-enable player controls here
