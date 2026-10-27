package reverse_search_permutation_enumeration

import "core:c"

MAX_N :: 4
MAX_INPUT :: 2
MAX_WORDS :: 97

visit :: proc(permutation: [^]i64, n: int, staged: [^]i64, cursor: ^int) {
	for index := 0; index < n; index += 1 { staged[cursor^] = permutation[index]; cursor^ += 1 }
	reverse_point := n
	for index := 0; index + 1 < n; index += 1 {
		if permutation[index] > permutation[index + 1] { reverse_point = index + 1; break }
	}
	for child := 1; child < reverse_point; child += 1 {
		temporary := permutation[child - 1]
		permutation[child - 1] = permutation[child]
		permutation[child] = temporary
		visit(permutation, n, staged, cursor)
		permutation[child] = permutation[child - 1]
		permutation[child - 1] = temporary
	}
	if reverse_point + 2 <= n && permutation[reverse_point - 1] < permutation[reverse_point + 1] {
		left := reverse_point
		temporary := permutation[left]
		permutation[left] = permutation[left + 1]
		permutation[left + 1] = temporary
		visit(permutation, n, staged, cursor)
		permutation[left + 1] = permutation[left]
		permutation[left] = temporary
	}
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
reverse_search_permutation_enumeration :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT do return -1
	if length != 1 || input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	count := 1
	for factor := 2; factor <= n; factor += 1 { count *= factor }
	words := 1 + n * count
	required := c.size_t(words * 8)
	if output == nil || capacity < required do return -2

	permutation: [MAX_N]i64
	staged: [MAX_WORDS]i64
	for index := 0; index < n; index += 1 { permutation[index] = i64(index + 1) }
	staged[0] = i64(count)
	cursor := 1
	visit(&permutation[0], n, &staged[0], &cursor)
	for word := 0; word < words; word += 1 { store_i64_le(output, word * 8, staged[word]) }
	return i64(required)
}
