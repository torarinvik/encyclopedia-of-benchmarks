module parboil_sad

const sad_range = 16
const sad_dim = 33
const sad_positions = 1089
const sad_pad = 1092
const sad_slots = 44772
const type_counts = [8]int{0, 1, 2, 2, 4, 8, 8, 16}
const type_offsets = [8]int{0, 0, 1, 3, 5, 9, 17, 25}

fn pixel(values &i64, image int, y int, x int) int {
	packed := u32(unsafe { values[image * 64 + y * 4 + x / 4] })
	return int((packed >> ((x % 4) * 8)) & u32(255))
}

@[export: 'parboil_sad']
pub fn parboil_sad(values &i64, length usize) i64 {
	if unsafe { values == nil } || length != 128 { return -1 }
	unsafe {
		for i in 0 .. 128 { if values[i] < 0 || values[i] > 4294967295 { return -1 } }
		mut sads := [sad_slots]u16{}
		for py in -sad_range .. sad_range + 1 {
			for px in -sad_range .. sad_range + 1 {
				for by in 0 .. 4 {
					for bx in 0 .. 4 {
						base := (type_offsets[7] + by * 4 + bx) * sad_pad
						pos := (py + sad_range) * sad_dim + px + sad_range
						mut sad := u32(0)
						for y in 0 .. 4 {
							for x in 0 .. 4 {
								fy, fx := by * 4 + y, bx * 4 + x
								ry, rx := fy + py, fx + px
								if ry < 0 { ry = 0 }; if ry > 15 { ry = 15 }
								if rx < 0 { rx = 0 }; if rx > 15 { rx = 15 }
								delta := pixel(values, 0, fy, fx) - pixel(values, 1, ry, rx)
								if delta < 0 { sad += u32(-delta) } else { sad += u32(delta) }
							}
						}
						sads[base + pos] = u16(sad)
					}
				}
			}
		}

		// Source larger_sads hierarchy: types 6, 5, 4, 3, 2, then 1.
		for by in 0 .. 2 { for bx in 0 .. 4 {
			dst, src := type_offsets[6] + 4 * by + bx, type_offsets[7] + 8 * by + bx
			for p in 0 .. sad_positions { sads[dst * sad_pad + p] = sads[src * sad_pad + p] + sads[(src + 4) * sad_pad + p] }
		} }
		for by in 0 .. 4 { for bx in 0 .. 2 {
			dst, src := type_offsets[5] + 2 * by + bx, type_offsets[7] + 4 * by + 2 * bx
			for p in 0 .. sad_positions { sads[dst * sad_pad + p] = sads[src * sad_pad + p] + sads[(src + 1) * sad_pad + p] }
		} }
		for by in 0 .. 2 { for bx in 0 .. 2 {
			dst, src := type_offsets[4] + 2 * by + bx, type_offsets[5] + 4 * by + bx
			for p in 0 .. sad_positions { sads[dst * sad_pad + p] = sads[src * sad_pad + p] + sads[(src + 2) * sad_pad + p] }
		} }
		for bx in 0 .. 2 {
			dst, src := type_offsets[3] + bx, type_offsets[4] + bx
			for p in 0 .. sad_positions { sads[dst * sad_pad + p] = sads[src * sad_pad + p] + sads[(src + 2) * sad_pad + p] }
		}
		for by in 0 .. 2 {
			dst, src := type_offsets[2] + by, type_offsets[4] + 2 * by
			for p in 0 .. sad_positions { sads[dst * sad_pad + p] = sads[src * sad_pad + p] + sads[(src + 1) * sad_pad + p] }
		}
		for p in 0 .. sad_positions { sads[type_offsets[1] * sad_pad + p] = sads[type_offsets[2] * sad_pad + p] + sads[(type_offsets[2] + 1) * sad_pad + p] }

		mut checksum := i64(0)
		for kind in 1 .. 8 { for block in 0 .. type_counts[kind] {
			for p in 0 .. sad_positions { checksum += i64(sads[(type_offsets[kind] + block) * sad_pad + p]) }
		} }
		return checksum
	}
}
