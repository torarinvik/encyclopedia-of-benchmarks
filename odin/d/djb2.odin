package djb2

import "core:c"

MAX_BYTES :: 64
MAX_PARSED_BYTES :: 65
UINT32_MODULUS :: u64(4_294_967_296)

@(export)
djb2 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_PARSED_BYTES || (length > 0 && input == nil) do return -1
	if length > MAX_BYTES do return -1
	hash: u64 = 5381
	for index: c.size_t = 0; index < length; index += 1 {
		code_point := input[index]
		if code_point < 0 || code_point > 255 do return -1
		hash = (hash * 33 + u64(code_point)) % UINT32_MODULUS
	}
	return i64(hash)
}
