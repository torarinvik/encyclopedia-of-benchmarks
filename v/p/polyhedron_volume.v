module polyhedron_volume

const max_faces = 32
const max_parseable_length = 290
const scale = i64(1_000_000)

fn coordinate(xyz []i64, face int, corner int, axis int) i64 {
	return xyz[9 * face + 3 * corner + axis]
}

fn edge_matches(xyz []i64, face int, edge int, other_face int, other_edge int, reverse bool) bool {
	edge_end := (edge + 1) % 3
	other_end := (other_edge + 1) % 3
	mut other_start := other_edge
	mut other_finish := other_end
	if reverse { other_start = other_end; other_finish = other_edge }
	for axis in 0 .. 3 {
		if coordinate(xyz, face, edge, axis) != coordinate(xyz, other_face, other_start, axis) { return false }
		if coordinate(xyz, face, edge_end, axis) != coordinate(xyz, other_face, other_finish, axis) { return false }
	}
	return true
}

fn store_i64_le(mut output &u8, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'polyhedron_volume']
pub fn polyhedron_volume(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_parseable_length { return -1 }
	unsafe {
		face_count_value := input[0]
		if face_count_value < 4 || face_count_value > max_faces { return -1 }
		face_count := int(face_count_value)
		if length != usize(1 + 9 * face_count) { return -1 }
		mut xyz := []i64{len: max_faces * 9, init: 0}
		for face in 0 .. face_count {
			for corner in 0 .. 3 {
				for axis in 0 .. 3 {
					value := input[1 + 9 * face + 3 * corner + axis]
					if value < -50 || value > 50 { return -1 }
					xyz[9 * face + 3 * corner + axis] = value
				}
			}
			ax := coordinate(xyz, face, 1, 0) - coordinate(xyz, face, 0, 0)
			ay := coordinate(xyz, face, 1, 1) - coordinate(xyz, face, 0, 1)
			az := coordinate(xyz, face, 1, 2) - coordinate(xyz, face, 0, 2)
			bx := coordinate(xyz, face, 2, 0) - coordinate(xyz, face, 0, 0)
			by := coordinate(xyz, face, 2, 1) - coordinate(xyz, face, 0, 1)
			bz := coordinate(xyz, face, 2, 2) - coordinate(xyz, face, 0, 2)
			nx, ny, nz := ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
			if nx == 0 && ny == 0 && nz == 0 { return -1 }
		}
		for face in 0 .. face_count {
			for edge in 0 .. 3 {
				mut same_count, mut reverse_count := 0, 0
				for other_face in 0 .. face_count {
					for other_edge in 0 .. 3 {
						if edge_matches(xyz, face, edge, other_face, other_edge, false) { same_count++ }
						if edge_matches(xyz, face, edge, other_face, other_edge, true) { reverse_count++ }
					}
				}
				if same_count != 1 || reverse_count != 1 { return -1 }
			}
		}
		mut determinant_sum := i64(0)
		for face in 0 .. face_count {
			ax, ay, az := coordinate(xyz, face, 0, 0), coordinate(xyz, face, 0, 1), coordinate(xyz, face, 0, 2)
			bx, by, bz := coordinate(xyz, face, 1, 0), coordinate(xyz, face, 1, 1), coordinate(xyz, face, 1, 2)
			cx, cy, cz := coordinate(xyz, face, 2, 0), coordinate(xyz, face, 2, 1), coordinate(xyz, face, 2, 2)
			determinant_sum += ax * (by * cz - bz * cy) + ay * (bz * cx - bx * cz) + az * (bx * cy - by * cx)
		}
		mut sign := i64(1)
		if determinant_sum < 0 { sign = -1 }
		magnitude := u64(if determinant_sum < 0 { -determinant_sum } else { determinant_sum })
		scaled := magnitude * u64(scale)
		mut quotient := scaled / 6
		if 2 * (scaled % 6) >= 6 { quotient++ }
		result := sign * i64(quotient)
		if unsafe { output == nil } || capacity < 8 { return -2 }
		store_i64_le(mut output, result)
		return 8
	}
}
