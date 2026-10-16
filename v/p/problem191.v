module problem191

@[export: 'problem191']
pub fn problem191(days i64) i64 {
	if days < 0 || days > 65 { return -1 }
	mut ways := [396]i64{}
	for absent in 0 .. 2 {
		for late in 0 .. 3 { ways[absent * 3 + late] = 1 }
	}
	for remaining in 1 .. int(days) + 1 {
		for absent in 0 .. 2 {
			for late in 0 .. 3 {
				previous := (remaining - 1) * 6
				late_state := if late < 2 { ways[previous + absent * 3 + late + 1] } else { i64(0) }
				absent_state := if absent == 0 { ways[previous + 3] } else { i64(0) }
				on_time_state := ways[previous + absent * 3]
				ways[remaining * 6 + absent * 3 + late] = late_state + absent_state + on_time_state
			}
		}
	}
	return ways[int(days * 6)]
}
