module simple_substitution_cipher

@[export: 'simple_substitution_cipher']
pub fn simple_substitution_cipher(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 28 || length > 284 { return -1 }
	mode := unsafe { input[0] }
	n64 := unsafe { input[27] }
	if (mode != 0 && mode != 1) || n64 < 0 || n64 > 256 || length != usize(28 + n64) { return -1 }
	mut seen := [26]bool{}
	for i := 0; i < 26; i++ {
		value := unsafe { input[1 + i] }
		if value < 65 || value > 90 || seen[int(value - 65)] { return -1 }
		seen[int(value - 65)] = true
	}
	n := int(n64)
	for i := 0; i < n; i++ {
		value := unsafe { input[28 + i] }
		if value < 0 || value > 127 { return -1 }
	}
	if unsafe { output == nil } || output_capacity < usize(n) { return -2 }
	unsafe {
		for i := 0; i < n; i++ {
			ch := input[28 + i]
			lower, upper := ch >= 97 && ch <= 122, ch >= 65 && ch <= 90
			if !lower && !upper { output[i] = u8(ch); continue }
			base := if lower { i64(97) } else { i64(65) }
			index := int(ch - base)
			mut mapped := index
			if mode == 0 { mapped = int(input[1 + index] - 65) } else {
				mapped = 0
				for mapped < 26 && input[1 + mapped] != i64(65 + index) { mapped++ }
			}
			output[i] = u8(base + i64(mapped))
		}
	}
	return i64(n)
}
