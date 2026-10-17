module main

@[export: 'simplest_radical_form']
pub fn simplest_radical_form(values &i64, length usize, output &u8, capacity usize) i64 {
	if isnil(values) || length != 1 { return -1 }
	original := unsafe { values[0] }
	if original < 0 || original > 100000000 { return -1 }
	if isnil(output) || capacity < 16 { return -2 }

	mut coefficient := i64(1)
	mut root_term := i64(1)
	if original == 0 {
		root_term = 0
	} else {
		mut remainder := original
		mut factor := i64(2)
		for factor * factor <= original {
			mut count := i64(0)
			for remainder % factor == 0 {
				remainder /= factor
				count++
			}
			for power := i64(0); power < count / 2; power++ { coefficient *= factor }
			if count % 2 != 0 { root_term *= factor }
			factor++
		}
		root_term *= remainder
	}
	put_i64(mut output, 0, coefficient)
	put_i64(mut output, 8, root_term)
	return 16
}

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits >> (byte * 8)) } }
}
