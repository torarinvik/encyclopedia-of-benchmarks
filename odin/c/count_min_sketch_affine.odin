package count_min_sketch_affine

import "core:c"

PRIME :: i64(2147483647)

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for b := 0; b < 8; b += 1 { output[offset+b] = u8(bits >> u64(8*b)) }
}

@(export)
count_min_sketch_affine :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 59 do return -1
	d64, w64, ops64 := input[0], input[1], input[2]
	if d64 < 1 || d64 > 4 || w64 < 1 || w64 > 8 || ops64 < 0 || ops64 > 16 do return -1
	d, w, ops := int(d64), int(w64), int(ops64)
	start := 3 + 2*d
	if length != c.size_t(start + 3*ops) do return -1
	var a: [4]i64
	var b: [4]i64
	for r := 0; r < d; r += 1 {
		a[r], b[r] = input[3+2*r], input[4+2*r]
		if a[r] < 1 || a[r] >= PRIME || b[r] < 0 || b[r] >= PRIME do return -1
	}
	queries := 0
	for op := 0; op < ops; op += 1 {
		kind, key, weight := input[start+3*op], input[start+3*op+1], input[start+3*op+2]
		if key < 0 || key > 1_000_000 do return -1
		if kind == 0 { if weight < 1 || weight > 1_000_000 do return -1 }
		else if kind == 1 { if weight != 0 do return -1; queries += 1 }
		else do return -1
	}
	var table: [4][8]i64
	var staged: [16]i64
	count := 0
	for op := 0; op < ops; op += 1 {
		kind, key, weight := input[start+3*op], input[start+3*op+1], input[start+3*op+2]
		var slots: [4]int
		for r := 0; r < d; r += 1 { slots[r] = int(((a[r]*key+b[r]) % PRIME) % i64(w)) }
		if kind == 0 { for r := 0; r < d; r += 1 { table[r][slots[r]] += weight } }
		else {
			minimum := table[0][slots[0]]
			for r := 1; r < d; r += 1 { if table[r][slots[r]] < minimum do minimum = table[r][slots[r]] }
			staged[count] = minimum; count += 1
		}
	}
	required := queries*8
	if capacity < c.size_t(required) || (required > 0 && output == nil) do return -2
	for i := 0; i < count; i += 1 { put_i64_le(output, 8*i, staged[i]) }
	return i64(required)
}
