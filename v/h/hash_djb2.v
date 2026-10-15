module hash_djb2

const max_bytes = 3

@[export: 'hash_djb2']
pub fn hash_djb2(input &i64, length usize) i64 {
	if length < 1 || length > max_bytes + 1 { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 0 || count_value > max_bytes || length != usize(count_value) + 1 { return -1 }
	mut hash := u64(5381)
	for index in 0 .. int(count_value) {
		byte := unsafe { input[index + 1] }
		if byte < 1 || byte > 127 { return -1 }
		hash = hash * u64(33) + u64(byte)
	}
	return i64(hash)
}
