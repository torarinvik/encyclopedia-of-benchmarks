package arbitrary_order_line_container

import "core:c"

MAX_OPERATIONS :: 32
MAX_INPUT_LENGTH :: 99
BREAKPOINT_INFINITY :: i64(1000000000000000)
CHECKSUM_OFFSET :: i64(2000001)

Line :: struct { slope, intercept, breakpoint: i64 }

floor_div :: proc "contextless" (numerator, denominator: i64) -> i64 {
	quotient := numerator / denominator
	if numerator % denominator != 0 && numerator < 0 do quotient -= 1
	return quotient
}

intersection :: proc "contextless" (left, right: Line) -> i64 {
	return floor_div(left.intercept - right.intercept, right.slope - left.slope)
}

erase_line :: proc "contextless" (lines: [^]Line, count, position: int) -> int {
	for i := position; i + 1 < count; i += 1 { lines[i] = lines[i + 1] }
	return count - 1
}

insert_line :: proc "contextless" (lines: [^]Line, initial_count: int, slope, intercept: i64) -> int {
	count := initial_count
	position := 0
	for position < count && lines[position].slope < slope { position += 1 }
	if position < count && lines[position].slope == slope {
		if lines[position].intercept >= intercept do return count
		count = erase_line(lines, count, position)
	}
	for i := count; i > position; i -= 1 { lines[i] = lines[i - 1] }
	lines[position] = Line{slope, intercept, BREAKPOINT_INFINITY}
	count += 1
	active := position
	for active + 1 < count {
		breakpoint := intersection(lines[active], lines[active + 1])
		lines[active].breakpoint = breakpoint
		if breakpoint >= lines[active + 1].breakpoint {
			count = erase_line(lines, count, active + 1)
		} else { break }
	}
	if active + 1 == count { lines[active].breakpoint = BREAKPOINT_INFINITY }
	if active > 0 {
		breakpoint := intersection(lines[active - 1], lines[active])
		lines[active - 1].breakpoint = breakpoint
		cursor: int
		if breakpoint >= lines[active].breakpoint {
			count = erase_line(lines, count, active)
			active -= 1
			if active + 1 < count { lines[active].breakpoint = intersection(lines[active], lines[active + 1]) }
			else { lines[active].breakpoint = BREAKPOINT_INFINITY }
			cursor = active
		} else { cursor = active - 1 }
		for cursor > 0 && lines[cursor - 1].breakpoint >= lines[cursor].breakpoint {
			count = erase_line(lines, count, cursor)
			cursor -= 1
			active -= 1
			if cursor + 1 < count { lines[cursor].breakpoint = intersection(lines[cursor], lines[cursor + 1]) }
			else { lines[cursor].breakpoint = BREAKPOINT_INFINITY }
		}
	}
	return count
}

line_query :: proc "contextless" (lines: [^]Line, count: int, x, objective: i64) -> i64 {
	low, high := 0, count
	for low < high {
		middle := low + (high - low) / 2
		if lines[middle].breakpoint < x { low = middle + 1 }
		else { high = middle }
	}
	return (lines[low].slope * x + lines[low].intercept) * objective
}

@(export)
arbitrary_order_line_container :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	mode, operation_value := input[0], input[1]
	if (mode != 0 && mode != 1) || operation_value < 0 || operation_value > MAX_OPERATIONS do return -1
	operations := int(operation_value)
	if int(length) != 2 + 3 * operations do return -1
	seen_line := false
	for operation := 0; operation < operations; operation += 1 {
		p := 2 + 3 * operation
		opcode, first, second := input[p], input[p + 1], input[p + 2]
		if opcode == 0 {
			if first < -1000 || first > 1000 || second < -1000 || second > 1000 do return -1
			seen_line = true
		} else if opcode == 1 {
			if !seen_line || first < -1000 || first > 1000 || second != 0 do return -1
		} else do return -1
	}
	objective := i64(1)
	if mode == 0 { objective = -1 }
	var lines: [MAX_OPERATIONS]Line
	line_count := 0
	query_index := 0
	checksum := i64(0)
	for operation := 0; operation < operations; operation += 1 {
		p := 2 + 3 * operation
		if input[p] == 0 {
			line_count = insert_line(&lines[0], line_count, input[p + 1] * objective, input[p + 2] * objective)
		} else {
			optimum := line_query(&lines[0], line_count, input[p + 1], objective)
			checksum += i64(query_index + 1) * (optimum + CHECKSUM_OFFSET)
			query_index += 1
		}
	}
	return checksum
}
