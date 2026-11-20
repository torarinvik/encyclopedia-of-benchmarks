fn segment_union_sift_down(mut events &i64, root_start int, end_value int) {
	mut root := root_start
	for root < end_value / 2 {
		mut child := root * 2 + 1
		if child + 1 < end_value && unsafe { events[child] < events[child + 1] } { child++ }
		if unsafe { events[root] >= events[child] } { break }
		unsafe {
			temporary := events[root]
			events[root] = events[child]
			events[child] = temporary
		}
		root = child
	}
}

fn segment_union_heap_sort(mut events &i64, count int) {
	mut start := count / 2
	for start > 0 { start--; segment_union_sift_down(mut events, start, count) }
	mut ending := count
	for ending > 1 {
		ending--
		unsafe {
			temporary := events[0]
			events[0] = events[ending]
			events[ending] = temporary
		}
		segment_union_sift_down(mut events, 0, ending)
	}
}

@[export: 'segment_union_length_klee']
pub fn segment_union_length_klee(input &i64, length usize) i64 {
	if length < 1 || length > 130 { return -1 }
	unsafe {
		if input == nil { return -1 }
		n_value := input[0]
		if n_value < 0 || n_value > 64 { return -1 }
		n := int(n_value)
		if length != usize(1 + 2*n) { return -1 }
		mut events := [128]i64{}
		for i in 0 .. n {
			left, right := input[1+2*i], input[2+2*i]
			if left < -1000 || left > right || right > 1000 { return -1 }
			events[2*i] = 2 * (left + 1000)
			events[2*i+1] = 2 * (right + 1000) + 1
		}
		event_count := 2*n
		if event_count == 0 { return 0 }
		segment_union_heap_sort(mut events[0], event_count)
		mut active := i64(0)
		mut total := i64(0)
		mut previous := i64(0)
		mut index := 0
		for index < event_count {
			coordinate_code := events[index] / 2
			coordinate := coordinate_code - 1000
			if index > 0 && active > 0 { total += coordinate - previous }
			mut delta := i64(0)
			for index < event_count && events[index] / 2 == coordinate_code {
				if events[index] % 2 == 0 { delta++ } else { delta-- }
				index++
			}
			active += delta
			previous = coordinate
		}
		return total
	}
}
