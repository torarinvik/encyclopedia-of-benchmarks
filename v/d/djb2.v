module djb2

const max_bytes = usize(64)
const max_parsed_bytes = usize(65)
const uint32_modulus = u64(4_294_967_296)

@[export: 'djb2']
pub fn djb2(input &i64, length usize) i64 {
	if length > max_parsed_bytes || (length > 0 && unsafe { input == nil }) { return -1 }
	if length > max_bytes { return -1 }
	mut hash := u64(5381)
	unsafe {
		for index in 0 .. int(length) {
			code_point := input[index]
			if code_point < 0 || code_point > 255 { return -1 }
			hash = (hash * 33 + u64(code_point)) % uint32_modulus
		}
	}
	return i64(hash)
}
