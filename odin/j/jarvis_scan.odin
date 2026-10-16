package jarvis_scan

import "core:c"

MAX_POINTS :: 64
MIN_COORDINATE :: i64(-10000)
MAX_COORDINATE :: i64(10000)

orientation :: proc "contextless" (ax, ay, bx, by, cx, cy: i64) -> i64 {
	return (bx-ax)*(cy-ay) - (by-ay)*(cx-ax)
}

put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits >> u64(byte*8))
	}
}

// Return an integer Jarvis-scan hull in counter-clockwise order.
@(export)
jarvis_scan :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	count_value := input[0]
	if count_value < 0 || count_value > MAX_POINTS do return -1
	count := int(count_value)
	if int(length) != 1 + 2*count do return -1

	x: [MAX_POINTS]i64
	y: [MAX_POINTS]i64
	for point := 0; point < count; point += 1 {
		x[point] = input[1+2*point]
		y[point] = input[2+2*point]
		if x[point] < MIN_COORDINATE || x[point] > MAX_COORDINATE ||
			y[point] < MIN_COORDINATE || y[point] > MAX_COORDINATE do return -1
	}
	if count <= 2 do return 0

	for first := 0; first < count; first += 1 {
		for second := first+1; second < count; second += 1 {
			if x[first] == x[second] && y[first] == y[second] do return -1
		}
	}
	for first := 0; first+2 < count; first += 1 {
		for second := first+1; second+1 < count; second += 1 {
			for third := second+1; third < count; third += 1 {
				if orientation(x[first], y[first], x[second], y[second], x[third], y[third]) == 0 do return -1
			}
		}
	}

	start := 0
	for point := 1; point < count; point += 1 {
		if x[point] < x[start] || (x[point] == x[start] && y[point] < y[start]) do start = point
	}
	hull: [MAX_POINTS]int
	hull_count := 0
	current := start
	for {
		if hull_count == count do return -1
		hull[hull_count] = current
		hull_count += 1
		candidate := (current+1) % count
		for point := 0; point < count; point += 1 {
			if orientation(x[current], y[current], x[point], y[point], x[candidate], y[candidate]) > 0 do candidate = point
		}
		if candidate == start do break
		current = candidate
	}
	bytes := hull_count*16
	if output == nil || int(capacity) < bytes do return -2
	for index := 0; index < hull_count; index += 1 {
		put_i64(output, index*16, x[hull[index]])
		put_i64(output, index*16+8, y[hull[index]])
	}
	return i64(bytes)
}
