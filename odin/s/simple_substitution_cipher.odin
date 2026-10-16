package simple_substitution_cipher

import "core:c"

@(export)
simple_substitution_cipher :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 28 || length > 284 do return -1
	mode, n64 := input[0], input[27]
	if (mode != 0 && mode != 1) || n64 < 0 || n64 > 256 || int(length) != 28 + int(n64) do return -1
	var seen: [26]bool
	for i := 0; i < 26; i += 1 {
		value := input[1+i]
		if value < 65 || value > 90 || seen[value-65] do return -1
		seen[value-65] = true
	}
	n := int(n64)
	for i := 0; i < n; i += 1 { if input[28+i] < 0 || input[28+i] > 127 do return -1 }
	if output == nil || output_capacity < c.size_t(n) do return -2
	for i := 0; i < n; i += 1 {
		ch := input[28+i]
		lower, upper := ch >= 97 && ch <= 122, ch >= 65 && ch <= 90
		if !lower && !upper { output[i] = u8(ch); continue }
		base := if lower do i64(97) else do i64(65)
		index := int(ch - base)
		mapped := index
		if mode == 0 { mapped = int(input[1+index] - 65) } else {
			mapped = 0
			for mapped < 26 && input[1+mapped] != 65 + i64(index) { mapped += 1 }
		}
		output[i] = u8(base + i64(mapped))
	}
	return i64(n)
}
