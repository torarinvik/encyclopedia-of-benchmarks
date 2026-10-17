package proportional_fair_scheduling

import "core:c"

store_i64_le :: proc "contextless" (output: [^]u8, position: c.size_t, value: i64) {
	bits := u64(value)
	for byte: c.size_t = 0; byte < 8; byte += 1 {
		output[position + byte] = u8((bits >> (byte * 8)) & 0xff)
	}
}

@(export)
proportional_fair_scheduling :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 131 do return -1
	if values[0] < 0 || values[0] > 64 || values[1] < 1 || values[1] > 1_000_000 {
		return -1
	}
	process_count := c.size_t(values[0])
	total_resources := values[1]
	if length != 2 + 2 * process_count do return -1

	name_ids: [64]i64
	weights: [64]i64
	total_weight: i64 = 0
	for process: c.size_t = 0; process < process_count; process += 1 {
		name_id, weight := values[2 + 2 * process], values[3 + 2 * process]
		if name_id < -2147483648 || name_id > 2147483647 || weight < 1 || weight > 1_000_000 do return -1
		name_ids[process], weights[process] = name_id, weight
		total_weight += weight
	}

	if process_count == 0 do return 0
	required := process_count * 16
	if output == nil || output_capacity < required do return -2
	for process: c.size_t = 0; process < process_count; process += 1 {
		quotient := f64(weights[process]) / f64(total_weight)
		share := quotient * f64(total_resources)
		allocation := i32(share)
		store_i64_le(output, process * 16, name_ids[process])
		store_i64_le(output, process * 16 + 8, i64(allocation))
	}
	return i64(required)
}
