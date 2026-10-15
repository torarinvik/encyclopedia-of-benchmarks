module number_of_paths

// Count vertex-simple directed paths with recursive DFS.
fn count_from(values &i64, n int, current int, destination int, visited u32) u32 {
	if current == destination { return 1 }
	seen := visited | (u32(1) << u32(current))
	mut count := u32(0)
	for next in 0 .. n {
		if values[3 + current * n + next] == 1 && (seen & (u32(1) << u32(next))) == 0 {
			count += count_from(values, n, next, destination, seen)
		}
	}
	return count
}

@[export: 'number_of_paths']
pub fn number_of_paths(values &i64, length usize) i64 {
	if length < 3 || values[0] < 1 || values[0] > 10 { return -1 }
	n := int(values[0])
	if length != usize(3 + n * n) { return -1 }
	if values[1] < 0 || values[1] > 4294967295 || values[2] < 0 || values[2] > 4294967295 { return -1 }
	for i := 3; i < int(length); i++ {
		if values[i] != 0 && values[i] != 1 { return -1 }
	}
	source := int(values[1])
	destination := int(values[2])
	if source >= n || destination >= n { return 0 }
	return i64(count_from(values, n, source, destination, 0))
}
