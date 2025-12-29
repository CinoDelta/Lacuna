extends Panel

var sfxChannels = []

func _ready():
	var i = 0
	for child in get_children():
		sfxChannels.insert(i, child)
		i += 1
		
func loadSoundEffect(path, channel, vol):
	print("children: " + str(get_children()))
	print("channel: " + str(sfxChannels))
	
	sfxChannels[channel-1].stream = load(path)
	sfxChannels[channel-1].volume_db = vol
	
func playSoundEffectOnChannel(channel):
	sfxChannels[channel-1].play()
