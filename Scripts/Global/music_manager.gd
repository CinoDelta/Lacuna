extends AudioStreamPlayer

func loadMusic(path):
	stream = load(path)

func stopMusic():
	stop()

func playMusic():
	play()

func setVolume(decibels:int):
	volume_db = decibels
