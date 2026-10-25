module parboil_cutcp

import math

const max_dim = 4
const max_atoms = 4
const max_input = 25
const max_grid = 64
const inv_cell_length = f32(0.25)

struct Atom {
mut:
	x f32
	y f32
	z f32
	q f32
}

fn decode_component(raw i64) f32 { return f32(raw) / f32(1_000_000) }

fn quantize_q(value f32) i32 {
	scaled := value * f32(1_000)
	magnitude := if scaled < 0 { -scaled } else { scaled }
	mut whole := i32(magnitude)
	if magnitude - f32(whole) >= f32(0.5) { whole++ }
	if scaled < 0 { return -whole }
	return whole
}

fn write_i32_le(output &u8, offset int, value i32) {
	bits := u32(value)
	unsafe {
		output[offset] = u8(bits)
		output[offset + 1] = u8(bits >> 8)
		output[offset + 2] = u8(bits >> 16)
		output[offset + 3] = u8(bits >> 24)
	}
}

@[export: 'parboil_cutcp']
pub fn parboil_cutcp(input &i64, input_length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 13 || input_length > max_input { return -1 }
	mut values := [max_input]i64{}
	unsafe {
		for i in 0 .. int(input_length) { values[i] = input[i] }
	}
	if values[0] < 2 || values[0] > max_dim || values[1] < 2 || values[1] > max_dim
		|| values[2] < 2 || values[2] > max_dim || values[3] < 1 || values[3] > max_atoms { return -1 }
	nx, ny, nz, atom_count := int(values[0]), int(values[1]), int(values[2]), int(values[3])
	if input_length != usize(9 + 4 * atom_count) { return -1 }
	xlo_raw, ylo_raw, zlo_raw := values[4], values[5], values[6]
	spacing_raw, cutoff_raw := values[7], values[8]
	if xlo_raw < -16_000_000 || xlo_raw > 16_000_000 || ylo_raw < -16_000_000 || ylo_raw > 16_000_000
		|| zlo_raw < -16_000_000 || zlo_raw > 16_000_000 || xlo_raw % 1_000_000 != 0
		|| ylo_raw % 1_000_000 != 0 || zlo_raw % 1_000_000 != 0
		|| spacing_raw < 1_000_000 || spacing_raw > 4_000_000 || spacing_raw % 1_000_000 != 0
		|| cutoff_raw < 250_000 || cutoff_raw > 4_000_000 { return -1 }
	for n in 0 .. atom_count {
		offset := 9 + 4 * n
		if values[offset] < 0 || values[offset] >= nx - 1 || values[offset + 1] < 0
			|| values[offset + 1] >= ny - 1 || values[offset + 2] < 0
			|| values[offset + 2] >= nz - 1 || values[offset + 3] < -1_000_000
			|| values[offset + 3] > 1_000_000 { return -1 }
	}
	points := nx * ny * nz
	output_bytes := 4 * points
	if unsafe { output == nil } || output_capacity < usize(output_bytes) { return -2 }

	xlo, ylo, zlo := decode_component(xlo_raw), decode_component(ylo_raw), decode_component(zlo_raw)
	spacing, cutoff := decode_component(spacing_raw), decode_component(cutoff_raw)
	half_spacing := spacing * f32(0.5)
	mut atoms := [max_atoms]Atom{}
	for n in 0 .. atom_count {
		offset := 9 + 4 * n
		ix, iy, iz := int(values[offset]), int(values[offset + 1]), int(values[offset + 2])
		atoms[n] = Atom{x: xlo + (f32(ix) * spacing + half_spacing),
			y: ylo + (f32(iy) * spacing + half_spacing),
			z: zlo + (f32(iz) * spacing + half_spacing), q: decode_component(values[offset + 3])}
	}
	mut min_x, mut max_x := atoms[0].x, atoms[0].x
	mut min_y, mut max_y := atoms[0].y, atoms[0].y
	mut min_z, mut max_z := atoms[0].z, atoms[0].z
	for n in 1 .. atom_count {
		if atoms[n].x < min_x { min_x = atoms[n].x }
		if atoms[n].x > max_x { max_x = atoms[n].x }
		if atoms[n].y < min_y { min_y = atoms[n].y }
		if atoms[n].y > max_y { max_y = atoms[n].y }
		if atoms[n].z < min_z { min_z = atoms[n].z }
		if atoms[n].z > max_z { max_z = atoms[n].z }
	}
	nx_cell := int(math.floor(f64((max_x - min_x) * inv_cell_length))) + 1
	ny_cell := int(math.floor(f64((max_y - min_y) * inv_cell_length))) + 1
	nz_cell := int(math.floor(f64((max_z - min_z) * inv_cell_length))) + 1
	cell_count := nx_cell * ny_cell * nz_cell
	mut first := [max_grid]int{}
	mut next := [max_atoms]int{}
	for c in 0 .. cell_count { first[c] = -1 }
	for n in 0 .. atom_count { next[n] = -1 }
	for n in 0 .. atom_count {
		if atoms[n].q == f32(0) { continue }
		i := int(math.floor(f64((atoms[n].x - min_x) * inv_cell_length)))
		j := int(math.floor(f64((atoms[n].y - min_y) * inv_cell_length)))
		k := int(math.floor(f64((atoms[n].z - min_z) * inv_cell_length)))
		cell := (k * ny_cell + j) * nx_cell + i
		next[n] = first[cell]
		first[cell] = n
	}

	cutoff_squared := cutoff * cutoff
	inv_cutoff_squared := f32(1) / cutoff_squared
	inv_spacing := f32(1) / spacing
	radius := int(math.ceil(f64(cutoff * inv_spacing))) - 1
	mut grid := [max_grid]f32{}
	for c in 0 .. cell_count {
		mut n := first[c]
		for n != -1 {
			x, y, z, q := atoms[n].x - xlo, atoms[n].y - ylo, atoms[n].z - zlo, atoms[n].q
			ic, jc, kc := int(x * inv_spacing), int(y * inv_spacing), int(z * inv_spacing)
			mut ia, mut ib := ic - radius, ic + radius + 1
			mut ja, mut jb := jc - radius, jc + radius + 1
			mut ka, mut kb := kc - radius, kc + radius + 1
			if ia < 0 { ia = 0 }
			if ib >= nx { ib = nx - 1 }
			if ja < 0 { ja = 0 }
			if jb >= ny { jb = ny - 1 }
			if ka < 0 { ka = 0 }
			if kb >= nz { kb = nz - 1 }
			xstart, ystart := f32(ia) * spacing - x, f32(ja) * spacing - y
			mut dz := f32(ka) * spacing - z
			for k := ka; k <= kb; k++ {
				koff := k * ny
				dz2 := dz * dz
				mut dy := ystart
				for j := ja; j <= jb; j++ {
					jkoff := (koff + j) * nx
					dydz2 := dy * dy + dz2
					if dydz2 < cutoff_squared {
						mut dx := xstart
						for i := ia; i <= ib; i++ {
							r2 := dx * dx + dydz2
							if r2 < cutoff_squared {
								s := f32(1) - r2 * inv_cutoff_squared
								reciprocal_r := f32(1.0 / math.sqrt(f64(r2)))
								mut energy := q * reciprocal_r
								energy = energy * s
								energy = energy * s
								grid[jkoff + i] = grid[jkoff + i] + energy
							}
							dx += spacing
						}
					}
					dy += spacing
				}
				dz += spacing
			}
			n = next[n]
		}
	}
	for point in 0 .. points { write_i32_le(output, 4 * point, quantize_q(grid[point])) }
	return i64(output_bytes)
}
