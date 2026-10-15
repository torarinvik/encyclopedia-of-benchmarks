module collatz_sequence

const max_start = 1000000

fn next_term(value i64) i64 {
	if value % 2 == 0 { return value / 2 }
	return 3 * value + 1
}

fn store_i64_le(output &mut u8, offset usize, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 0xff) }
	}
}

@[export: 'collatz_sequence']
pub fn collatz_sequence(input &i64, length usize, output &mut u8, output_capacity usize) i64 {
	if length != 1 { return -1 }
	start := unsafe { input[0] }
	if start < 1 || start > max_start { return -1 }
	mut current := start
	mut term_count := usize(1)
	for current != 1 { current = next_term(current); term_count++ }
	required := term_count * 8
	if output_capacity < required { return -2 }
	current = start
	mut written := usize(0)
	for {
		store_i64_le(mut output, written, current)
		written += 8
		if current == 1 { break }
		current = next_term(current)
	}
	return i64(written)
}
