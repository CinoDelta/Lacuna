extends AudioStreamPlayer

func loadMusic(path):
	stream = load(path)

func setMusic(resource):
	stream = resource

func stopMusic():
	stop()

func playMusic():
	play()

func setVolume(decibels):
	volume_db = decibels
