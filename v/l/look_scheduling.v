const max_requests = 4096
const max_track_bound = 256
const fnv_offset = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)

fn hash_i64(mut hash u64, value i64) u64 {
	bits := u64(value)
	for shift in 0 .. 8 { hash = (hash ^ u64(u8(bits >> (shift * 8)))) * fnv_prime }
	return hash
}

@[export: 'look_scheduling']
pub fn look_scheduling(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_requests + 4 { return -1 }
	max_track64 := unsafe { input[0] }
	start64 := unsafe { input[1] }
	direction := unsafe { input[2] }
	count64 := unsafe { input[3] }
	if max_track64 < 1 || max_track64 > max_track_bound || start64 < 0 || start64 >= max_track64 || (direction != 0 && direction != 1) || count64 < 0 || count64 > max_requests || length != usize(count64 + 4) { return -1 }
	max_track := int(max_track64)
	start := int(start64)
	count := int(count64)
	mut lower_counts := [max_track_bound]int{}
	mut upper_counts := [max_track_bound]int{}
	mut farthest := i64(0)
	for i in 0 .. count {
		request := unsafe { input[4 + i] }
		if request < i64(-2147483648) || request > i64(2147483647) { return -1 }
		if request >= 0 && request < max_track64 {
			track := int(request)
			if track < start { lower_counts[track]++ } else { upper_counts[track]++ }
			if request > farthest { farthest = request }
		}
	}
	mut route := [max_requests]i64{}
	mut route_count := 0
	if direction == 1 {
		for track in start .. max_track {
			for _ in 0 .. upper_counts[track] { route[route_count] = i64(track); route_count++ }
		}
		mut track := start
		for track > 0 {
			track--
			for _ in 0 .. lower_counts[track] { route[route_count] = i64(track); route_count++ }
		}
	} else {
		mut track := start
		for track > 0 {
			track--
			for _ in 0 .. lower_counts[track] { route[route_count] = i64(track); route_count++ }
		}
		for track in start .. max_track {
			for _ in 0 .. upper_counts[track] { route[route_count] = i64(track); route_count++ }
		}
	}
	mut hash := hash_i64(fnv_offset, i64(route_count))
	for i in 0 .. route_count { hash = hash_i64(hash, route[i]) }
	final_direction := if direction == 1 { i64(0) } else { i64(1) }
	hash = hash_i64(hash, final_direction)
	hash = hash_i64(hash, farthest)
	hash = hash_i64(hash, start64)
	return i64(hash & u64(0x7fffffffffffffff))
}
