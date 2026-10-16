module nearest_neighbour_algorithm

@[export: 'nearest_neighbour_algorithm']
pub fn nearest_neighbour_algorithm(values &i64, length usize, output &u8, capacity usize) i64 {
	if length < 2 || length > 257 { return -1 }
	count := unsafe { values[0] }
	if count < 1 || count > 16 || length != usize(1 + count * count) { return -1 }
	for i in 1 .. int(length) { x := unsafe { values[i] }; if x < 0 || x > 1000000 { return -1 } }
	mut seen := [16]bool{}
	mut path := []int{}
	mut current := 0
	for step in 0 .. int(count) {
		path << current
		seen[current] = true
		if step + 1 < int(count) {
			mut best := int(count)
			mut distance := i64(0)
			for j in 0 .. int(count) {
				if !seen[j] { d := unsafe { values[1 + current * int(count) + j] }; if best == int(count) || d < distance { best = j; distance = d } }
			}
			current = best
		}
	}
	mut result := ''
	for i, node in path { if i > 0 { result += ',' }; result += node.str() }
	if usize(result.len) > capacity || (result.len > 0 && isnil(output)) { return -2 }
	for i in 0 .. result.len { unsafe { output[i] = result[i] } }
	return i64(result.len)
}
