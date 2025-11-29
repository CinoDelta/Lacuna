extends AudioStreamPlayer

var sfxChannels = []

func _ready():
	var i = 0
	for child in get_children():
		sfxChannels.insert(i, child)
		i += 1
func loadMusic(path):
	stream = load(path)
	
func loadSoundEffect(path, channel):
	print("children: " + str(get_children()))
	print("channel: " + str(sfxChannels))
	sfxChannels[channel].stream = load(path)
	
func setMusic(resource):
	stream = resource

func stopMusic():
	stop()

func playMusic():
	play()
	
func playSoundEffectOnChannel(channel):
	sfxChannels[channel-1].play()

func setVolume(decibels):
	volume_db = decibels
