module next_greater_nodes

@[export: 'next_greater_nodes']
pub fn next_greater_nodes(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length == 0 || length > 4096 { return -1 }
	for index := usize(0); index < length; index++ {
		value := unsafe { values[index] }
		if value < 1 || value > 1_000_000_000 { return -1 }
	}
	required := 4 * length
	if output_capacity < required { return -2 }
	for index := usize(0); index < length; index++ {
		value := unsafe { values[index] }
		mut next_greater := i64(0)
		for later := index + 1; later < length; later++ {
			candidate := unsafe { values[later] }
			if candidate > value {
				next_greater = candidate
				break
			}
		}
		encoded := u32(next_greater)
		unsafe {
			output[4 * index] = u8(encoded & 0xff)
			output[4 * index + 1] = u8((encoded >> 8) & 0xff)
			output[4 * index + 2] = u8((encoded >> 16) & 0xff)
			output[4 * index + 3] = u8((encoded >> 24) & 0xff)
		}
	}
	return i64(length)
}
