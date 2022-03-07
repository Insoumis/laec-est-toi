tool
extends EditorScript



func _run():
	prints("TAU", TAU)
	prints("(TAU + 5.0) % TAU", fmod(TAU + 5.0, TAU))
	prints("(TAU - 5.0) % TAU", fmod(TAU - 5.0, TAU))
	
	var chrono = Chronometer
	
	var loops := 100000
	var report
	
	chrono.start('sin')
	for i in range(loops):
		sin(i)
	report = chrono.stop('sin')
	print(report)
	
	chrono.start('cheap_sin')
	for i in range(loops):
		CheapTrigo.cheap_sin(i)
	report = chrono.stop('cheap_sin')
	print(report)
	
	
