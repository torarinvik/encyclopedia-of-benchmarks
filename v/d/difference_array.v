module difference_array

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'difference_array']
pub fn difference_array(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	unsafe {
		raw_n := input[0]
		raw_q := input[1]
		if raw_n < 1 || raw_n > 64 || raw_q < 0 || raw_q > 64 { return -1 }
		n := int(raw_n)
		q := int(raw_q)
		if length != usize(2+n+3*q) { return -1 }
		for i in 0 .. n { if input[2+i] < -1_000_000 || input[2+i] > 1_000_000 { return -1 } }
		for u in 0 .. q {
			base := 2+n+3*u
			if input[base] < 0 || input[base] >= raw_n || input[base+1] < input[base] || input[base+1] >= raw_n || input[base+2] < -1_000_000 || input[base+2] > 1_000_000 { return -1 }
		}
		bytes := n*8
		if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
		mut diff := [65]i64{}
		diff[0] = input[2]
		for i in 1 .. n { diff[i] = input[2+i] - input[2+i-1] }
		for u in 0 .. q {
			base := 2+n+3*u
			left := int(input[base])
			right := int(input[base+1])
			delta := input[base+2]
			diff[left] += delta
			diff[right+1] -= delta
		}
		mut current := diff[0]
		put_i64_le(mut output, 0, current)
		for i in 1 .. n { current += diff[i]; put_i64_le(mut output, i*8, current) }
		return i64(bytes)
	}
}
