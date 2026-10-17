package msd_radix_string_sorter

import "core:c"

MAX_STRINGS :: 256
MAX_LENGTH :: 32
MAX_INPUT :: 1 + MAX_STRINGS * (1 + MAX_LENGTH) + 1
FNV_OFFSET :: u64(14_695_981_039_346_656_037)
FNV_PRIME :: u64(1_099_511_628_211)
MASK_63 :: u64(0x7fff_ffff_ffff_ffff)

Encoded_String :: struct { bytes: [MAX_LENGTH]u8, length: int }

bucket :: proc "contextless" (value: ^Encoded_String, digit: int) -> int {
	if digit >= value.length do return 0
	return int(value.bytes[digit]) + 1
}

msd_sort :: proc "contextless" (values, auxiliary: ^[MAX_STRINGS]Encoded_String, low, high, digit: int) {
	if high - low < 2 || digit >= MAX_LENGTH do return
	counts: [257]int
	for i := low; i < high; i += 1 { counts[bucket(&values[i], digit)] += 1 }
	starts, next: [257]int
	position := low
	for b := 0; b < 257; b += 1 { starts[b] = position; next[b] = position; position += counts[b] }
	for i := low; i < high; i += 1 { b := bucket(&values[i], digit); auxiliary[next[b]] = values[i]; next[b] += 1 }
	for i := low; i < high; i += 1 { values[i] = auxiliary[i] }
	for b := 1; b < 257; b += 1 { first := starts[b]; last := first + counts[b]; if last-first > 1 do msd_sort(values, auxiliary, first, last, digit+1) }
}

@(export)
msd_radix_string_sorter :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length == 0 || length > c.size_t(MAX_INPUT) do return -1
	if input[0] < 0 || input[0] > MAX_STRINGS do return -1
	count := int(input[0])
	values, auxiliary: [MAX_STRINGS]Encoded_String
	position := 1
	for i := 0; i < count; i += 1 {
		if position >= int(length) || input[position] < 0 || input[position] > MAX_LENGTH do return -1
		n := int(input[position]); position += 1
		if n > int(length) - position do return -1
		values[i].length = n
		for digit := 0; digit < n; digit += 1 { if input[position] < 0 || input[position] > 255 do return -1; values[i].bytes[digit] = u8(input[position]); position += 1 }
	}
	if position != int(length) do return -1
	if count > 1 do msd_sort(&values, &auxiliary, 0, count, 0)
	hash := FNV_OFFSET
	hash = (hash ^ u64(count & 255)) * FNV_PRIME
	hash = (hash ^ u64((count >> 8) & 255)) * FNV_PRIME
	for i := 0; i < count; i += 1 { hash = (hash ^ u64(values[i].length)) * FNV_PRIME; for digit := 0; digit < values[i].length; digit += 1 { hash = (hash ^ u64(values[i].bytes[digit])) * FNV_PRIME } }
	return i64(hash & MASK_63)
}
