package main

@(export, link_name="recamans_sequence")
recamans_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > 32 do return -1
	seen: [529]bool = {}
	seen[0] = true
	previous: i64 = 0
	for step: i64 = 1; step <= index; step += 1 {
		candidate := previous - step
		if candidate < 0 || seen[candidate] do candidate = previous + step
		seen[candidate] = true
		previous = candidate
	}
	return previous
}

main :: proc() {}
