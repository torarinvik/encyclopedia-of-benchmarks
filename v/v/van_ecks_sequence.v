@[export: 'van_ecks_sequence']
pub fn van_ecks_sequence(position i64) i64 {
	if position < 1 || position > 16 { return -1 }
	mut last_seen := [17]i64{}
	mut previous := i64(0)
	for current := i64(2); current <= position; current++ {
		mut next := i64(0)
		if last_seen[int(previous)] != 0 { next = current - last_seen[int(previous)] }
		last_seen[int(previous)] = current
		previous = next
	}
	return previous
}
