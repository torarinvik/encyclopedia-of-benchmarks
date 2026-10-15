package hash_djb2

import "core:c"

MAX_BYTES :: 3

@(export)
hash_djb2 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_BYTES + 1 do return -1
	count_value := input[0]
	if count_value < 0 || count_value > MAX_BYTES || length != c.size_t(count_value) + 1 do return -1
	hash := u64(5381)
	for index := 0; index < int(count_value); index += 1 {
		byte := input[index + 1]
		if byte < 1 || byte > 127 do return -1
		hash = hash * 33 + u64(byte)
	}
	return i64(hash)
}
