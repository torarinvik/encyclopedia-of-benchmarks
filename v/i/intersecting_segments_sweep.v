module intersecting_segments_sweep

const max_segments = 24
const max_input = 98
const coord_min = i64(-100)
const coord_max = i64(100)

struct Segment {
	x1 i64
	y1 i64
	x2 i64
	y2 i64
}

struct Event {
	x i64
	id int
	starts bool
}

fn sweep_orient(ax i64, ay i64, bx i64, by i64, cx i64, cy i64) i64 {
	return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
}

fn sweep_between(a i64, b i64, point i64) bool {
	if a <= b { return a <= point && point <= b }
	return b <= point && point <= a
}

fn sweep_on_segment(ax i64, ay i64, bx i64, by i64, px i64, py i64) bool {
	return sweep_orient(ax, ay, bx, by, px, py) == 0 && sweep_between(ax, bx, px) && sweep_between(ay, by, py)
}

fn sweep_intersects(a Segment, b Segment) bool {
	ab_c := sweep_orient(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1)
	ab_d := sweep_orient(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2)
	cd_a := sweep_orient(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1)
	cd_b := sweep_orient(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2)
	if ab_c == 0 && sweep_on_segment(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1) { return true }
	if ab_d == 0 && sweep_on_segment(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2) { return true }
	if cd_a == 0 && sweep_on_segment(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1) { return true }
	if cd_b == 0 && sweep_on_segment(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2) { return true }
	return ((ab_c < 0 && ab_d > 0) || (ab_c > 0 && ab_d < 0)) && ((cd_a < 0 && cd_b > 0) || (cd_a > 0 && cd_b < 0))
}

fn sweep_compare_at_x(a Segment, id_a int, b Segment, id_b int, x i64) int {
	adx := a.x2 - a.x1
	bdx := b.x2 - b.x1
	anum := a.y1 * adx + (a.y2 - a.y1) * (x - a.x1)
	bnum := b.y1 * bdx + (b.y2 - b.y1) * (x - b.x1)
	left := anum * bdx
	right := bnum * adx
	if left < right { return -1 }
	if left > right { return 1 }
	aslope := (a.y2 - a.y1) * bdx
	bslope := (b.y2 - b.y1) * adx
	if aslope < bslope { return -1 }
	if aslope > bslope { return 1 }
	if id_a < id_b { return -1 }
	if id_a > id_b { return 1 }
	return 0
}

@[export: 'intersecting_segments_sweep']
pub fn intersecting_segments_sweep(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input { return -1 }
	unsafe {
		count_raw := input[0]
		if count_raw < 0 || count_raw > max_segments || length != usize(1 + 4 * count_raw) { return -1 }
		count := int(count_raw)
		mut used_x := [201]bool{}
	mut segments := [max_segments]Segment{}
	mut events := [2 * max_segments]Event{}
	mut event_count := 0
		for id in 0 .. count {
			offset := 1 + 4 * id
			segment := Segment{x1: input[offset], y1: input[offset + 1], x2: input[offset + 2], y2: input[offset + 3]}
			if segment.x1 < coord_min || segment.x1 > coord_max || segment.x2 < coord_min || segment.x2 > coord_max || segment.y1 < coord_min || segment.y1 > coord_max || segment.y2 < coord_min || segment.y2 > coord_max || segment.x1 >= segment.x2 { return -1 }
			first_x := int(segment.x1 - coord_min)
			second_x := int(segment.x2 - coord_min)
			if used_x[first_x] || used_x[second_x] { return -1 }
			used_x[first_x] = true
			used_x[second_x] = true
			segments[id] = segment
			events[event_count] = Event{x: segment.x1, id: id, starts: true}
			event_count++
			events[event_count] = Event{x: segment.x2, id: id, starts: false}
			event_count++
		}
		for index in 0 .. event_count {
			if index == 0 { continue }
			item := events[index]
			mut position := index
			for position > 0 && events[position - 1].x > item.x {
				events[position] = events[position - 1]
				position--
			}
			events[position] = item
		}
		mut active := [max_segments]int{}
		mut active_count := 0
		for event_index in 0 .. event_count {
			event := events[event_index]
			if event.starts {
				mut position := 0
				for position < active_count && sweep_compare_at_x(segments[active[position]], active[position], segments[event.id], event.id, event.x) < 0 { position++ }
				if position > 0 && sweep_intersects(segments[active[position - 1]], segments[event.id]) { return 1 }
				if position < active_count && sweep_intersects(segments[active[position]], segments[event.id]) { return 1 }
				mut move := active_count
				for move > position { active[move] = active[move - 1]; move-- }
				active[position] = event.id
				active_count++
			} else {
				mut position := 0
				for position < active_count && active[position] != event.id { position++ }
				if position == active_count { return -1 }
				if position > 0 && position + 1 < active_count && sweep_intersects(segments[active[position - 1]], segments[active[position + 1]]) { return 1 }
				mut move := position
				for move + 1 < active_count { active[move] = active[move + 1]; move++ }
				active_count--
			}
		}
		return 0
	}
}
