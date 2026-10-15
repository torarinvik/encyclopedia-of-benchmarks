@[export: 'recamans_sequence']
pub fn recamans_sequence(index i64) i64 {
	if index < 0 || index > 32 { return -1 }
	mut seen := [529]bool{}
	seen[0] = true
	mut previous := i64(0)
	for step := i64(1); step <= index; step++ {
		mut candidate := previous - step
		if candidate < 0 || seen[int(candidate)] { candidate = previous + step }
		seen[int(candidate)] = true
		previous = candidate
	}
	return previous
}
