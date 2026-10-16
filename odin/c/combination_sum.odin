package combination_sum

import "core:c"

MAX_CANDIDATES :: 8
MAX_TARGET :: 20
MAX_PACKED_WORDS :: 4096

Search :: struct {
	candidates: [^]i64,
	count: int,
	path: [MAX_TARGET]i64,
	packed: [MAX_PACKED_WORDS]i64,
	used: int,
}

enumerate :: proc "contextless" (search: ^Search, start: int, remaining: i64, depth: int) {
	if remaining == 0 {
		search.packed[search.used] = i64(depth)
		search.used += 1
		for i := 0; i < depth; i += 1 {
			search.packed[search.used] = search.path[i]
			search.used += 1
		}
		search.packed[0] += 1
		return
	}
	for i := start; i < search.count; i += 1 {
		candidate := search.candidates[i]
		if candidate > remaining do break
		search.path[depth] = candidate
		enumerate(search, i, remaining - candidate, depth + 1)
	}
}

put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
combination_sum :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 do return -1
	count_value, target := input[0], input[1]
	if count_value < 1 || count_value > MAX_CANDIDATES || target < 0 || target > MAX_TARGET do return -1
	count := int(count_value)
	if length != c.size_t(count + 2) do return -1
	for i := 0; i < count; i += 1 {
		candidate := input[i + 2]
		if candidate < 1 || candidate > 24 || (i > 0 && input[i + 1] >= candidate) do return -1
	}

	search := Search{candidates = &input[2], count = count, used = 1}
	enumerate(&search, 0, target, 0)
	required := search.used * 8
	if output == nil || capacity < c.size_t(required) do return -2
	for i := 0; i < search.used; i += 1 { put_i64(output, i * 8, search.packed[i]) }
	return i64(required)
}
