module monotone_convex_hull_trick

const max_lines = 32
const max_queries = 32
const max_length = 99
const invalid = i64(-9223372036854775807 - 1)

struct Line { slope i64; intercept i64 }

fn line_value(line Line, x i64) i64 { return line.slope * x + line.intercept }

fn redundant(a Line, b Line, c Line) bool {
	return (b.intercept - a.intercept) * (b.slope - c.slope) >= (c.intercept - b.intercept) * (a.slope - b.slope)
}

@[export: 'monotone_convex_hull_trick']
pub fn monotone_convex_hull_trick(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > max_length { return invalid }
	line_count_value := unsafe { values[0] }
	query_count_value := unsafe { values[1] }
	if line_count_value < 1 || line_count_value > max_lines || query_count_value < 0 || query_count_value > max_queries { return invalid }
	line_count := int(line_count_value)
	query_count := int(query_count_value)
	if length != 2 + 2 * line_count + query_count { return invalid }

	mut hull := []Line{len: max_lines, init: Line{}}
	mut hull_count := 0
	mut previous_slope := i64(9223372036854775807)
	mut cursor := 2
	for _ in 0 .. line_count {
		line := Line{unsafe { values[cursor] }, unsafe { values[cursor + 1] }}
		cursor += 2
		if line.slope < -1000 || line.slope > 1000 || line.intercept < -10000 || line.intercept > 10000 || line.slope >= previous_slope { return invalid }
		previous_slope = line.slope
		for hull_count >= 2 && redundant(hull[hull_count - 2], hull[hull_count - 1], line) { hull_count-- }
		hull[hull_count] = line
		hull_count++
	}

	mut front := 0
	mut previous_x := i64(-9223372036854775807 - 1)
	mut checksum := i64(0)
	for i in 0 .. query_count {
		x := unsafe { values[cursor + i] }
		if x < -1000 || x > 1000 || (i > 0 && x < previous_x) { return invalid }
		previous_x = x
		for front + 1 < hull_count && line_value(hull[front + 1], x) <= line_value(hull[front], x) { front++ }
		checksum += i64(i + 1) * line_value(hull[front], x)
	}
	return checksum
}
