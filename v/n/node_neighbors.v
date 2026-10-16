module node_neighbors

@[export: 'node_neighbors']
pub fn node_neighbors(values &i64, length usize, output &u8, capacity usize) i64 {
	if length < 2 { return -1 }
	count := unsafe { values[0] }; node := unsafe { values[1] }
	if count < 0 || count > 64 || node < 0 || node > 63 || length != usize(2+2*count) { return -1 }
	mut seen := [64]bool{}; mut result := ''
	for i in 0 .. int(count) {
		a := unsafe { values[2+2*i] }; b := unsafe { values[3+2*i] }
		if a < 0 || a > 63 || b < 0 || b > 63 { return -1 }
		neighbor := if a == node { b } else if b == node { a } else { i64(-1) }
		if neighbor >= 0 && !seen[int(neighbor)] { seen[int(neighbor)] = true; if result.len > 0 { result += ',' }; result += neighbor.str() }
	}
	if usize(result.len) > capacity || (result.len > 0 && isnil(output)) { return -2 }
	for i in 0 .. result.len { unsafe { output[i] = result[i] } }
	return i64(result.len)
}
