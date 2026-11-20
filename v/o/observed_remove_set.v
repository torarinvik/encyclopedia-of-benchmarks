module observed_remove_set

const max_q = 32
const max_tags = 64
const max_input = 129

@[export: 'observed_remove_set']
pub fn observed_remove_set(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input { return -1 }
	qv := unsafe { input[0] }
	if qv < 0 || qv > max_q || length != usize(1 + qv * 4) { return -1 }
	q := int(qv)
	for i in 0 .. q {
		op := unsafe { input[1 + 4 * i] }
		replica := unsafe { input[2 + 4 * i] }
		element := unsafe { input[3 + 4 * i] }
		peer := unsafe { input[4 + 4 * i] }
		if op >= 0 && op <= 2 {
			if replica < 0 || replica > 1 || element < 0 || element > 15 || peer != 0 { return -1 }
		} else if op == 3 || op == 4 {
			if replica < 0 || replica > 1 || element != 0 || peer < 0 || peer > 1 { return -1 }
		} else { return -1 }
	}

	mut used := []bool{len: max_tags}
	mut tag_element := []i64{len: max_tags}
	mut next_sequence := []int{len: 2}
	mut additions := []bool{len: 2 * max_tags}
	mut removals := []bool{len: 2 * max_tags}
	mut answer := u64(0)
	mut read_count := 0
	for i in 0 .. q {
		op := unsafe { input[1 + 4 * i] }
		replica := int(unsafe { input[2 + 4 * i] })
		element := unsafe { input[3 + 4 * i] }
		peer := int(unsafe { input[4 + 4 * i] })
		base := replica * max_tags
		peer_base := peer * max_tags
		mut result := false
		if op == 0 {
			tag := replica * max_q + next_sequence[replica]
			next_sequence[replica]++
			used[tag] = true
			tag_element[tag] = element
			additions[base + tag] = true
		} else if op == 1 {
			for tag in 0 .. max_tags {
				if additions[base + tag] && !removals[base + tag] && used[tag] && tag_element[tag] == element { removals[base + tag] = true }
			}
		} else if op == 2 {
			for tag in 0 .. max_tags {
				if additions[base + tag] && !removals[base + tag] && used[tag] && tag_element[tag] == element { result = true }
			}
		} else if op == 3 {
			for tag in 0 .. max_tags {
				additions[base + tag] = additions[base + tag] || additions[peer_base + tag]
				removals[base + tag] = removals[base + tag] || removals[peer_base + tag]
			}
		} else {
			result = true
			for tag in 0 .. max_tags {
				if (additions[base + tag] && !additions[peer_base + tag]) || (removals[base + tag] && !removals[peer_base + tag]) { result = false }
			}
		}
		if op == 2 || op == 4 {
			if result { answer |= u64(1) << u64(read_count) }
			read_count++
		}
	}
	return i64(answer)
}
