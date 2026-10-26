module landlord_file_caching

const max_requests = 7
const max_files = 8
const max_input = 23

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'landlord_file_caching']
pub fn landlord_file_caching(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		capacity_value, count_value := input[0], input[1]
		if capacity_value < 1 || capacity_value > 8 || count_value < 0 || count_value > max_requests ||
			length != usize(2 + 3 * count_value) { return -1 }
		mut known_size := [max_files]i64{init: 0}
		mut known_cost := [max_files]i64{init: 0}
		mut seen := [max_files]bool{init: false}
		count := int(count_value)
		for request in 0 .. count {
			id, size, cost := input[2+3*request], input[3+3*request], input[4+3*request]
			if id < 0 || id >= max_files || size < 1 || size > 4 || size > capacity_value || cost < 0 || cost > 20 { return -1 }
			slot := int(id)
			if seen[slot] && (known_size[slot] != size || known_cost[slot] != cost) { return -1 }
			seen[slot] = true
			known_size[slot], known_cost[slot] = size, cost
		}
		mut ids := [max_files]i64{init: 0}
		mut sizes := [max_files]i64{init: 0}
		mut credits := [max_files]i64{init: 0}
		mut resident_count := 0
		mut misses, total_cost := i64(0), i64(0)
		mut hit_signature, eviction_signature, resident_mask := u64(0), u64(0), u64(0)
		for request in 0 .. count {
			id, size, cost := input[2+3*request], input[3+3*request], input[4+3*request]
			mut position := 0
			for position < resident_count && ids[position] != id { position++ }
			if position < resident_count { hit_signature |= u64(1) << request; continue }
			misses++
			total_cost += cost
			mut evicted_mask := u64(0)
			mut used := i64(0)
			for i in 0 .. resident_count { used += sizes[i] }
			for used + size > capacity_value {
				mut delta := credits[0] / sizes[0]
				for i in 1 .. resident_count {
					ratio := credits[i] / sizes[i]
					if ratio < delta { delta = ratio }
				}
				mut kept := 0
				used = 0
				for i in 0 .. resident_count {
					credits[i] -= delta * sizes[i]
					if credits[i] == 0 { evicted_mask |= u64(1) << ids[i] }
					else {
						ids[kept], sizes[kept], credits[kept] = ids[i], sizes[i], credits[i]
						used += sizes[kept]
						kept++
					}
				}
				resident_count = kept
			}
			eviction_signature |= evicted_mask << (8 * request)
			ids[resident_count], sizes[resident_count], credits[resident_count] = id, size, cost * 12
			resident_count++
		}
		for i in 0 .. resident_count { resident_mask |= u64(1) << ids[i] }
		if output == nil || capacity < 40 { return -2 }
		mut staged := [40]u8{init: 0}
		store_i64_le(mut staged[..], 0, misses)
		store_i64_le(mut staged[..], 8, total_cost)
		store_i64_le(mut staged[..], 16, i64(hit_signature))
		store_i64_le(mut staged[..], 24, i64(eviction_signature))
		store_i64_le(mut staged[..], 32, i64(resident_mask))
		for byte in 0 .. 40 { output[byte] = staged[byte] }
		return 40
	}
}
