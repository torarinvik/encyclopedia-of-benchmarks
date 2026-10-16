package look_scheduling

import "core:c"

FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

hash_i64 :: proc(hash: u64, value: i64) -> u64 {
	result := hash
	bits := transmute(u64(value))
	for shift := 0; shift < 64; shift += 8 { result = (result ^ u64(u8(bits >> u64(shift)))) * FNV_PRIME }
	return result
}

@(export)
look_scheduling :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 4100 do return -1
	max_track64, start64, direction, count64 := input[0], input[1], input[2], input[3]
	if max_track64 < 1 || max_track64 > 256 || start64 < 0 || start64 >= max_track64 ||
		(direction != 0 && direction != 1) || count64 < 0 || count64 > 4096 || length != c.size_t(count64 + 4) do return -1
	max_track, start, count := int(max_track64), int(start64), int(count64)
	var lower_counts: [256]int
	var upper_counts: [256]int
	farthest: i64 = 0
	for i := 0; i < count; i += 1 {
		request := input[4+i]
		if request < -2147483648 || request > 2147483647 do return -1
		if request >= 0 && request < max_track64 {
			track := int(request)
			if track < start { lower_counts[track] += 1 } else { upper_counts[track] += 1 }
			if request > farthest { farthest = request }
		}
	}
	var route: [4096]i64
	route_count := 0
	if direction == 1 {
		for track := start; track < max_track; track += 1 {
			for repeat := 0; repeat < upper_counts[track]; repeat += 1 { route[route_count] = i64(track); route_count += 1 }
		}
		track := start
		for track > 0 {
			track -= 1
			for repeat := 0; repeat < lower_counts[track]; repeat += 1 { route[route_count] = i64(track); route_count += 1 }
		}
	} else {
		track := start
		for track > 0 {
			track -= 1
			for repeat := 0; repeat < lower_counts[track]; repeat += 1 { route[route_count] = i64(track); route_count += 1 }
		}
		for track = start; track < max_track; track += 1 {
			for repeat := 0; repeat < upper_counts[track]; repeat += 1 { route[route_count] = i64(track); route_count += 1 }
		}
	}
	hash := hash_i64(FNV_OFFSET, i64(route_count))
	for i := 0; i < route_count; i += 1 { hash = hash_i64(hash, route[i]) }
	final_direction := i64(1)
	if direction == 1 { final_direction = 0 }
	hash = hash_i64(hash, final_direction)
	hash = hash_i64(hash, farthest)
	hash = hash_i64(hash, start64)
	return i64(hash & 0x7fffffffffffffff)
}
