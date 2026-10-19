module coremark_matrix_manipulation

fn crc_byte(value0 u8, crc0 u16) u16 {
	mut value := value0
	mut crc := crc0
	for _ in 0..8 {
		mix := (value & 1) ^ u8(crc & 1)
		value >>= 1
		if mix != 0 { crc ^= 0x4002 }
		crc >>= 1
		if mix != 0 { crc |= 0x8000 } else { crc &= 0x7fff }
	}
	return crc
}
fn crc16(value i16, crc u16) u16 {
	bits := u16(value)
	return crc_byte(u8(bits >> 8), crc_byte(u8(bits), crc))
}
fn matrix_sum(c [9]i32, clip i16) i16 {
	mut tmp := i32(0)
	mut prev := i32(0)
	mut ret := i16(0)
	for cur in c {
		tmp += cur
		if tmp > i32(clip) { ret += 10; tmp = 0 } else if cur > prev { ret++ }
		prev = cur
	}
	return ret
}
fn put_i64(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for b := 0; b < 8; b++ { unsafe { output[offset+b] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'coremark_matrix_manipulation']
pub fn coremark_matrix_manipulation(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length != 19 { return -1 }
	unsafe {
		raw := input[0]
		if raw < 0 || raw > 15 { return -1 }
		mut a := [9]i16{}
		mut b := [9]i16{}
		for i := 0; i < 9; i++ {
			if input[1+i] < 0 || input[1+i] > 127 || input[10+i] < 0 || input[10+i] > 127 { return -1 }
			a[i] = i16(input[1+i]); b[i] = i16(input[10+i])
		}
		if output == nil || capacity < 112 { return -2 }
		value := i16(raw)
		clip := value - 4096
		mut c := [9]i32{}
		mut sums := [4]i16{}
		for i := 0; i < 9; i++ { a[i] += value; c[i] = i32(a[i]) * i32(value) }
		sums[0] = matrix_sum(c, clip)
		for i := 0; i < 3; i++ { c[i] = 0; for j := 0; j < 3; j++ { c[i] += i32(a[i*3+j]) * i32(b[j]) } }
		sums[1] = matrix_sum(c, clip)
		for i := 0; i < 3; i++ { for j := 0; j < 3; j++ { c[i*3+j] = 0; for k := 0; k < 3; k++ { c[i*3+j] += i32(a[i*3+k]) * i32(b[k*3+j]) } } }
		sums[2] = matrix_sum(c, clip)
		for i := 0; i < 3; i++ { for j := 0; j < 3; j++ { c[i*3+j] = 0; for k := 0; k < 3; k++ { product := i32(a[i*3+k]) * i32(b[k*3+j]); c[i*3+j] += ((product >> 2) & 0xf) * ((product >> 5) & 0x7f) } } }
		sums[3] = matrix_sum(c, clip)
		mut crc := u16(0)
		for sum in sums { crc = crc16(sum, crc) }
		for i := 0; i < 9; i++ { a[i] -= value }
		mut result := [14]i64{}
		result[0] = i64(crc)
		for i := 0; i < 4; i++ { result[i+1] = i64(sums[i]) }
		for i := 0; i < 9; i++ { result[i+5] = i64(a[i]) }
		for i := 0; i < 14; i++ { put_i64(mut output, i*8, result[i]) }
		return 112
	}
}
