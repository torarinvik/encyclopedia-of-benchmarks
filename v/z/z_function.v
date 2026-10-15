module z_function

const MaxLength = 256

@[export: 'z_function']
pub fn z_function(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if (unsafe { input == nil } && length > 0) || length > MaxLength { return -1 }
	for index in 0 .. length {
		if input[index] < 0 || input[index] > 127 { return -1 }
	}
	required := length * 8
	if capacity < required || (required > 0 && unsafe { output == nil }) { return -2 }
	mut z := []i64{len: length}
	mut left := usize(0)
	mut right := usize(0)
	for index in 1 .. length {
		if index <= right {
			prior := usize(z[index - left])
			window := right - index + 1
			z[index] = i64(if window < prior { window } else { prior })
		}
		for index + usize(z[index]) < length && input[usize(z[index])] == input[index + usize(z[index])] {
			z[index]++
		}
		if index + usize(z[index]) > right + 1 {
			left = index
			right = index + usize(z[index]) - 1
		}
	}
	for index in 0 .. length {
		bits := u64(z[index])
		for byte in 0 .. 8 {
			unsafe { output[8 * index + byte] = u8(bits >> (8 * byte)) }
		}
	}
	return i64(required)
}
