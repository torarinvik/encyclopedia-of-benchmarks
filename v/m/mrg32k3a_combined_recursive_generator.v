module mrg32k3a_combined_recursive_generator

const m1 = i64(4_294_967_087)
const m2 = i64(4_294_944_443)
const max_count = i64(64)

fn residue(value i64, modulus i64) i64 {
	mut result := value % modulus
	if result < 0 { result += modulus }
	return result
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'mrg32k3a_combined_recursive_generator']
pub fn mrg32k3a_combined_recursive_generator(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 7 { return -1 }
	mut x1 := [3]i64{}
	mut x2 := [3]i64{}
	for index in 0 .. 3 {
		x1[index] = unsafe { input[index] }
		x2[index] = unsafe { input[index + 3] }
		if x1[index] < 0 || x1[index] >= m1 || x2[index] < 0 || x2[index] >= m2 { return -1 }
	}
	if (x1[0] | x1[1] | x1[2]) == 0 || (x2[0] | x2[1] | x2[2]) == 0 { return -1 }
	count_value := unsafe { input[6] }
	if count_value < 0 || count_value > max_count { return -1 }
	count := int(count_value)
	required := count * 8
	if count == 0 { return 0 }
	if capacity < usize(required) || unsafe { output == nil } { return -2 }

	for step in 0 .. count {
		next1 := residue(1_403_580 * x1[1] - 810_728 * x1[0], m1)
		next2 := residue(527_612 * x2[2] - 1_370_589 * x2[0], m2)
		x1[0] = x1[1]; x1[1] = x1[2]; x1[2] = next1
		x2[0] = x2[1]; x2[1] = x2[2]; x2[2] = next2
		mut z := next1 - next2
		if z < 0 { z += m1 }
		put_i64_le(mut output, step * 8, z)
	}
	return i64(required)
}
