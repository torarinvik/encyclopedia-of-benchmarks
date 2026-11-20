module rectangle_union_area_sweep

const max_events = 128
const tree_size = 512
const min_coordinate = i64(-1000000000)
const max_coordinate = i64(1000000000)

struct RuasEvent {
mut:
	x i64
	y1 i64
	y2 i64
	delta i64
}

fn ruas_sift_values(mut values [max_events]i64, root_start int, end_value int) {
	mut root := root_start
	for root * 2 + 1 < end_value {
		mut child := root * 2 + 1
		if child + 1 < end_value && values[child] < values[child + 1] { child++ }
		if values[root] >= values[child] { return }
		values[root], values[child] = values[child], values[root]
		root = child
	}
}

fn ruas_sort_values(mut values [max_events]i64, count int) {
	for start0 in 0 .. count / 2 {
		start := count / 2 - 1 - start0
		ruas_sift_values(mut values, start, count)
	}
	for end0 in 0 .. max(0, count - 1) {
		end_value := count - 1 - end0
		values[0], values[end_value] = values[end_value], values[0]
		ruas_sift_values(mut values, 0, end_value)
	}
}

fn ruas_sift_events(mut events [max_events]RuasEvent, root_start int, end_value int) {
	mut root := root_start
	for root * 2 + 1 < end_value {
		mut child := root * 2 + 1
		if child + 1 < end_value && events[child].x < events[child + 1].x { child++ }
		if events[root].x >= events[child].x { return }
		events[root], events[child] = events[child], events[root]
		root = child
	}
}

fn ruas_sort_events(mut events [max_events]RuasEvent, count int) {
	for start0 in 0 .. count / 2 {
		start := count / 2 - 1 - start0
		ruas_sift_events(mut events, start, count)
	}
	for end0 in 0 .. max(0, count - 1) {
		end_value := count - 1 - end0
		events[0], events[end_value] = events[end_value], events[0]
		ruas_sift_events(mut events, 0, end_value)
	}
}

fn ruas_lower_bound(values []i64, count int, target i64) int {
	mut low := 0
	mut high := count
	for low < high {
		middle := low + (high - low) / 2
		if values[middle] < target { low = middle + 1 } else { high = middle }
	}
	return low
}

fn ruas_update(node int, left int, right int, ql int, qr int, delta i64,
		mut ys [max_events]i64, mut cover [tree_size]i64, mut covered [tree_size]i64) {
	if ql <= left && right <= qr { cover[node] += delta }
	else {
		middle := left + (right - left) / 2
		if ql < middle { ruas_update(node * 2, left, middle, ql, qr, delta, mut ys, mut cover, mut covered) }
		if qr > middle { ruas_update(node * 2 + 1, middle, right, ql, qr, delta, mut ys, mut cover, mut covered) }
	}
	if cover[node] > 0 { covered[node] = ys[right] - ys[left] }
	else if right - left == 1 { covered[node] = 0 }
	else { covered[node] = covered[node * 2] + covered[node * 2 + 1] }
}

@[export: 'rectangle_union_area_sweep']
pub fn rectangle_union_area_sweep(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 258 || input[0] < 0 || input[0] > 64 { return -1 }
		count := int(input[0])
		if length != usize(1 + 4 * count) { return -1 }
		mut ys := [max_events]i64{}
		mut events := [max_events]RuasEvent{}
		mut y_count := 0
		mut event_count := 0
		for i in 0 .. count {
			x1 := input[1 + 4 * i]
			y1 := input[2 + 4 * i]
			x2 := input[3 + 4 * i]
			y2 := input[4 + 4 * i]
			if x1 < min_coordinate || x1 > max_coordinate || x2 < min_coordinate || x2 > max_coordinate || y1 < min_coordinate || y1 > max_coordinate || y2 < min_coordinate || y2 > max_coordinate || x1 >= x2 || y1 >= y2 { return -1 }
			ys[y_count] = y1
			ys[y_count + 1] = y2
			y_count += 2
			events[event_count] = RuasEvent{x: x1, y1: y1, y2: y2, delta: 1}
			events[event_count + 1] = RuasEvent{x: x2, y1: y1, y2: y2, delta: -1}
			event_count += 2
		}
		if count == 0 { return 0 }
		ruas_sort_values(mut ys, y_count)
		mut unique_count := 1
		for i in 1 .. y_count {
			if ys[i] != ys[unique_count - 1] {
				ys[unique_count] = ys[i]
				unique_count++
			}
		}
		ruas_sort_events(mut events, event_count)
		mut cover := [tree_size]i64{}
		mut covered := [tree_size]i64{}
		intervals := unique_count - 1
		mut area := i64(0)
		mut previous_x := events[0].x
		mut event := 0
		for event < event_count {
			x := events[event].x
			area += covered[1] * (x - previous_x)
			mut finish := event
			for finish < event_count && events[finish].x == x { finish++ }
			for delta in [i64(1), i64(-1)] {
				for i in event .. finish {
					if events[i].delta != delta { continue }
					low := ruas_lower_bound(ys[..], unique_count, events[i].y1)
					high := ruas_lower_bound(ys[..], unique_count, events[i].y2)
					ruas_update(1, 0, intervals, low, high, delta, mut ys, mut cover, mut covered)
				}
			}
			previous_x = x
			event = finish
		}
		return area
	}
}
