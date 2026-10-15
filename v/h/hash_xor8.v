module hash_xor8

@[export: 'hash_xor8']
pub fn hash_xor8(values &i64, length usize) i64 {
	if length > 100001 { return -1 }
	for i := 0; i < int(length); i++ {
		if values[i] == 0 { break }
		if values[i] < 0 || values[i] > 127 { return -1 }
	}
	mut hash := u32(0)
	for i := 0; i < int(length) && values[i] != 0; i++ {
		hash = (hash + u32(values[i])) & 0xff
	}
	return i64(((hash ^ 0xff) + 1) & 0xff)
}
