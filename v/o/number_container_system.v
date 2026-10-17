module number_container_system

@[export: 'number_container_system']
pub fn number_container_system(values &i64, length usize, output &u8, capacity usize) i64 {
	if isnil(values) || length < 1 { return -1 }
	count := unsafe { values[0] }
	if count < 0 || count > 32 || length != usize(1+3*count) { return -1 }
	mut slots := [64]i64{}; mut present := [64]bool{}; mut result := ''
	for i in 0 .. int(count) {
		op := unsafe { values[1+3*i] }; a := unsafe { values[2+3*i] }; b := unsafe { values[3+3*i] }
		if op == 0 { if a < 0 || a > 63 || b < -100 || b > 100 { return -1 }; slots[int(a)] = b; present[int(a)] = true }
		else if op == 1 {
			if a < -100 || a > 100 || b != 0 { return -1 }
			mut found := i64(-1); for j in 0 .. 64 { if present[j] && slots[j] == a { found = i64(j); break } }
			if result.len > 0 { result += ',' }; result += found.str()
		} else { return -1 }
	}
	if isnil(output) || usize(result.len) > capacity { return -2 }
	for i in 0 .. result.len { unsafe { output[i] = result[i] } }
	return i64(result.len)
}
