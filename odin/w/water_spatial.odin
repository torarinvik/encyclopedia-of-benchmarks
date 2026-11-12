package water_spatial

import "core:c"

MAX_MOLECULES :: 64
MAX_GRID_SIDE :: 8
MAX_CELLS :: 512
MAX_INPUT_LENGTH :: 4 + 4 * MAX_MOLECULES
SCALE :: i64(1_000_000)

trunc_div :: proc(numerator, denominator: i64) -> i64 {
	if numerator < 0 { return -((-numerator) / denominator) }
	return numerator / denominator
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := u64(value)
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
water_spatial :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) { return -1 }
	count_value, grid_value, cutoff := input[0], input[1], input[2]
	if count_value < 0 || count_value > MAX_MOLECULES || grid_value < 1 || grid_value > MAX_GRID_SIDE
		|| cutoff < 1 || cutoff > 4 { return -1 }
	count, grid := int(count_value), int(grid_value)
	if length != c.size_t(3+4*count) { return -1 }
	extent := i64(grid) * cutoff
	for index := 0; index < count; index += 1 {
		base := 3 + 4*index
		if input[base] < 0 || input[base] >= extent || input[base+1] < 0 || input[base+1] >= extent
			|| input[base+2] < 0 || input[base+2] >= extent || input[base+3] < -4 || input[base+3] > 4 { return -1 }
	}
	output_bytes := c.size_t(8 * (3*count + 2))
	if output == nil || capacity < output_bytes { return -2 }

	head: [MAX_CELLS]i64
	next: [MAX_MOLECULES]i64
	force_x: [MAX_MOLECULES]i64
	force_y: [MAX_MOLECULES]i64
	force_z: [MAX_MOLECULES]i64
	for cell := 0; cell < MAX_CELLS; cell += 1 { head[cell] = -1 }
	for index := 0; index < count; index += 1 {
		base := 3 + 4*index
		cx, cy, cz := int(input[base]/cutoff), int(input[base+1]/cutoff), int(input[base+2]/cutoff)
		cell := cx + grid*(cy+grid*cz)
		next[index] = head[cell]
		head[cell] = i64(index)
	}

	energy, pairs := i64(0), i64(0)
	cutoff_squared := cutoff * cutoff
	for index := 0; index < count; index += 1 {
		base_i := 3 + 4*index
		cx, cy, cz := int(input[base_i]/cutoff), int(input[base_i+1]/cutoff), int(input[base_i+2]/cutoff)
		for oz := -1; oz < 2; oz += 1 {
			nz := cz + oz
			if nz < 0 || nz >= grid { continue }
			for oy := -1; oy < 2; oy += 1 {
				ny := cy + oy
				if ny < 0 || ny >= grid { continue }
				for ox := -1; ox < 2; ox += 1 {
					nx := cx + ox
					if nx < 0 || nx >= grid { continue }
					cell := nx + grid*(ny+grid*nz)
					candidate := head[cell]
					for candidate >= 0 {
						other := int(candidate)
						if other > index {
							base_j := 3 + 4*other
							dx, dy, dz := input[base_j]-input[base_i], input[base_j+1]-input[base_i+1], input[base_j+2]-input[base_i+2]
							r2 := dx*dx + dy*dy + dz*dz
							if r2 < cutoff_squared {
								product := input[base_i+3] * input[base_j+3]
								energy += trunc_div(product*(cutoff_squared-r2)*SCALE, (1+r2)*(1+cutoff_squared))
								denominator := (1+r2)*(1+r2)
								px := trunc_div(-2*product*dx*SCALE, denominator)
								py := trunc_div(-2*product*dy*SCALE, denominator)
								pz := trunc_div(-2*product*dz*SCALE, denominator)
								force_x[index] += px; force_x[other] -= px
								force_y[index] += py; force_y[other] -= py
								force_z[index] += pz; force_z[other] -= pz
								pairs += 1
							}
						}
						candidate = next[other]
					}
				}
			}
		}
	}
	for index := 0; index < count; index += 1 {
		store_i64_le(output, c.size_t(8*(3*index)), force_x[index])
		store_i64_le(output, c.size_t(8*(3*index+1)), force_y[index])
		store_i64_le(output, c.size_t(8*(3*index+2)), force_z[index])
	}
	store_i64_le(output, c.size_t(8*(3*count)), energy)
	store_i64_le(output, c.size_t(8*(3*count+1)), pairs)
	return i64(output_bytes)
}
