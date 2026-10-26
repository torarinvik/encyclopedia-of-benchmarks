module randomized_ray_search

const max_rays = 5
const max_rounds = 32
const max_input = 11

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'randomized_ray_search']
pub fn randomized_ray_search(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_input { return -1 }
		rays_raw, growth, initial := input[0], input[1], input[2]
		if rays_raw < 2 || rays_raw > max_rays || growth < 2 || growth > 4 ||
			initial < 1000 || initial >= growth * 1000 || length != usize(rays_raw + 5) { return -1 }
		rays := int(rays_raw)
		mut permutation := [max_rays]int{init: 0}
		mut seen := [max_rays]bool{init: false}
		for i in 0 .. rays {
			ray := input[3 + i]
			if ray < 0 || ray >= rays_raw { return -1 }
			index := int(ray)
			if seen[index] { return -1 }
			seen[index] = true
			permutation[i] = index
		}
		target, target_distance := input[3 + rays], input[4 + rays]
		if target < 0 || target >= rays_raw || target_distance < 1 || target_distance > 1000000000 { return -1 }
		mut distance, mut total := initial, i64(0)
		mut attempts := i64(0)
		mut found := false
		for round in 0 .. max_rounds {
			ray := permutation[round % rays]
			attempts++
			if i64(ray) == target && target_distance <= distance {
				total += target_distance
				found = true
				break
			}
			total += 2 * distance
			distance *= growth
		}
		if !found { return -1 }
		if output == nil || capacity < 16 { return -2 }
		mut staged := [16]u8{init: 0}
		store_i64_le(mut staged[..], 0, attempts)
		store_i64_le(mut staged[..], 8, total)
		for byte in 0 .. 16 { output[byte] = staged[byte] }
		return 16
	}
}
