package landlord_file_caching

import "core:c"

MAX_REQUESTS :: 7
MAX_FILES :: 8
MAX_INPUT :: 23

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
landlord_file_caching :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	capacity_value, count_value := input[0], input[1]
	if capacity_value < 1 || capacity_value > 8 || count_value < 0 || count_value > MAX_REQUESTS ||
		length != c.size_t(2 + 3*count_value) do return -1
	known_size: [MAX_FILES]i64
	known_cost: [MAX_FILES]i64
	seen: [MAX_FILES]bool
	count := int(count_value)
	for request := 0; request < count; request += 1 {
		id, size, cost := input[2+3*request], input[3+3*request], input[4+3*request]
		if id < 0 || id >= MAX_FILES || size < 1 || size > 4 || size > capacity_value || cost < 0 || cost > 20 do return -1
		slot := int(id)
		if seen[slot] && (known_size[slot] != size || known_cost[slot] != cost) do return -1
		seen[slot] = true
		known_size[slot], known_cost[slot] = size, cost
	}
	ids: [MAX_FILES]i64
	sizes: [MAX_FILES]i64
	credits: [MAX_FILES]i64
	resident_count := 0
	misses, total_cost: i64 = 0, 0
	hit_signature, eviction_signature, resident_mask: u64 = 0, 0, 0
	for request := 0; request < count; request += 1 {
		id, size, cost := input[2+3*request], input[3+3*request], input[4+3*request]
		position := 0
		for position < resident_count && ids[position] != id { position += 1 }
		if position < resident_count { hit_signature |= u64(1) << u64(request); continue }
		misses += 1
		total_cost += cost
		evicted_mask: u64 = 0
		used: i64 = 0
		for i := 0; i < resident_count; i += 1 { used += sizes[i] }
		for used + size > capacity_value {
			delta := credits[0] / sizes[0]
			for i := 1; i < resident_count; i += 1 { ratio := credits[i] / sizes[i]; if ratio < delta { delta = ratio } }
			kept := 0
			used = 0
			for i := 0; i < resident_count; i += 1 {
				credits[i] -= delta * sizes[i]
				if credits[i] == 0 { evicted_mask |= u64(1) << u64(ids[i]) }
				else { ids[kept], sizes[kept], credits[kept] = ids[i], sizes[i], credits[i]; used += sizes[kept]; kept += 1 }
			}
			resident_count = kept
		}
		eviction_signature |= evicted_mask << u64(8*request)
		ids[resident_count], sizes[resident_count], credits[resident_count] = id, size, cost*12
		resident_count += 1
	}
	for i := 0; i < resident_count; i += 1 { resident_mask |= u64(1) << u64(ids[i]) }
	if output == nil || capacity < 40 do return -2
	staged: [40]u8
	store_i64_le(&staged[0], 0, misses)
	store_i64_le(&staged[0], 8, total_cost)
	store_i64_le(&staged[0], 16, i64(hit_signature))
	store_i64_le(&staged[0], 24, i64(eviction_signature))
	store_i64_le(&staged[0], 32, i64(resident_mask))
	for byte := 0; byte < 40; byte += 1 { output[byte] = staged[byte] }
	return 40
}
