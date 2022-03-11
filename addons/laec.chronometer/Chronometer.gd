tool
extends Node

#   _____ _                                          _
#  / ____| |                                        | |
# | |    | |__  _ __ ___  _ __   ___  _ __ ___   ___| |_ ___ _ __
# | |    | '_ \| '__/ _ \| '_ \ / _ \| '_ ` _ \ / _ \ __/ _ \ '__|
# | |____| | | | | | (_) | | | | (_) | | | | | |  __/ ||  __/ |
#  \_____|_| |_|_|  \___/|_| |_|\___/|_| |_| |_|\___|\__\___|_|
#
# Example usage:
#
#	Chronometer.start('my_thing')
#	something_long()
#	Chronometer.stop('my_thing')
#	var seconds = Chronometer.report('my_thing')

var __times := Dictionary()


const DEFAULT_RUN := 'main'
const START := 'start'
const STOP := 'stop'


func get_now_usec():
	return OS.get_ticks_usec()


func start(run_name:=DEFAULT_RUN) -> void:
	if not __times.has(run_name):
		__times[run_name] = Dictionary()
	
	__times[run_name][START] = get_now_usec()


func end(run_name:=DEFAULT_RUN) -> float:
	return stop(run_name)


func stop(run_name:=DEFAULT_RUN, silent:=false) -> float:
	if not __times.has(run_name):
		if not silent:
			printerr("Stopping a chronometer that was never started…")
		return 0.0
	
	__times[run_name][STOP] = get_now_usec()
	
	return report(run_name)


func report(run_name:=DEFAULT_RUN, silent:=false) -> float:
	if not __times.has(run_name):
		if not silent:
			printerr("Reporting on a chronometer run that was never started…")
		return 0.0
	
	var time_usec = __times[run_name][STOP] - __times[run_name][START]
	
	return time_usec * 0.000001


#func start_lap
#func stop_lap
#func report_lap


func print_report():
	for run in __times:
		print("%s : %fs" % [run, report(run)])


