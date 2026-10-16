module trifid_cipher

@[export: 'trifid_cipher']
pub fn trifid_cipher(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 31 { return -1 }
	mode := unsafe { input[0] }
	period_value := unsafe { input[1] }
	n_value := unsafe { input[2] }
	if (mode != 0 && mode != 1) || period_value < 1 || period_value > 256 || n_value < 0 || n_value > 256 || unsafe { input[3] != 27 } || length != usize(31 + n_value) { return -1 }
	mut alphabet := [27]u8{}
	mut text := [256]u8{}
	mut transformed := [256]u8{}
	mut al := 0
	mut tl := 0
	for i in 0 .. 27 {
		raw := unsafe { input[4 + int(n_value) + i] }
		if raw < 0 || raw > 127 { return -1 }
		mut c := u8(raw)
		if c >= 97 && c <= 122 { c -= 32 }
		if c == 32 { continue }
		for j in 0 .. al { if alphabet[j] == c { return -1 } }
		alphabet[al] = c
		al++
	}
	if al != 27 { return -1 }
	for i in 0 .. int(n_value) {
		raw := unsafe { input[4 + i] }
		if raw < 0 || raw > 127 { return -1 }
		mut c := u8(raw)
		if c >= 97 && c <= 122 { c -= 32 }
		if c == 32 { continue }
		mut found := false
		for a in alphabet { if a == c { found = true } }
		if !found { return -1 }
		text[tl] = c
		tl++
	}
	period := int(period_value)
	mut start := 0
	for start < tl {
		k := if period < tl - start { period } else { tl - start }
		mut digits := [768]u8{}
		if mode == 0 {
			mut m := 0
			for axis in 0 .. 3 { for i in 0 .. k {
				mut idx := 0
				for alphabet[idx] != text[start+i] { idx++ }
				divisor := if axis == 0 { 9 } else if axis == 1 { 3 } else { 1 }
				digits[m] = u8((idx / divisor) % 3)
				m++
			} }
			mut i := 0
			for i < m { idx := int(digits[i])*9 + int(digits[i+1])*3 + int(digits[i+2]); transformed[start+i/3] = alphabet[idx]; i += 3 }
		} else {
			for i in 0 .. k {
				mut idx := 0
				for alphabet[idx] != text[start+i] { idx++ }
				digits[3 * i] = u8((idx / 9) % 3)
				digits[3 * i + 1] = u8((idx / 3) % 3)
				digits[3 * i + 2] = u8(idx % 3)
			}
			for i in 0 .. k { idx := int(digits[i])*9 + int(digits[k+i])*3 + int(digits[2*k+i]); transformed[start+i] = alphabet[idx] }
		}
		start += k
	}
	if output_capacity < usize(tl) { return -2 }
	if tl > 0 && unsafe { output == nil } { return -1 }
	for i in 0 .. tl { unsafe { output[i] = transformed[i] } }
	return i64(tl)
}
