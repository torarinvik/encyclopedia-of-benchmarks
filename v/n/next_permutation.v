module next_permutation

const max_length = 128

fn reverse_values(mut values [max_length]i32, left int, right int) {
	mut low := left
	mut high := right
	for low < high {
		temporary := values[low]
		values[low] = values[high]
		values[high] = temporary
		low++
		high--
	}
}

fn store_i32_le(output &u8, position int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 { unsafe { output[position + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'next_permutation']
pub fn next_permutation(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 || length > max_length + 1 { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 0 || n_value > max_length || length != usize(n_value + 1) { return -1 }
	n := int(n_value)
	mut values := [max_length]i32{}
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[i] = i32(value)
	}
	required := usize(n * 4)
	if output_capacity < required { return -2 }
	mut pivot := n
	mut index := n
	for index > 1 {
		index--
		if values[index - 1] < values[index] { pivot = index - 1; break }
	}
	if pivot == n {
		if n > 1 { reverse_values(mut values, 0, n - 1) }
	} else {
		mut successor := n - 1
		for values[successor] <= values[pivot] { successor-- }
		temporary := values[pivot]
		values[pivot] = values[successor]
		values[successor] = temporary
		if pivot + 1 < n { reverse_values(mut values, pivot + 1, n - 1) }
	}
	for i in 0 .. n { store_i32_le(output, i * 4, values[i]) }
	return i64(n)
}
