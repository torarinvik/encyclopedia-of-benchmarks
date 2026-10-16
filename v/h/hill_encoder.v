module main

@[export: 'hill_encoder']
pub fn hill_encoder(v &i64, n usize, out &u8, cap usize) i64 {
	if n < 10 || n > 74 { return -1 }
	if v[0] < 0 || v[0] > 64 || n != usize(10 + v[0]) { return -1 }
	length := int(v[0])
	padded := (length + 2) / 3 * 3
	mut text := []i64{len: 66}
	mut key := []i64{len: 9}
	mut result := []i64{len: 66}
	for i in 0 .. length {
		if v[1 + i] < 65 || v[1 + i] > 90 { return -1 }
		text[i] = v[1 + i]
	}
	for i in length .. padded { text[i] = 32 }
	for i in 0 .. 9 {
		key[i] = v[1 + length + i]
		if key[i] < -2 || key[i] > 2 { return -1 }
	}
	for off in 0 .. padded / 3 {
		for row in 0 .. 3 {
			mut sum := i64(0)
			for col in 0 .. 3 { sum += key[row * 3 + col] * text[off * 3 + col] }
			if sum < 0 || sum > 65535 { return -1 }
			result[off * 3 + row] = sum
		}
	}
	bytes := padded * 8
	if cap < bytes { return -2 }
	for i in 0 .. padded {
		bits := u64(result[i])
		for k in 0 .. 8 { unsafe { out[i * 8 + k] = u8(bits >> (8 * k)) } }
	}
	return i64(bytes)
}
