package circular_scan_scheduling

import "core:c"

MAX_REQUESTS :: 64
MAX_CYLINDER_COUNT :: i64(128)

sort_ascending :: proc "contextless" (items: [^]i64, count: int) {
	for index := 1; index < count; index += 1 {
		value := items[index]
		position := index
		for position > 0 && items[position - 1] > value {
			items[position] = items[position - 1]
			position -= 1
		}
		items[position] = value
	}
}

@(export)
circular_scan_scheduling :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 4 || length > 4 + MAX_REQUESTS do return -1
	max_cylinder := values[0]
	start := values[1]
	moving_up := values[2]
	request_count := values[3]
	if max_cylinder < 1 || max_cylinder > MAX_CYLINDER_COUNT || start < 0 || start >= max_cylinder do return -1
	if (moving_up != 0 && moving_up != 1) || request_count < 0 || request_count > MAX_REQUESTS do return -1
	if length != c.size_t(4 + request_count) do return -1

	up: [MAX_REQUESTS]i64 = {}
	down: [MAX_REQUESTS]i64 = {}
	up_count := 0
	down_count := 0
	for index in 0..<int(request_count) {
		request := values[4 + index]
		if request < -128 || request > 127 do return -1
		if moving_up == 1 {
			if request >= start && request < max_cylinder {
				up[up_count] = request
				up_count += 1
			} else {
				if request < start {
					down[down_count] = request
					down_count += 1
				}
			}
		} else {
			if request <= start {
				down[down_count] = request
				down_count += 1
			} else {
				up[up_count] = request
				up_count += 1
			}
		}
	}
	sort_ascending(raw_data(up[:]), up_count)
	sort_ascending(raw_data(down[:]), down_count)

	output_count := up_count + down_count
	if output_capacity < c.size_t(output_count) || (output_count > 0 && output == nil) do return -2
	position := 0
	if moving_up == 1 {
		for index in 0..<up_count {
			output[position] = u8((up[index] + 256) % 256)
			position += 1
		}
		for index in 0..<down_count {
			output[position] = u8((down[index] + 256) % 256)
			position += 1
		}
	} else {
		for index := down_count; index > 0; index -= 1 {
			output[position] = u8((down[index - 1] + 256) % 256)
			position += 1
		}
		for index := up_count; index > 0; index -= 1 {
			output[position] = u8((up[index - 1] + 256) % 256)
			position += 1
		}
	}
	return i64(output_count)
}
