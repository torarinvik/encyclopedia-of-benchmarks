package fcfs_scheduling

import "core:c"

store_i64_le :: proc "contextless" (output: [^]u8, position: c.size_t, value: i64) {
	bits := u64(value)
	for byte: c.size_t = 0; byte < 8; byte += 1 {
		output[position + byte] = u8((bits >> (byte * 8)) & 0xff)
	}
}

@(export)
fcfs_scheduling :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 193 do return -2
	if values[0] < 0 || values[0] > 64 do return -2
	count := c.size_t(values[0])
	if length != 1 + 3 * count do return -2

	ids: [64]i64
	arrivals: [64]i64
	bursts: [64]i64
	order: [64]c.size_t
	for i: c.size_t = 0; i < count; i += 1 {
		id, arrival, burst := values[1 + 3 * i], values[2 + 3 * i], values[3 + 3 * i]
		if id < 0 || id > 63 || arrival < 0 || arrival > 1_000_000 || burst < 1 || burst > 1_000_000 do return -2
		for previous: c.size_t = 0; previous < i; previous += 1 {
			if ids[previous] == id do return -2
		}
		ids[i], arrivals[i], bursts[i], order[i] = id, arrival, burst, i
	}
	for i: c.size_t = 1; i < count; i += 1 {
		key := order[i]
		j := i
		for j > 0 && (arrivals[order[j - 1]] > arrivals[key] ||
				(arrivals[order[j - 1]] == arrivals[key] && ids[order[j - 1]] > ids[key])) {
			order[j] = order[j - 1]
			j -= 1
		}
		order[j] = key
	}

	required := count * 48
	if output_capacity < required || (required != 0 && output == nil) do return -2
	elapsed: i64 = 0
	for position: c.size_t = 0; position < count; position += 1 {
		i := order[position]
		if elapsed < arrivals[i] do elapsed = arrivals[i]
		completion := elapsed + bursts[i]
		turnaround := completion - arrivals[i]
		waiting := turnaround - bursts[i]
		fields := [6]i64{ids[i], arrivals[i], bursts[i], completion, turnaround, waiting}
		for field: c.size_t = 0; field < 6; field += 1 {
			store_i64_le(output, position * 48 + field * 8, fields[field])
		}
		elapsed = completion
	}
	return i64(count)
}
