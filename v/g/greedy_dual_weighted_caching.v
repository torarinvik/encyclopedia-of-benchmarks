module greedy_dual_weighted_caching

const max_requests = 7
const max_files = 8
const max_input = 16

fn store_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'greedy_dual_weighted_caching']
pub fn greedy_dual_weighted_caching(input &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if isnil(input) || length < 2 || length > max_input { return -1 }
		cache_capacity, count_value := input[0], input[1]
		if cache_capacity < 1 || cache_capacity > max_files || count_value < 0 || count_value > max_requests ||
			length != usize(2 + 2*count_value) { return -1 }
		mut known_cost := [max_files]i64{init: 0}
		mut seen := [max_files]bool{init: false}
		count := int(count_value)
		for request in 0 .. count {
			id, cost := input[2+2*request], input[3+2*request]
			if id < 0 || id >= max_files || cost < 0 || cost > 20 { return -1 }
			slot := int(id)
			if seen[slot] && known_cost[slot] != cost { return -1 }
			seen[slot], known_cost[slot] = true, cost
		}
		mut ids := [max_files]i64{init: 0}
		mut credits := [max_files]i64{init: 0}
		mut resident_count := 0
		mut misses, total_cost := i64(0), i64(0)
		mut hit_signature, eviction_signature, resident_mask := u64(0), u64(0), u64(0)
		for request in 0 .. count {
			id, cost := input[2+2*request], input[3+2*request]
			mut position := 0
			for position < resident_count && ids[position] != id { position++ }
			if position < resident_count {
				hit_signature |= u64(1) << u64(request)
				credits[position] = cost
				continue
			}
			misses++
			total_cost += cost
			mut evicted_mask := u64(0)
			for resident_count >= int(cache_capacity) {
				mut delta := credits[0]
				for i in 1 .. resident_count { if credits[i] < delta { delta = credits[i] } }
				mut kept := 0
				for i in 0 .. resident_count {
					credits[i] -= delta
					if credits[i] == 0 { evicted_mask |= u64(1) << u64(ids[i]) }
					else { ids[kept], credits[kept] = ids[i], credits[i]; kept++ }
				}
				resident_count = kept
			}
			eviction_signature |= evicted_mask << u64(8*request)
			ids[resident_count], credits[resident_count] = id, cost
			resident_count++
		}
		for i in 0 .. resident_count { resident_mask |= u64(1) << u64(ids[i]) }
		if isnil(output) || output_capacity < 40 { return -2 }
		mut staged := [40]u8{init: 0}
		store_i64_le(&staged[0], 0, misses)
		store_i64_le(&staged[0], 8, total_cost)
		store_i64_le(&staged[0], 16, i64(hit_signature))
		store_i64_le(&staged[0], 24, i64(eviction_signature))
		store_i64_le(&staged[0], 32, i64(resident_mask))
		for byte in 0 .. 40 { output[byte] = staged[byte] }
		return 40
	}
}
