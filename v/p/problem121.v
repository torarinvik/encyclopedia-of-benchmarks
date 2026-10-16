module problem121

@[export: 'problem121']
pub fn problem121(num_turns i64) i64 {
	if num_turns < 1 || num_turns > 15 { return -1 }
	mut denominator := i64(1)
	for turn := i64(2); turn <= num_turns + 1; turn++ { denominator *= turn }
	mut sequence_count := i64(1)
	for _ in 0 .. int(num_turns) { sequence_count *= 2 }
	mut winning_weight := i64(0)
	for mask in i64(0) .. sequence_count {
		mut remaining := mask
		mut blue := i64(0)
		mut weight := i64(1)
		for turn in i64(0) .. num_turns {
			if remaining % 2 == 0 { weight *= turn + 1 }
			else { blue++ }
			remaining /= 2
		}
		if 2 * blue > num_turns { winning_weight += weight }
	}
	return denominator / winning_weight
}
