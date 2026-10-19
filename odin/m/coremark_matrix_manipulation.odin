package coremark_matrix_manipulation

import "core:c"

crc_byte :: proc "contextless" (value0: u8, crc0: u16) -> u16 {
	value, crc := value0, crc0
	for bit := 0; bit < 8; bit += 1 {
		mix := (value & 1) ^ u8(crc & 1)
		value >>= 1
		if mix != 0 do crc ^= 0x4002
		crc >>= 1
		if mix != 0 do crc |= 0x8000 else crc &= 0x7fff
	}
	return crc
}
crc16 :: proc "contextless" (value: i16, crc: u16) -> u16 {
	bits := u16(value)
	return crc_byte(u8(bits >> 8), crc_byte(u8(bits), crc))
}
matrix_sum :: proc "contextless" (c: [9]i32, clip: i16) -> i16 {
	tmp, prev: i32 = 0, 0
	ret: i16 = 0
	for cur in c {
		tmp += cur
		if tmp > i32(clip) { ret += 10; tmp = 0 } else if cur > prev { ret += 1 }
		prev = cur
	}
	return ret
}
put_i64 :: proc "contextless" (out: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { out[offset+b] = u8(bits >> u64(8*b)) }
}

coremark_matrix_manipulation :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 19 do return -1
	raw := input[0]
	if raw < 0 || raw > 15 do return -1
	a, b: [9]i16
	for i := 0; i < 9; i += 1 {
		if input[1+i] < 0 || input[1+i] > 127 || input[10+i] < 0 || input[10+i] > 127 do return -1
		a[i] = i16(input[1+i]); b[i] = i16(input[10+i])
	}
	if output == nil || capacity < 112 do return -2
	value := i16(raw)
	clip := value - 4096
	var cmat: [9]i32
	var sums: [4]i16
	for i := 0; i < 9; i += 1 { a[i] += value; cmat[i] = i32(a[i]) * i32(value) }
	sums[0] = matrix_sum(cmat, clip)
	for i := 0; i < 3; i += 1 { cmat[i] = 0; for j := 0; j < 3; j += 1 { cmat[i] += i32(a[i*3+j]) * i32(b[j]) } }
	sums[1] = matrix_sum(cmat, clip)
	for i := 0; i < 3; i += 1 { for j := 0; j < 3; j += 1 { cmat[i*3+j] = 0; for k := 0; k < 3; k += 1 { cmat[i*3+j] += i32(a[i*3+k]) * i32(b[k*3+j]) } } }
	sums[2] = matrix_sum(cmat, clip)
	for i := 0; i < 3; i += 1 { for j := 0; j < 3; j += 1 { cmat[i*3+j] = 0; for k := 0; k < 3; k += 1 { product := i32(a[i*3+k]) * i32(b[k*3+j]); cmat[i*3+j] += ((product >> 2) & 0xf) * ((product >> 5) & 0x7f) } } }
	sums[3] = matrix_sum(cmat, clip)
	crc: u16 = 0
	for sum in sums { crc = crc16(sum, crc) }
	for i := 0; i < 9; i += 1 { a[i] -= value }
	result: [14]i64
	result[0] = i64(crc)
	for i := 0; i < 4; i += 1 { result[i+1] = i64(sums[i]) }
	for i := 0; i < 9; i += 1 { result[i+5] = i64(a[i]) }
	for i := 0; i < 14; i += 1 { put_i64(output, i*8, result[i]) }
	return 112
}
