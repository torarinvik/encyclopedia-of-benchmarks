module main

const max_n = 7

fn emit_row(items &u8, n int, mut output &u8, mut rows &int) {
	offset := rows * n
	for index in 0 .. n {
		unsafe { output[offset + index] = items[index] }
	}
	rows++
}

fn generate(mut items &u8, n int, size int, mut output &u8, mut rows &int) {
	if size == 1 {
		emit_row(items, n, mut output, mut rows)
		return
	}
	for index in 0 .. size {
		generate(mut items, n, size - 1, mut output, mut rows)
		swap_index := if size % 2 == 1 { index } else { 0 }
		unsafe {
			temporary := items[swap_index]
			items[swap_index] = items[size - 1]
			items[size - 1] = temporary
		}
	}
}

@[export: 'heaps']
pub fn heaps(values &i64, length usize, mut output &u8, capacity usize) i64 {
	if values == nil || length != 1 { return -1 }
	n64 := unsafe { values[0] }
	if n64 < 0 || n64 > max_n { return -1 }
	n := int(n64)
	if n == 0 { return 0 }
	mut row_count := 1
	for factor := 2; factor <= n; factor++ { row_count *= factor }
	required := row_count * n
	if output == nil || capacity < usize(required) { return -2 }
	mut items := [max_n]u8{}
	for index in 0 .. n { items[index] = u8(49 + index) }
	mut rows := 0
	unsafe { generate(mut items[0], n, n, mut output, mut rows) }
	return i64(rows)
}
