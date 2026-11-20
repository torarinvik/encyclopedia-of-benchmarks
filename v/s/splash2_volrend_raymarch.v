module splash2_volrend_raymarch

const max_side = 8
const max_rays = 16
const max_samples = 32
const max_voxels = max_side * max_side * max_side
const max_parseable = 3 + 2 * max_voxels + 6 * max_rays + 1
const max_masks = 4 * max_voxels
const q8 = i64(256)
const q16 = i64(65536)
const weight_den = i64(16777216)
const alpha_den = i64(255) * weight_den
const color_den = i64(255) * 255 * weight_den

fn voxel_index(side int, x int, y int, z int) int { return (z * side + y) * side + x }
fn mask_index(level int, x int, y int, z int) int { return ((level * 8 + z) * 8 + y) * 8 + x }
fn round_half_up(numerator i64, denominator i64) i64 { return (numerator + denominator / 2) / denominator }
fn to_byte(value i64) u8 { return u8((value * 255 + q16 / 2) / q16) }

@[export: 'splash2_volrend_raymarch']
pub fn splash2_volrend_raymarch(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 3 || length > usize(max_parseable) { return -1 }
	unsafe {
		if input == nil { return -1 }
		side_raw := input[0]
		rays_raw := input[1]
		samples_raw := input[2]
		if (side_raw != 2 && side_raw != 4 && side_raw != 8) || rays_raw < 1 || rays_raw > max_rays || samples_raw < 1 || samples_raw > max_samples { return -1 }
		side := int(side_raw)
		rays_count := int(rays_raw)
		samples := int(samples_raw)
		voxel_count := side * side * side
		ray_start := 3 + 2 * voxel_count
		if length != usize(ray_start + 6 * rays_count) { return -1 }
		mut alpha := [max_voxels]u8{}
		mut gray := [max_voxels]u8{}
		mut rays := [max_rays * 6]i32{}
		for voxel in 0 .. voxel_count {
			a := input[3 + 2 * voxel]
			g := input[4 + 2 * voxel]
			if a < 0 || a > 255 || g < 0 || g > 255 { return -1 }
			alpha[voxel] = u8(a)
			gray[voxel] = u8(g)
		}
		coord_max := i64(side - 1) * q8
		for ray in 0 .. rays_count {
			at := ray_start + 6 * ray
			for axis in 0 .. 3 {
				origin := input[at + axis]
				delta := input[at + axis + 3]
				if origin < 0 || origin > coord_max || delta < -coord_max || delta > coord_max { return -1 }
				rays[6 * ray + axis] = i32(origin)
				rays[6 * ray + axis + 3] = i32(delta)
			}
			if samples > 1 && rays[6 * ray + 3] == 0 && rays[6 * ray + 4] == 0 && rays[6 * ray + 5] == 0 { return -1 }
			for sample in 0 .. samples {
				for axis in 0 .. 3 {
					q := i64(rays[6 * ray + axis]) + i64(sample) * i64(rays[6 * ray + axis + 3])
					if q < 0 || q > coord_max { return -1 }
				}
			}
		}
		output_bytes := 5 * rays_count
		if output == nil { return -2 }
		if capacity < usize(output_bytes) { return -3 }

		mut support := [max_masks]u8{}
		for z in 0 .. side { for y in 0 .. side { for x in 0 .. side {
			mut occupied := u8(0)
			for dz in 0 .. 2 { for dy in 0 .. 2 { for dx in 0 .. 2 {
				nx := if x + dx < side { x + dx } else { side - 1 }
				ny := if y + dy < side { y + dy } else { side - 1 }
				nz := if z + dz < side { z + dz } else { side - 1 }
				if alpha[voxel_index(side, nx, ny, nz)] != 0 { occupied = 1 }
			} } }
			support[mask_index(0, x, y, z)] = occupied
		} } }
		mut levels := 0
		mut dimension := side
		for dimension > 1 { dimension >>= 1; levels++ }
		for level in 1 .. levels + 1 {
			dim := side >> level
			for z in 0 .. dim { for y in 0 .. dim { for x in 0 .. dim {
				mut occupied := u8(0)
				for dz in 0 .. 2 { for dy in 0 .. 2 { for dx in 0 .. 2 {
					if support[mask_index(level - 1, 2 * x + dx, 2 * y + dy, 2 * z + dz)] != 0 { occupied = 1 }
				} } }
				support[mask_index(level, x, y, z)] = occupied
			} } }
		}
		for ray in 0 .. rays_count {
			mut accumulated_alpha := i64(0)
			mut accumulated_gray := i64(0)
			mut used := 0
			for sample in 0 .. samples {
				used = sample + 1
				xq := i64(rays[6 * ray]) + i64(sample) * i64(rays[6 * ray + 3])
				yq := i64(rays[6 * ray + 1]) + i64(sample) * i64(rays[6 * ray + 4])
				zq := i64(rays[6 * ray + 2]) + i64(sample) * i64(rays[6 * ray + 5])
				cx, cy, cz := int(xq / q8), int(yq / q8), int(zq / q8)
				mut supported := true
				for level := levels; level >= 0; level-- {
					if support[mask_index(level, cx >> level, cy >> level, cz >> level)] == 0 { supported = false; break }
				}
				if supported {
					low := [3]int{int(xq / q8), int(yq / q8), int(zq / q8)}
					frac := [3]int{int(xq % q8), int(yq % q8), int(zq % q8)}
					high := [3]int{if low[0] + 1 < side { low[0] + 1 } else { side - 1 }, if low[1] + 1 < side { low[1] + 1 } else { side - 1 }, if low[2] + 1 < side { low[2] + 1 } else { side - 1 }}
					mut opacity_sum := i64(0)
					mut premul_sum := i64(0)
					for dz in 0 .. 2 { for dy in 0 .. 2 { for dx in 0 .. 2 {
						x := if dx == 0 { low[0] } else { high[0] }
						y := if dy == 0 { low[1] } else { high[1] }
						z := if dz == 0 { low[2] } else { high[2] }
						wx := i64(if dx == 0 { 256 - frac[0] } else { frac[0] })
						wy := i64(if dy == 0 { 256 - frac[1] } else { frac[1] })
						wz := i64(if dz == 0 { 256 - frac[2] } else { frac[2] })
						idx := voxel_index(side, x, y, z)
						weight := wx * wy * wz
						opacity_sum += i64(alpha[idx]) * weight
						premul_sum += i64(alpha[idx]) * i64(gray[idx]) * weight
					} } }
					sample_alpha := round_half_up(opacity_sum * q16, alpha_den)
					sample_gray := round_half_up(premul_sum * q16, color_den)
					remaining := q16 - accumulated_alpha
					accumulated_alpha += round_half_up(remaining * sample_alpha, q16)
					accumulated_gray += round_half_up(remaining * sample_gray, q16)
					if accumulated_alpha > q16 { accumulated_alpha = q16 }
					if accumulated_gray > q16 { accumulated_gray = q16 }
					if accumulated_alpha == q16 { break }
				}
			}
			at := 5 * ray
			value := to_byte(accumulated_gray)
			output[at] = value; output[at + 1] = value; output[at + 2] = value
			output[at + 3] = to_byte(accumulated_alpha); output[at + 4] = u8(used)
		}
		return i64(output_bytes)
	}
}
