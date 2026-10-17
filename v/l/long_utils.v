module long_utils

@[export: 'long_utils']
pub fn long_utils(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length != 3 { return -1 }
	operation := unsafe { input[0] }
	distance_value := unsafe { input[2] }
	if operation < 0 || operation > 3 || distance_value < 0 || distance_value > 63 { return -1 }
	if output == nil || capacity < 8 { return -2 }
	value := unsafe { input[1] }
	bits := u64(value)
	distance := int(distance_value)
	mut rotated := bits
	if distance != 0 {
		if operation < 2 { rotated = (bits << distance) | (bits >> (64 - distance)) }
		else { rotated = (bits >> distance) | (bits << (64 - distance)) }
	}
	for byte in 0 .. 8 {
		unsafe { output[byte] = u8((rotated >> (8 * byte)) & 255) }
	}
	return 8
}
