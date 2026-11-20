package rectangle_union_area_sweep

import "core:c"

MAX_EVENTS :: 128
TREE_SIZE :: 512
MIN_COORDINATE :: i64(-1000000000)
MAX_COORDINATE :: i64(1000000000)

Event :: struct { x, y1, y2, delta: i64 }

sift_values :: proc(values: ^[MAX_EVENTS]i64, root_start, end_value: int) {
	root := root_start
	for root*2+1 < end_value {
		child := root*2+1
		if child+1 < end_value && values[child] < values[child+1] do child += 1
		if values[root] >= values[child] do return
		values[root], values[child] = values[child], values[root]
		root = child
	}
}

sort_values :: proc(values: ^[MAX_EVENTS]i64, count: int) {
	for start := count/2-1; start >= 0; start -= 1 { sift_values(values, start, count) }
	for end_value := count-1; end_value > 0; end_value -= 1 {
		values[0], values[end_value] = values[end_value], values[0]
		sift_values(values, 0, end_value)
	}
}

sift_events :: proc(events: ^[MAX_EVENTS]Event, root_start, end_value: int) {
	root := root_start
	for root*2+1 < end_value {
		child := root*2+1
		if child+1 < end_value && events[child].x < events[child+1].x do child += 1
		if events[root].x >= events[child].x do return
		events[root], events[child] = events[child], events[root]
		root = child
	}
}

sort_events :: proc(events: ^[MAX_EVENTS]Event, count: int) {
	for start := count/2-1; start >= 0; start -= 1 { sift_events(events, start, count) }
	for end_value := count-1; end_value > 0; end_value -= 1 {
		events[0], events[end_value] = events[end_value], events[0]
		sift_events(events, 0, end_value)
	}
}

lower_bound :: proc(values: ^[MAX_EVENTS]i64, count: int, target: i64) -> int {
	low, high := 0, count
	for low < high {
		middle := low + (high-low)/2
		if values[middle] < target { low = middle+1 } else { high = middle }
	}
	return low
}

update :: proc(node, left, right, ql, qr: int, delta: i64,
		ys: ^[MAX_EVENTS]i64, cover, covered: ^[TREE_SIZE]i64) {
	if ql <= left && right <= qr { cover[node] += delta }
	else {
		middle := left+(right-left)/2
		if ql < middle do update(node*2, left, middle, ql, qr, delta, ys, cover, covered)
		if qr > middle do update(node*2+1, middle, right, ql, qr, delta, ys, cover, covered)
	}
	if cover[node] > 0 { covered[node] = ys[right]-ys[left] }
	else if right-left == 1 { covered[node] = 0 }
	else { covered[node] = covered[node*2]+covered[node*2+1] }
}

@(export)
rectangle_union_area_sweep :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 258 do return -1
	if input[0] < 0 || input[0] > 64 do return -1
	count := int(input[0])
	if length != c.size_t(1+4*count) do return -1
	var ys: [MAX_EVENTS]i64
	var events: [MAX_EVENTS]Event
	y_count, event_count := 0, 0
	for i := 0; i < count; i += 1 {
		x1, y1 := input[1+4*i], input[2+4*i]
		x2, y2 := input[3+4*i], input[4+4*i]
		if x1 < MIN_COORDINATE || x1 > MAX_COORDINATE || x2 < MIN_COORDINATE || x2 > MAX_COORDINATE ||
			y1 < MIN_COORDINATE || y1 > MAX_COORDINATE || y2 < MIN_COORDINATE || y2 > MAX_COORDINATE || x1 >= x2 || y1 >= y2 do return -1
		ys[y_count], ys[y_count+1] = y1, y2
		y_count += 2
		events[event_count] = Event{x1, y1, y2, 1}
		events[event_count+1] = Event{x2, y1, y2, -1}
		event_count += 2
	}
	if count == 0 do return 0
	sort_values(&ys, y_count)
	unique_count := 1
	for i := 1; i < y_count; i += 1 {
		if ys[i] != ys[unique_count-1] { ys[unique_count] = ys[i]; unique_count += 1 }
	}
	sort_events(&events, event_count)
	var cover: [TREE_SIZE]i64
	var covered: [TREE_SIZE]i64
	intervals := unique_count-1
	area: i64 = 0
	previous_x := events[0].x
	event := 0
	for event < event_count {
		x := events[event].x
		area += covered[1]*(x-previous_x)
		finish := event
		for finish < event_count && events[finish].x == x { finish += 1 }
		for delta in [2]i64{1, -1} {
			for i := event; i < finish; i += 1 {
				if events[i].delta != delta do continue
				low := lower_bound(&ys, unique_count, events[i].y1)
				high := lower_bound(&ys, unique_count, events[i].y2)
				update(1, 0, intervals, low, high, delta, &ys, &cover, &covered)
			}
		}
		previous_x = x
		event = finish
	}
	return area
}
