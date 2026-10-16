module main

const max_values = 6
const bytes_per_value = 8

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. bytes_per_value {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn emit_row(values &i64, n int, mut output &u8, mut rows &int) {
	row_offset := rows * n * bytes_per_value
	for index in 0 .. n {
		unsafe { store_i64_le(mut output, row_offset + index * bytes_per_value, values[index]) }
	}
	rows++
}

fn generate(mut values &i64, n int, k int, mut output &u8, mut rows &int) {
	if k == 1 {
		emit_row(values, n, mut output, mut rows)
		return
	}
	generate(mut values, n, k - 1, mut output, mut rows)
	for index in 0 .. k - 1 {
		swap_index := if k % 2 == 0 { index } else { 0 }
		unsafe {
			temporary := values[swap_index]
			values[swap_index] = values[k - 1]
			values[k - 1] = temporary
		}
		generate(mut values, n, k - 1, mut output, mut rows)
	}
}

@[export: 'heaps_algorithm']
pub fn heaps_algorithm(values &i64, length usize, mut output &u8, capacity usize) i64 {
	if values == nil || length < 1 || length > usize(max_values) { return -1 }
	n := int(length)
	mut row_count := 1
	for factor := 2; factor <= n; factor++ { row_count *= factor }
	required := row_count * n * bytes_per_value
	if output == nil || capacity < usize(required) { return -2 }
	mut items := [max_values]i64{}
	unsafe { for index in 0 .. n { items[index] = values[index] } }
	mut rows := 0
	unsafe { generate(mut items[0], n, n, mut output, mut rows) }
	return i64(rows)
}
