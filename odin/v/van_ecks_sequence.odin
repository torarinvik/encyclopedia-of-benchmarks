package main

@(export, link_name="van_ecks_sequence")
van_ecks_sequence :: proc(position: i64) -> i64 {
	if position < 1 || position > 16 do return -1
	last_seen: [17]i64 = {}
	previous: i64 = 0
	for current: i64 = 2; current <= position; current += 1 {
		next: i64 = 0
		if last_seen[previous] != 0 do next = current - last_seen[previous]
		last_seen[previous] = current
		previous = next
	}
	return previous
}

main :: proc() {}
