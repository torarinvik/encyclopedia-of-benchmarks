package splash2_volrend_raymarch

import "core:c"

MAX_SIDE :: 8
MAX_RAYS :: 16
MAX_SAMPLES :: 32
MAX_VOXELS :: MAX_SIDE * MAX_SIDE * MAX_SIDE
MAX_PARSEABLE :: 3 + 2 * MAX_VOXELS + 6 * MAX_RAYS + 1
MAX_MASKS :: 4 * MAX_VOXELS
Q8 :: i64(256)
Q16 :: i64(65536)
WEIGHT_DEN :: i64(16777216)
ALPHA_DEN :: i64(255) * WEIGHT_DEN
COLOR_DEN :: i64(255) * 255 * WEIGHT_DEN

voxel_index :: proc "contextless" (side, x, y, z: int) -> int {
	return (z * side + y) * side + x
}

mask_index :: proc "contextless" (level, x, y, z: int) -> int {
	return ((level * 8 + z) * 8 + y) * 8 + x
}

round_half_up :: proc "contextless" (numerator, denominator: i64) -> i64 {
	return (numerator + denominator / 2) / denominator
}

to_byte :: proc "contextless" (q16: i64) -> u8 {
	return u8((q16 * 255 + Q16 / 2) / Q16)
}

@(export)
splash2_volrend_raymarch :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_PARSEABLE) do return -1
	side_raw, ray_raw, samples_raw := input[0], input[1], input[2]
	if (side_raw != 2 && side_raw != 4 && side_raw != 8) || ray_raw < 1 || ray_raw > MAX_RAYS || samples_raw < 1 || samples_raw > MAX_SAMPLES do return -1
	side, ray_count, samples := int(side_raw), int(ray_raw), int(samples_raw)
	voxel_count := side * side * side
	ray_start := 3 + 2 * voxel_count
	if length != c.size_t(ray_start + 6 * ray_count) do return -1

	var alpha: [MAX_VOXELS]u8
	var gray: [MAX_VOXELS]u8
	var rays: [MAX_RAYS * 6]i32
	for voxel := 0; voxel < voxel_count; voxel += 1 {
		a, g := input[3 + 2 * voxel], input[4 + 2 * voxel]
		if a < 0 || a > 255 || g < 0 || g > 255 do return -1
		alpha[voxel], gray[voxel] = u8(a), u8(g)
	}
	coord_max := i64(side - 1) * Q8
	for ray := 0; ray < ray_count; ray += 1 {
		at := ray_start + 6 * ray
		for axis := 0; axis < 3; axis += 1 {
			origin, delta := input[at + axis], input[at + axis + 3]
			if origin < 0 || origin > coord_max || delta < -coord_max || delta > coord_max do return -1
			rays[6 * ray + axis], rays[6 * ray + axis + 3] = i32(origin), i32(delta)
		}
		if samples > 1 && rays[6 * ray + 3] == 0 && rays[6 * ray + 4] == 0 && rays[6 * ray + 5] == 0 do return -1
		for sample := 0; sample < samples; sample += 1 {
			for axis := 0; axis < 3; axis += 1 {
				q := i64(rays[6 * ray + axis]) + i64(sample) * i64(rays[6 * ray + axis + 3])
				if q < 0 || q > coord_max do return -1
			}
		}
	}
	output_bytes := 5 * ray_count
	if output == nil do return -2
	if capacity < c.size_t(output_bytes) do return -3

	var support: [MAX_MASKS]u8
	for z := 0; z < side; z += 1 {
		for y := 0; y < side; y += 1 {
			for x := 0; x < side; x += 1 {
				var occupied: u8 = 0
				for dz := 0; dz < 2; dz += 1 {
					for dy := 0; dy < 2; dy += 1 {
						for dx := 0; dx < 2; dx += 1 {
							nx, ny, nz := x + dx, y + dy, z + dz
							if nx >= side do nx = side - 1
							if ny >= side do ny = side - 1
							if nz >= side do nz = side - 1
							if alpha[voxel_index(side, nx, ny, nz)] != 0 do occupied = 1
						}
					}
				}
				support[mask_index(0, x, y, z)] = occupied
			}
		}
	}
	levels, dimension := 0, side
	for dimension > 1 { dimension >>= 1; levels += 1 }
	for level := 1; level <= levels; level += 1 {
		dim := side >> level
		for z := 0; z < dim; z += 1 {
			for y := 0; y < dim; y += 1 {
				for x := 0; x < dim; x += 1 {
					var occupied: u8 = 0
					for dz := 0; dz < 2; dz += 1 {
						for dy := 0; dy < 2; dy += 1 {
							for dx := 0; dx < 2; dx += 1 {
								if support[mask_index(level - 1, 2 * x + dx, 2 * y + dy, 2 * z + dz)] != 0 do occupied = 1
							}
						}
					}
					support[mask_index(level, x, y, z)] = occupied
				}
			}
		}
	}
	for ray := 0; ray < ray_count; ray += 1 {
		accumulated_alpha, accumulated_gray: i64 = 0, 0
		used := 0
		for sample := 0; sample < samples; sample += 1 {
			used = sample + 1
			xq := i64(rays[6 * ray]) + i64(sample) * i64(rays[6 * ray + 3])
			yq := i64(rays[6 * ray + 1]) + i64(sample) * i64(rays[6 * ray + 4])
			zq := i64(rays[6 * ray + 2]) + i64(sample) * i64(rays[6 * ray + 5])
			cx, cy, cz := int(xq / Q8), int(yq / Q8), int(zq / Q8)
			supported := true
			for level := levels; level >= 0; level -= 1 {
				if support[mask_index(level, cx >> level, cy >> level, cz >> level)] == 0 {
					supported = false
					break
				}
			}
			if supported {
				low := [3]int{cx, cy, cz}
				frac := [3]int{int(xq % Q8), int(yq % Q8), int(zq % Q8)}
				high := [3]int{}
				for axis := 0; axis < 3; axis += 1 {
					high[axis] = low[axis] + 1
					if high[axis] >= side do high[axis] = side - 1
				}
				var opacity_sum, premul_sum: i64 = 0, 0
				for dz := 0; dz < 2; dz += 1 {
					for dy := 0; dy < 2; dy += 1 {
						for dx := 0; dx < 2; dx += 1 {
							x, y, z := low[0], low[1], low[2]
							wx, wy, wz := 256 - frac[0], 256 - frac[1], 256 - frac[2]
							if dx != 0 { x, wx = high[0], frac[0] }
							if dy != 0 { y, wy = high[1], frac[1] }
							if dz != 0 { z, wz = high[2], frac[2] }
							at_voxel := voxel_index(side, x, y, z)
							weight := i64(wx) * i64(wy) * i64(wz)
							opacity_sum += i64(alpha[at_voxel]) * weight
							premul_sum += i64(alpha[at_voxel]) * i64(gray[at_voxel]) * weight
						}
					}
				}
				sample_alpha := round_half_up(opacity_sum * Q16, ALPHA_DEN)
				sample_gray := round_half_up(premul_sum * Q16, COLOR_DEN)
				remaining := Q16 - accumulated_alpha
				accumulated_alpha += round_half_up(remaining * sample_alpha, Q16)
				accumulated_gray += round_half_up(remaining * sample_gray, Q16)
				if accumulated_alpha > Q16 do accumulated_alpha = Q16
				if accumulated_gray > Q16 do accumulated_gray = Q16
				if accumulated_alpha == Q16 do break
			}
		}
		at := 5 * ray
		value := to_byte(accumulated_gray)
		output[at], output[at + 1], output[at + 2] = value, value, value
		output[at + 3], output[at + 4] = to_byte(accumulated_alpha), u8(used)
	}
	return i64(output_bytes)
}
