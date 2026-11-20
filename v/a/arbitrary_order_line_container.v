const max_operations = 32
const max_input_length = 99
const breakpoint_infinity = i64(1000000000000000)
const checksum_offset = i64(2000001)

struct Line { slope i64; intercept i64; breakpoint i64 }

fn floor_div(numerator i64, denominator i64) i64 {
	mut quotient := numerator / denominator
	if numerator % denominator != 0 && numerator < 0 { quotient-- }
	return quotient
}

fn intersection(left Line, right Line) i64 {
	return floor_div(left.intercept - right.intercept, right.slope - left.slope)
}

fn erase_line(mut lines [max_operations]Line, mut count int, position int) {
	for i in position .. count - 1 { lines[i] = lines[i + 1] }
	count--
}

fn insert_line(mut lines [max_operations]Line, mut count int, slope i64, intercept i64) {
	mut position := 0
	for position < count && lines[position].slope < slope { position++ }
	if position < count && lines[position].slope == slope {
		if lines[position].intercept >= intercept { return }
		erase_line(mut lines, mut count, position)
	}
	for i := count - 1; i >= position; i-- { lines[i + 1] = lines[i] }
	lines[position] = Line{slope: slope, intercept: intercept, breakpoint: breakpoint_infinity}
	count++
	mut active := position
	for active + 1 < count {
		breakpoint := intersection(lines[active], lines[active + 1])
		lines[active].breakpoint = breakpoint
		if breakpoint >= lines[active + 1].breakpoint { erase_line(mut lines, mut count, active + 1) }
		else { break }
	}
	if active + 1 == count { lines[active].breakpoint = breakpoint_infinity }
	if active > 0 {
		breakpoint := intersection(lines[active - 1], lines[active])
		lines[active - 1].breakpoint = breakpoint
		mut cursor := 0
		if breakpoint >= lines[active].breakpoint {
			erase_line(mut lines, mut count, active)
			active--
			if active + 1 < count { lines[active].breakpoint = intersection(lines[active], lines[active + 1]) }
			else { lines[active].breakpoint = breakpoint_infinity }
			cursor = active
		} else { cursor = active - 1 }
		for cursor > 0 && lines[cursor - 1].breakpoint >= lines[cursor].breakpoint {
			erase_line(mut lines, mut count, cursor)
			cursor--
			active--
			if cursor + 1 < count { lines[cursor].breakpoint = intersection(lines[cursor], lines[cursor + 1]) }
			else { lines[cursor].breakpoint = breakpoint_infinity }
		}
	}
}

fn line_query(lines [max_operations]Line, count int, x i64, objective i64) i64 {
	mut low := 0
	mut high := count
	for low < high {
		middle := low + (high - low) / 2
		if lines[middle].breakpoint < x { low = middle + 1 }
		else { high = middle }
	}
	return (lines[low].slope * x + lines[low].intercept) * objective
}

@[export: 'arbitrary_order_line_container']
pub fn arbitrary_order_line_container(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		mode, operation_value := input[0], input[1]
		if (mode != 0 && mode != 1) || operation_value < 0 || operation_value > max_operations { return -1 }
		operations := int(operation_value)
		if length != usize(2 + 3 * operations) { return -1 }
		mut seen_line := false
		for operation in 0 .. operations {
			p := 2 + 3 * operation
			opcode, first, second := input[p], input[p + 1], input[p + 2]
			if opcode == 0 {
				if first < -1000 || first > 1000 || second < -1000 || second > 1000 { return -1 }
				seen_line = true
			} else if opcode == 1 {
				if !seen_line || first < -1000 || first > 1000 || second != 0 { return -1 }
			} else { return -1 }
		}
		objective := if mode == 1 { i64(1) } else { i64(-1) }
		mut lines := [max_operations]Line{}
		mut line_count := 0
		mut query_index := 0
		mut checksum := i64(0)
		for operation in 0 .. operations {
			p := 2 + 3 * operation
			if input[p] == 0 {
				insert_line(mut lines, mut line_count, input[p + 1] * objective, input[p + 2] * objective)
			} else {
				optimum := line_query(lines, line_count, input[p + 1], objective)
				checksum += i64(query_index + 1) * (optimum + checksum_offset)
				query_index++
			}
		}
		return checksum
	}
}
