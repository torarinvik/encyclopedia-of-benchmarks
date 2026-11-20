package segment_union_length_klee

import "core:c"

MAX_N :: 64
MAX_EVENTS :: 128
MAX_INPUT_VALUES :: 130

sift_down :: proc "contextless" (events: [^]i64, root_start, end_value: int) {
	root := root_start
	for root < end_value / 2 {
		child := root * 2 + 1
		if child + 1 < end_value && events[child] < events[child+1] do child += 1
		if events[root] >= events[child] do break
		temporary := events[root]
		events[root] = events[child]
		events[child] = temporary
		root = child
	}
}

heap_sort :: proc "contextless" (events: [^]i64, count: int) {
	start := count / 2
	for start > 0 {
		start -= 1
		sift_down(events, start, count)
	}
	ending := count
	for ending > 1 {
		ending -= 1
		temporary := events[0]
		events[0] = events[ending]
		events[ending] = temporary
		sift_down(events, 0, ending)
	}
}

@(export)
segment_union_length_klee :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_VALUES do return -1
	n_value := input[0]
	if n_value < 0 || n_value > MAX_N do return -1
	n := int(n_value)
	if length != c.size_t(1 + 2*n) do return -1
	events: [MAX_EVENTS]i64
	for i := 0; i < n; i += 1 {
		left, right := input[1+2*i], input[2+2*i]
		if left < -1000 || left > right || right > 1000 do return -1
		events[2*i] = 2 * (left + 1000)
		events[2*i+1] = 2 * (right + 1000) + 1
	}
	event_count := 2*n
	if event_count == 0 do return 0
	heap_sort(&events[0], event_count)
	active, total, previous := i64(0), i64(0), i64(0)
	index := 0
	for index < event_count {
		coordinate_code := events[index] / 2
		coordinate := coordinate_code - 1000
		if index > 0 && active > 0 do total += coordinate - previous
		delta := i64(0)
		for index < event_count && events[index] / 2 == coordinate_code {
			if events[index] % 2 == 0 do delta += 1 else delta -= 1
			index += 1
		}
		active += delta
		previous = coordinate
	}
	return total
}
