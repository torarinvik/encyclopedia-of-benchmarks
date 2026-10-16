package trifid_cipher

import "core:c"

@(export)
trifid_cipher :: proc(input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 31 do return -1
	mode := input[0]
	period_value := input[1]
	n_value := input[2]
	if (mode != 0 && mode != 1) || period_value < 1 || period_value > 256 || n_value < 0 || n_value > 256 || input[3] != 27 || length != c.size_t(31 + n_value) do return -1
	alphabet: [27]u8
	text: [256]u8
	transformed: [256]u8
	alen: int = 0
	tlen: int = 0
	for i in 0..<27 {
		raw := input[4 + int(n_value) + i]
		if raw < 0 || raw > 127 do return -1
		c8 := u8(raw)
		mut_char := c8
		if mut_char >= 97 && mut_char <= 122 do mut_char -= 32
		if mut_char == 32 do continue
		for j in 0..<alen { if alphabet[j] == mut_char do return -1 }
		alphabet[alen] = mut_char
		alen += 1
	}
	if alen != 27 do return -1
	for i in 0..<int(n_value) {
		raw := input[4 + i]
		if raw < 0 || raw > 127 do return -1
		mut_char := u8(raw)
		if mut_char >= 97 && mut_char <= 122 do mut_char -= 32
		if mut_char == 32 do continue
		found := false
		for a in alphabet { if a == mut_char do found = true }
		if !found do return -1
		text[tlen] = mut_char
		tlen += 1
	}
	start := 0
	period := int(period_value)
	for start < tlen {
		k := min(period, tlen - start)
		digits: [768]u8
		if mode == 0 {
			m := 0
			for axis in 0..<3 { for i in 0..<k {
				idx := 0
				for alphabet[idx] != text[start+i] { idx += 1 }
				divisor := 1
				if axis == 0 { divisor = 9 } else if axis == 1 { divisor = 3 }
				digits[m] = u8((idx / divisor) % 3)
				m += 1
			} }
			for i := 0; i < m; i += 3 { idx := int(digits[i])*9 + int(digits[i+1])*3 + int(digits[i+2]); transformed[start+i/3] = alphabet[idx] }
		} else {
			for i in 0..<k {
				idx := 0
				for alphabet[idx] != text[start+i] { idx += 1 }
				digits[3*i] = u8((idx/9)%3)
				digits[3*i+1] = u8((idx/3)%3)
				digits[3*i+2] = u8(idx%3)
			}
			for i in 0..<k { idx := int(digits[i])*9 + int(digits[k+i])*3 + int(digits[2*k+i]); transformed[start+i] = alphabet[idx] }
		}
		start += k
	}
	if output_capacity < c.size_t(tlen) do return -2
	if tlen > 0 && output == nil do return -1
	for i in 0..<tlen { output[i] = transformed[i] }
	return i64(tlen)
}
