package observed_remove_set

import "core:c"

MAX_Q :: 32
MAX_TAGS :: 64
MAX_INPUT :: 129

@(export)
observed_remove_set :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT do return -1
	qv := input[0]
	if qv < 0 || qv > MAX_Q || length != c.size_t(1 + qv * 4) do return -1
	q := int(qv)
	for i in 0..<q {
		op, replica, element, peer := input[1 + 4 * i], input[2 + 4 * i], input[3 + 4 * i], input[4 + 4 * i]
		if op >= 0 && op <= 2 {
			if replica < 0 || replica > 1 || element < 0 || element > 15 || peer != 0 do return -1
		} else if op == 3 || op == 4 {
			if replica < 0 || replica > 1 || element != 0 || peer < 0 || peer > 1 do return -1
		} else do return -1
	}

	used: [MAX_TAGS]bool
	tag_element: [MAX_TAGS]i64
	next_sequence: [2]int
	additions: [2 * MAX_TAGS]bool
	removals: [2 * MAX_TAGS]bool
	answer := u64(0)
	read_count := 0
	for i in 0..<q {
		op, replica_value, element, peer_value := input[1 + 4 * i], input[2 + 4 * i], input[3 + 4 * i], input[4 + 4 * i]
		replica, peer := int(replica_value), int(peer_value)
		base, peer_base := replica * MAX_TAGS, peer * MAX_TAGS
		result := false
		if op == 0 {
			tag := replica * MAX_Q + next_sequence[replica]
			next_sequence[replica] += 1
			used[tag] = true
			tag_element[tag] = element
			additions[base + tag] = true
		} else if op == 1 {
			for tag in 0..<MAX_TAGS {
				if additions[base + tag] && !removals[base + tag] && used[tag] && tag_element[tag] == element do removals[base + tag] = true
			}
		} else if op == 2 {
			for tag in 0..<MAX_TAGS {
				if additions[base + tag] && !removals[base + tag] && used[tag] && tag_element[tag] == element do result = true
			}
		} else if op == 3 {
			for tag in 0..<MAX_TAGS {
				additions[base + tag] = additions[base + tag] || additions[peer_base + tag]
				removals[base + tag] = removals[base + tag] || removals[peer_base + tag]
			}
		} else {
			result = true
			for tag in 0..<MAX_TAGS {
				if (additions[base + tag] && !additions[peer_base + tag]) || (removals[base + tag] && !removals[peer_base + tag]) do result = false
			}
		}
		if op == 2 || op == 4 {
			if result do answer |= u64(1) << u64(read_count)
			read_count += 1
		}
	}
	return i64(answer)
}
