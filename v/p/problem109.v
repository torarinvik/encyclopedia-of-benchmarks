module problem109

@[export: 'problem109']
pub fn problem109(limit i64) i64 {
	mut values := [63]i64{}
	mut doubles := [21]i64{}
	mut value_count := 0
	mut double_count := 0
	for score in 1 .. 21 { values[value_count] = i64(score); value_count++ }
	values[value_count] = 25; value_count++
	for score in 1 .. 21 { doubles[double_count] = 2 * i64(score); values[value_count] = 2 * i64(score); double_count++; value_count++ }
	doubles[double_count] = 50; values[value_count] = 50; double_count++; value_count++
	for score in 1 .. 21 { values[value_count] = 3 * i64(score); value_count++ }
	values[value_count] = 0; value_count++
	mut count := i64(0)
	for d in 0 .. double_count { for first in 0 .. value_count { for second in first .. value_count {
		if doubles[d] + values[first] + values[second] < limit { count++ }
	} } }
	return count
}
