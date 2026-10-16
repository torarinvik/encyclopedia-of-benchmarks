package problem109

@(export)
problem109 :: proc "c" (limit: i64) -> i64 {
	values: [63]i64 = {}
	doubles: [21]i64 = {}
	value_count := 0
	double_count := 0
	for score := 1; score <= 20; score += 1 { values[value_count] = i64(score); value_count += 1 }
	values[value_count] = 25; value_count += 1
	for score := 1; score <= 20; score += 1 { doubles[double_count] = 2 * i64(score); values[value_count] = 2 * i64(score); double_count += 1; value_count += 1 }
	doubles[double_count] = 50; values[value_count] = 50; double_count += 1; value_count += 1
	for score := 1; score <= 20; score += 1 { values[value_count] = 3 * i64(score); value_count += 1 }
	values[value_count] = 0; value_count += 1
	count := i64(0)
	for d := 0; d < double_count; d += 1 {
		for first := 0; first < value_count; first += 1 {
			for second := first; second < value_count; second += 1 {
				if doubles[d] + values[first] + values[second] < limit { count += 1 }
			}
		}
	}
	return count
}
