module blake2b

const max_input = 4096
const block_bytes = 128
fn load_le64_string(data string, position int) u64 {
	mut value := u64(0)
	for i in 0 .. 8 { value |= u64(data[position + i]) << (8 * i) }
	return value
}
fn add64(a u64, b u64) u64 {
	low := (a & 0xffff_ffff) + (b & 0xffff_ffff)
	high := (a >> 32) + (b >> 32) + (low >> 32)
	return ((high & 0xffff_ffff) << 32) | (low & 0xffff_ffff)
}
fn rotr64(value u64, amount int) u64 { return (value >> amount) | (value << (64 - amount)) }
fn mix(mut v &u64, a int, b int, c int, d int, x u64, y u64) {
	v[a] = add64(add64(v[a], v[b]), x)
	v[d] = rotr64(v[d] ^ v[a], 32)
	v[c] = add64(v[c], v[d])
	v[b] = rotr64(v[b] ^ v[c], 24)
	v[a] = add64(add64(v[a], v[b]), y)
	v[d] = rotr64(v[d] ^ v[a], 16)
	v[c] = add64(v[c], v[d])
	v[b] = rotr64(v[b] ^ v[c], 63)
}
fn load_le64(block []u8, position int) u64 {
	mut value := u64(0)
	for i in 0 .. 8 { value |= u64(block[position + i]) << (8 * i) }
	return value
}
fn compress(mut h &u64, block []u8, counter u64, last bool) {
	iv_bytes := '\x08\xc9\xbc\xf3\x67\xe6\x09\x6a\x3b\xa7\xca\x84\x85\xae\x67\xbb\x2b\xf8\x94\xfe\x72\xf3\x6e\x3c\xf1\x36\x1d\x5f\x3a\xf5\x4f\xa5\xd1\x82\xe6\xad\x7f\x52\x0e\x51\x1f\x6c\x3e\x2b\x8c\x68\x05\x9b\x6b\xbd\x41\xfb\xab\xd9\x83\x1f\x79\x21\x7e\x13\x19\xcd\xe0\x5b'
	sigma := '\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x0e\x0a\x04\x08\x09\x0f\x0d\x06\x01\x0c\x00\x02\x0b\x07\x05\x03\x0b\x08\x0c\x00\x05\x02\x0f\x0d\x0a\x0e\x03\x06\x07\x01\x09\x04\x07\x09\x03\x01\x0d\x0c\x0b\x0e\x02\x06\x05\x0a\x04\x00\x0f\x08\x09\x00\x05\x07\x02\x04\x0a\x0f\x0e\x01\x0b\x0c\x06\x08\x03\x0d\x02\x0c\x06\x0a\x00\x0b\x08\x03\x04\x0d\x07\x05\x0f\x0e\x01\x09\x0c\x05\x01\x0f\x0e\x0d\x04\x0a\x00\x07\x06\x03\x09\x02\x08\x0b\x0d\x0b\x07\x0e\x0c\x01\x03\x09\x05\x00\x0f\x04\x08\x06\x02\x0a\x06\x0f\x0e\x09\x0b\x03\x00\x08\x0c\x02\x0d\x07\x01\x04\x0a\x05\x0a\x02\x08\x04\x07\x06\x01\x05\x0f\x0b\x09\x0e\x03\x0c\x0d\x00'
	mut m := [16]u64{init: 0}
	mut v := [16]u64{init: 0}
	for i in 0 .. 16 { m[i] = load_le64(block, i * 8) }
	for i in 0 .. 8 { v[i] = h[i]; v[i + 8] = load_le64_string(iv_bytes, i * 8) }
	v[12] ^= counter
	if last { v[14] = ~v[14] }
	for round in 0 .. 12 {
		offset := (round % 10) * 16
		mix(mut &v[0], 0,4,8,12, m[int(sigma[offset])],m[int(sigma[offset+1])])
		mix(mut &v[0], 1,5,9,13,m[int(sigma[offset+2])],m[int(sigma[offset+3])])
		mix(mut &v[0], 2,6,10,14,m[int(sigma[offset+4])],m[int(sigma[offset+5])])
		mix(mut &v[0], 3,7,11,15,m[int(sigma[offset+6])],m[int(sigma[offset+7])])
		mix(mut &v[0], 0,5,10,15,m[int(sigma[offset+8])],m[int(sigma[offset+9])])
		mix(mut &v[0], 1,6,11,12,m[int(sigma[offset+10])],m[int(sigma[offset+11])])
		mix(mut &v[0], 2,7,8,13,m[int(sigma[offset+12])],m[int(sigma[offset+13])])
		mix(mut &v[0], 3,4,9,14,m[int(sigma[offset+14])],m[int(sigma[offset+15])])
	}
	for i in 0 .. 8 { h[i] ^= v[i] ^ v[i + 8] }
}

@[export: 'blake2b']
pub fn blake2b(input voidptr, length usize, output voidptr, capacity usize) i64 {
	unsafe {
		if length > max_input || (length > 0 && input == nil) { return -1 }
		input_values := &i64(input)
		output_bytes := &u8(output)
		for i in 0 .. int(length) { if input_values[i] < 0 || input_values[i] > 255 { return -1 } }
		if output == nil || capacity < 64 { return -2 }
		mut h := [8]u64{init: 0}
		iv_bytes := '\x08\xc9\xbc\xf3\x67\xe6\x09\x6a\x3b\xa7\xca\x84\x85\xae\x67\xbb\x2b\xf8\x94\xfe\x72\xf3\x6e\x3c\xf1\x36\x1d\x5f\x3a\xf5\x4f\xa5\xd1\x82\xe6\xad\x7f\x52\x0e\x51\x1f\x6c\x3e\x2b\x8c\x68\x05\x9b\x6b\xbd\x41\xfb\xab\xd9\x83\x1f\x79\x21\x7e\x13\x19\xcd\xe0\x5b'
		for i in 0 .. 8 { h[i] = load_le64_string(iv_bytes, i * 8) }
		h[0] ^= u64(0x01010040)
		mut block := [block_bytes]u8{init: 0}
		mut consumed := 0
		mut counter := u64(0)
		for int(length) - consumed > block_bytes {
			for i in 0 .. block_bytes { block[i] = u8(input_values[consumed + i]) }
			counter += u64(block_bytes)
			compress(mut &h[0], block[..], counter, false)
			consumed += block_bytes
			for i in 0 .. block_bytes { block[i] = 0 }
		}
		remaining := int(length) - consumed
		for i in 0 .. remaining { block[i] = u8(input_values[consumed + i]) }
		counter += u64(remaining)
		compress(mut &h[0], block[..], counter, true)
		for word in 0 .. 8 { for byte in 0 .. 8 { output_bytes[word * 8 + byte] = u8((h[word] >> (8 * byte)) & 255) } }
		return 64
	}
}
