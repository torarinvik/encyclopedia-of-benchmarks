package greedy_dual_weighted_caching

import "core:c"

MAX_REQUESTS :: 7
MAX_FILES :: 8
MAX_INPUT :: 16

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
greedy_dual_weighted_caching :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	cache_capacity, count_value := input[0], input[1]
	if cache_capacity < 1 || cache_capacity > MAX_FILES || count_value < 0 || count_value > MAX_REQUESTS ||
		length != c.size_t(2 + 2*count_value) do return -1
	known_cost: [MAX_FILES]i64
	seen: [MAX_FILES]bool
	count := int(count_value)
	for request := 0; request < count; request += 1 {
		id, cost := input[2+2*request], input[3+2*request]
		if id < 0 || id >= MAX_FILES || cost < 0 || cost > 20 do return -1
		slot := int(id)
		if seen[slot] && known_cost[slot] != cost do return -1
		seen[slot], known_cost[slot] = true, cost
	}
	ids: [MAX_FILES]i64
	credits: [MAX_FILES]i64
	resident_count := 0
	misses, total_cost: i64 = 0, 0
	hit_signature, eviction_signature, resident_mask: u64 = 0, 0, 0
	for request := 0; request < count; request += 1 {
		id, cost := input[2+2*request], input[3+2*request]
		position := 0
		for position < resident_count && ids[position] != id { position += 1 }
		if position < resident_count {
			hit_signature |= u64(1) << u64(request)
			credits[position] = cost
			continue
		}
		misses += 1
		total_cost += cost
		var evicted_mask: u64 = 0
		for resident_count >= int(cache_capacity) {
			delta := credits[0]
			for i := 1; i < resident_count; i += 1 { if credits[i] < delta { delta = credits[i] } }
			kept := 0
			for i := 0; i < resident_count; i += 1 {
				credits[i] -= delta
				if credits[i] == 0 { evicted_mask |= u64(1) << u64(ids[i]) }
				else { ids[kept], credits[kept] = ids[i], credits[i]; kept += 1 }
			}
			resident_count = kept
		}
		eviction_signature |= evicted_mask << u64(8*request)
		ids[resident_count], credits[resident_count] = id, cost
		resident_count += 1
	}
	for i := 0; i < resident_count; i += 1 { resident_mask |= u64(1) << u64(ids[i]) }
	if output == nil || output_capacity < 40 do return -2
	staged: [40]u8
	for byte := 0; byte < 40; byte += 1 { staged[byte] = 0 }
	store_i64_le(&staged[0], 0, misses)
	store_i64_le(&staged[0], 8, total_cost)
	store_i64_le(&staged[0], 16, i64(hit_signature))
	store_i64_le(&staged[0], 24, i64(eviction_signature))
	store_i64_le(&staged[0], 32, i64(resident_mask))
	for byte := 0; byte < 40; byte += 1 { output[byte] = staged[byte] }
	return 40
}
