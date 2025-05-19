extends Node

const TYPES = ["Entity", "Army", "Civilian"]

const STATS_RANGES = {
	"Entity": {
		"signal_integrity": [10, 50],
		"error_rate": [10, 50],
		"latency": [10, 40],
		"transponder_dots": [1.0, 2.0]
	},
	"Army": {
		"signal_integrity": [70, 100],
		"error_rate": [0, 30],
		"latency": [5, 20],
		"transponder_dots": [1.5, 3.0]
	},
	"Civilian": {
		"signal_integrity": [30, 60],
		"error_rate": [5, 70],
		"latency": [10, 70],
		"transponder_dots": [1.0, 2.5]
	}
}
