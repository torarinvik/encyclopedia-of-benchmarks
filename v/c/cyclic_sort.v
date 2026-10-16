module cyclic_sort

@[export: 'cyclic_sort']
pub fn cyclic_sort(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	max_length := 1024
	if length > usize(max_length) || (length > 0 && isnil(values)) { return -1 }
	mut seen := [1025]bool{}
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 1 || value > i64(length) || seen[int(value)] { return -1 }
		seen[int(value)] = true
	}

	mut sorted := [1024]i64{}
	for index in 0 .. int(length) { sorted[index] = unsafe { values[index] } }
	mut index := 0
	for index < int(length) {
		destination := int(sorted[index] - 1)
		if destination == index {
			index++
		} else {
			sorted[index], sorted[destination] = sorted[destination], sorted[index]
		}
	}

	output_length := int(length) * 8
	if usize(output_length) > output_capacity || (output_length > 0 && isnil(output)) { return -2 }
	mut written := 0
	for item in 0 .. int(length) {
		bits := u64(sorted[item])
		for byte in 0 .. 8 {
			unsafe { output[written] = u8((bits >> (byte * 8)) & 255) }
			written++
		}
	}
	return i64(length)
}
