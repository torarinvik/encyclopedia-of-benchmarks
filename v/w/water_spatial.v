module water_spatial

const max_molecules = 64
const max_grid_side = 8
const max_cells = 512
const max_input_length = 4 + 4 * max_molecules
const scale = i64(1000000)

fn water_spatial_trunc_div(numerator i64, denominator i64) i64 {
	if numerator < 0 { return -((-numerator) / denominator) }
	return numerator / denominator
}

fn water_spatial_store_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'water_spatial']
pub fn water_spatial(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input_length { return -1 }
		count_value, grid_value, cutoff := input[0], input[1], input[2]
		if count_value < 0 || count_value > max_molecules || grid_value < 1 || grid_value > max_grid_side
			|| cutoff < 1 || cutoff > 4 { return -1 }
		count, grid := int(count_value), int(grid_value)
		if length != usize(3 + 4 * count) { return -1 }
		extent := i64(grid) * cutoff
		for index in 0 .. count {
			base := 3 + 4 * index
			if input[base] < 0 || input[base] >= extent || input[base+1] < 0 || input[base+1] >= extent
				|| input[base+2] < 0 || input[base+2] >= extent || input[base+3] < -4 || input[base+3] > 4 { return -1 }
		}
		output_bytes := 8 * (3 * count + 2)
		if output == nil || capacity < usize(output_bytes) { return -2 }

		mut head := [max_cells]i64{}
		mut next := [max_molecules]i64{}
		mut force_x := [max_molecules]i64{}
		mut force_y := [max_molecules]i64{}
		mut force_z := [max_molecules]i64{}
		for cell in 0 .. max_cells { head[cell] = -1 }
		for index in 0 .. count {
			base := 3 + 4 * index
			cx, cy, cz := int(input[base] / cutoff), int(input[base+1] / cutoff), int(input[base+2] / cutoff)
			cell := cx + grid * (cy + grid * cz)
			next[index] = head[cell]
			head[cell] = i64(index)
		}

		mut energy := i64(0)
		mut pairs := i64(0)
		cutoff_squared := cutoff * cutoff
		for index in 0 .. count {
			base_i := 3 + 4 * index
			cx, cy, cz := int(input[base_i] / cutoff), int(input[base_i+1] / cutoff), int(input[base_i+2] / cutoff)
			for oz in -1 .. 2 {
				nz := cz + oz
				if nz < 0 || nz >= grid { continue }
				for oy in -1 .. 2 {
					ny := cy + oy
					if ny < 0 || ny >= grid { continue }
					for ox in -1 .. 2 {
						nx := cx + ox
						if nx < 0 || nx >= grid { continue }
						cell := nx + grid * (ny + grid * nz)
						mut candidate := head[cell]
						for candidate >= 0 {
							other := int(candidate)
							if other > index {
								base_j := 3 + 4 * other
								dx, dy, dz := input[base_j]-input[base_i], input[base_j+1]-input[base_i+1], input[base_j+2]-input[base_i+2]
								r2 := dx*dx + dy*dy + dz*dz
								if r2 < cutoff_squared {
									product := input[base_i+3] * input[base_j+3]
									energy += water_spatial_trunc_div(product*(cutoff_squared-r2)*scale, (1+r2)*(1+cutoff_squared))
									denominator := (1+r2)*(1+r2)
									px := water_spatial_trunc_div(-2*product*dx*scale, denominator)
									py := water_spatial_trunc_div(-2*product*dy*scale, denominator)
									pz := water_spatial_trunc_div(-2*product*dz*scale, denominator)
									force_x[index] += px; force_x[other] -= px
									force_y[index] += py; force_y[other] -= py
									force_z[index] += pz; force_z[other] -= pz
									pairs++
								}
							}
							candidate = next[other]
						}
					}
				}
			}
		}
		for index in 0 .. count {
			water_spatial_store_i64(mut output, 8*(3*index), force_x[index])
			water_spatial_store_i64(mut output, 8*(3*index+1), force_y[index])
			water_spatial_store_i64(mut output, 8*(3*index+2), force_z[index])
		}
		water_spatial_store_i64(mut output, 8*(3*count), energy)
		water_spatial_store_i64(mut output, 8*(3*count+1), pairs)
		return i64(output_bytes)
	}
}
