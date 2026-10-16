module select_bits

@[export: 'select_bits']
pub fn select_bits(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 1 || length > 3 {
		return -1
	}

	unsafe {
		number := values[0]
		if number < 0 || number > 9007199254740991 {
			return -1
		}

		first := if length >= 2 { values[1] } else { i64(1) }
		last := if length >= 3 { values[2] } else { i64(53) }
		if first < 1 || first > 53 || last < 1 || last > 53 {
			return -1
		}

		modulus := i64(1) << u32(last)
		return (number % modulus) >> u32(first - 1)
	}
}
