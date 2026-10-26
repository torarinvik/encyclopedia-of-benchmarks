package randomized_ray_search

import "core:c"

MAX_RAYS :: 5
MAX_ROUNDS :: 32
MAX_INPUT :: 11

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

randomized_ray_search :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_INPUT do return -1
	rays_raw, growth, initial := input[0], input[1], input[2]
	if rays_raw < 2 || rays_raw > MAX_RAYS || growth < 2 || growth > 4 || initial < 1000 || initial >= growth * 1000 || int(length) != int(rays_raw) + 5 do return -1
	rays := int(rays_raw)
	permutation: [MAX_RAYS]int
	seen: [MAX_RAYS]bool
	for i := 0; i < rays; i += 1 {
		ray := input[3 + i]
		if ray < 0 || ray >= rays_raw do return -1
		index := int(ray)
		if seen[index] do return -1
		seen[index] = true
		permutation[i] = index
	}
	target, target_distance := input[3 + rays], input[4 + rays]
	if target < 0 || target >= rays_raw || target_distance < 1 || target_distance > 1000000000 do return -1

	distance := initial
	total: i64 = 0
	attempts: i64 = 0
	found := false
	for round := 0; round < MAX_ROUNDS; round += 1 {
		ray := permutation[round % rays]
		attempts += 1
		if i64(ray) == target && target_distance <= distance {
			total += target_distance
			found = true
			break
		}
		total += 2 * distance
		distance *= growth
	}
	if !found do return -1
	if output == nil || capacity < 16 do return -2
	staged: [16]u8
	store_i64_le(&staged[0], attempts)
	store_i64_le(&staged[8], total)
	for byte := 0; byte < 16; byte += 1 { output[byte] = staged[byte] }
	return 16
}
