package intersecting_segments_sweep

import "core:c"

MAX_SEGMENTS :: 24
MAX_INPUT :: 98
COORD_MIN: i64 = -100
COORD_MAX: i64 = 100

Segment :: struct { x1, y1, x2, y2: i64 }
Event :: struct { x: i64, id: int, starts: bool }

sweep_orient :: proc(ax, ay, bx, by, cx, cy: i64) -> i64 {
	return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
}

sweep_between :: proc(a, b, point: i64) -> bool {
	if a <= b do return a <= point && point <= b
	return b <= point && point <= a
}

sweep_on_segment :: proc(ax, ay, bx, by, px, py: i64) -> bool {
	return sweep_orient(ax, ay, bx, by, px, py) == 0 && sweep_between(ax, bx, px) && sweep_between(ay, by, py)
}

sweep_intersects :: proc(a, b: Segment) -> bool {
	ab_c := sweep_orient(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1)
	ab_d := sweep_orient(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2)
	cd_a := sweep_orient(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1)
	cd_b := sweep_orient(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2)
	if ab_c == 0 && sweep_on_segment(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1) do return true
	if ab_d == 0 && sweep_on_segment(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2) do return true
	if cd_a == 0 && sweep_on_segment(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1) do return true
	if cd_b == 0 && sweep_on_segment(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2) do return true
	return ((ab_c < 0 && ab_d > 0) || (ab_c > 0 && ab_d < 0)) &&
		((cd_a < 0 && cd_b > 0) || (cd_a > 0 && cd_b < 0))
}

sweep_compare_at_x :: proc(a: Segment, id_a: int, b: Segment, id_b: int, x: i64) -> int {
	adx, bdx := a.x2 - a.x1, b.x2 - b.x1
	anum := a.y1 * adx + (a.y2 - a.y1) * (x - a.x1)
	bnum := b.y1 * bdx + (b.y2 - b.y1) * (x - b.x1)
	left, right := anum * bdx, bnum * adx
	if left < right do return -1
	if left > right do return 1
	aslope, bslope := (a.y2 - a.y1) * bdx, (b.y2 - b.y1) * adx
	if aslope < bslope do return -1
	if aslope > bslope do return 1
	if id_a < id_b do return -1
	if id_a > id_b do return 1
	return 0
}

@(export)
intersecting_segments_sweep :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT do return -1
	count_raw := input[0]
	if count_raw < 0 || count_raw > MAX_SEGMENTS || length != c.size_t(1 + 4 * count_raw) do return -1
	count := int(count_raw)
	used_x: [201]bool
	segments: [MAX_SEGMENTS]Segment
	events: [2 * MAX_SEGMENTS]Event
	event_count := 0
	for id := 0; id < count; id += 1 {
		offset := 1 + 4 * id
		segment := Segment{x1 = input[offset], y1 = input[offset + 1], x2 = input[offset + 2], y2 = input[offset + 3]}
		if segment.x1 < COORD_MIN || segment.x1 > COORD_MAX || segment.x2 < COORD_MIN || segment.x2 > COORD_MAX ||
			segment.y1 < COORD_MIN || segment.y1 > COORD_MAX || segment.y2 < COORD_MIN || segment.y2 > COORD_MAX || segment.x1 >= segment.x2 do return -1
		first_x, second_x := int(segment.x1 - COORD_MIN), int(segment.x2 - COORD_MIN)
		if used_x[first_x] || used_x[second_x] do return -1
		used_x[first_x], used_x[second_x] = true, true
		segments[id] = segment
		events[event_count] = Event{x = segment.x1, id = id, starts = true}; event_count += 1
		events[event_count] = Event{x = segment.x2, id = id, starts = false}; event_count += 1
	}
	for index := 1; index < event_count; index += 1 {
		item := events[index]
		position := index
		for position > 0 && events[position - 1].x > item.x {
			events[position] = events[position - 1]
			position -= 1
		}
		events[position] = item
	}

	active: [MAX_SEGMENTS]int
	active_count := 0
	for event_index := 0; event_index < event_count; event_index += 1 {
		event := events[event_index]
		if event.starts {
			position := 0
			for position < active_count && sweep_compare_at_x(segments[active[position]], active[position], segments[event.id], event.id, event.x) < 0 {
				position += 1
			}
			if position > 0 && sweep_intersects(segments[active[position - 1]], segments[event.id]) do return 1
			if position < active_count && sweep_intersects(segments[active[position]], segments[event.id]) do return 1
			for move := active_count; move > position; move -= 1 do active[move] = active[move - 1]
			active[position] = event.id
			active_count += 1
		} else {
			position := 0
			for position < active_count && active[position] != event.id do position += 1
			if position == active_count do return -1
			if position > 0 && position + 1 < active_count && sweep_intersects(segments[active[position - 1]], segments[active[position + 1]]) do return 1
			for move := position; move + 1 < active_count; move += 1 do active[move] = active[move + 1]
			active_count -= 1
		}
	}
	return 0
}
