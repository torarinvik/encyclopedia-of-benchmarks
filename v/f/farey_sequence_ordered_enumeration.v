module farey_sequence_ordered_enumeration

fn farey_count(order i64) i64 {
	mut a := i64(0)
	mut b := i64(1)
	mut c := i64(1)
	mut d := order
	mut count := i64(1)
	for {
		count++
		if c == d { break }
		k := (order + b) / d
		next_c := k * c - a
		next_d := k * d - b
		a = c
		b = d
		c = next_c
		d = next_d
	}
	return count
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'farey_sequence_ordered_enumeration']
pub fn farey_sequence_ordered_enumeration(values &i64, length usize, mut output &u8,
	output_capacity usize) i64 {
	if length != 1 || unsafe { values == nil } { return -1 }
	unsafe {
		order := values[0]
		if order < 1 || order > 32 { return -1 }
		count := farey_count(order)
		required := usize((1 + 2 * count) * 8)
		if output == nil || output_capacity < required { return -2 }
		store_i64_le(output, 0, count)
		store_i64_le(output, 8, 0)
		store_i64_le(output, 16, 1)
		mut a := i64(0)
		mut b := i64(1)
		mut c := i64(1)
		mut d := order
		mut position := 24
		for {
			store_i64_le(output, position, c)
			store_i64_le(output, position + 8, d)
			position += 16
			if c == d { break }
			k := (order + b) / d
			next_c := k * c - a
			next_d := k * d - b
			a = c
			b = d
			c = next_c
			d = next_d
		}
		return i64(required)
	}
}
