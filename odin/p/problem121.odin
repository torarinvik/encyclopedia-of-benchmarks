package problem121

@(export)
problem121 :: proc "c" (num_turns: i64) -> i64 {
	if num_turns < 1 || num_turns > 15 do return -1
	denominator: i64 = 1
	for turn := i64(2); turn <= num_turns + 1; turn += 1 do denominator *= turn
	sequence_count: i64 = 1
	for turn := i64(0); turn < num_turns; turn += 1 do sequence_count *= 2
	winning_weight: i64 = 0
	for mask := i64(0); mask < sequence_count; mask += 1 {
		remaining := mask
		blue: i64 = 0
		weight: i64 = 1
		for turn := i64(0); turn < num_turns; turn += 1 {
			if remaining % 2 == 0 do weight *= turn + 1
			else do blue += 1
			remaining /= 2
		}
		if 2 * blue > num_turns do winning_weight += weight
	}
	return denominator / winning_weight
}
