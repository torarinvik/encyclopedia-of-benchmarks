const MAX_SEGMENTS: usize = 24;
const MAX_INPUT: usize = 98;
const COORD_MIN: i64 = -100;
const COORD_MAX: i64 = 100;

#[derive(Clone, Copy, Default)]
struct Segment { x1: i64, y1: i64, x2: i64, y2: i64 }

#[derive(Clone, Copy, Default)]
struct Event { x: i64, id: usize, starts: bool }

fn orient(ax: i64, ay: i64, bx: i64, by: i64, cx: i64, cy: i64) -> i64 {
    (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
}

fn between(a: i64, b: i64, point: i64) -> bool {
    if a <= b { return a <= point && point <= b; }
    b <= point && point <= a
}

fn on_segment(ax: i64, ay: i64, bx: i64, by: i64, px: i64, py: i64) -> bool {
    orient(ax, ay, bx, by, px, py) == 0 && between(ax, bx, px) && between(ay, by, py)
}

fn intersects(a: Segment, b: Segment) -> bool {
    let ab_c = orient(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1);
    let ab_d = orient(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2);
    let cd_a = orient(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1);
    let cd_b = orient(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2);
    if ab_c == 0 && on_segment(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1) { return true; }
    if ab_d == 0 && on_segment(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2) { return true; }
    if cd_a == 0 && on_segment(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1) { return true; }
    if cd_b == 0 && on_segment(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2) { return true; }
    ((ab_c < 0 && ab_d > 0) || (ab_c > 0 && ab_d < 0)) &&
        ((cd_a < 0 && cd_b > 0) || (cd_a > 0 && cd_b < 0))
}

fn compare_at_x(a: Segment, id_a: usize, b: Segment, id_b: usize, x: i64) -> i8 {
    let adx = a.x2 - a.x1;
    let bdx = b.x2 - b.x1;
    let anum = a.y1 * adx + (a.y2 - a.y1) * (x - a.x1);
    let bnum = b.y1 * bdx + (b.y2 - b.y1) * (x - b.x1);
    let left = anum * bdx;
    let right = bnum * adx;
    if left < right { return -1; }
    if left > right { return 1; }
    let aslope = (a.y2 - a.y1) * bdx;
    let bslope = (b.y2 - b.y1) * adx;
    if aslope < bslope { return -1; }
    if aslope > bslope { return 1; }
    if id_a < id_b { return -1; }
    if id_a > id_b { return 1; }
    0
}

#[no_mangle]
pub unsafe extern "C" fn intersecting_segments_sweep(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_raw = values[0];
    if !(0..=MAX_SEGMENTS as i64).contains(&count_raw) || length != 1 + 4 * count_raw as usize { return -1; }
    let count = count_raw as usize;
    let mut used_x = [false; 201];
    let mut segments = [Segment::default(); MAX_SEGMENTS];
    let mut events = [Event::default(); 2 * MAX_SEGMENTS];
    let mut event_count = 0usize;
    for id in 0..count {
        let offset = 1 + 4 * id;
        let segment = Segment { x1: values[offset], y1: values[offset + 1], x2: values[offset + 2], y2: values[offset + 3] };
        if !(COORD_MIN..=COORD_MAX).contains(&segment.x1) || !(COORD_MIN..=COORD_MAX).contains(&segment.x2) ||
            !(COORD_MIN..=COORD_MAX).contains(&segment.y1) || !(COORD_MIN..=COORD_MAX).contains(&segment.y2) || segment.x1 >= segment.x2 { return -1; }
        let first_x = (segment.x1 - COORD_MIN) as usize;
        let second_x = (segment.x2 - COORD_MIN) as usize;
        if used_x[first_x] || used_x[second_x] { return -1; }
        used_x[first_x] = true;
        used_x[second_x] = true;
        segments[id] = segment;
        events[event_count] = Event { x: segment.x1, id, starts: true };
        event_count += 1;
        events[event_count] = Event { x: segment.x2, id, starts: false };
        event_count += 1;
    }
    for index in 1..event_count {
        let item = events[index];
        let mut position = index;
        while position > 0 && events[position - 1].x > item.x {
            events[position] = events[position - 1];
            position -= 1;
        }
        events[position] = item;
    }

    let mut active = [0usize; MAX_SEGMENTS];
    let mut active_count = 0usize;
    for event in events.iter().take(event_count) {
        if event.starts {
            let mut position = 0usize;
            while position < active_count && compare_at_x(segments[active[position]], active[position],
                    segments[event.id], event.id, event.x) < 0 { position += 1; }
            if position > 0 && intersects(segments[active[position - 1]], segments[event.id]) { return 1; }
            if position < active_count && intersects(segments[active[position]], segments[event.id]) { return 1; }
            for move_index in (position..active_count).rev() { active[move_index + 1] = active[move_index]; }
            active[position] = event.id;
            active_count += 1;
        } else {
            let mut position = 0usize;
            while position < active_count && active[position] != event.id { position += 1; }
            if position == active_count { return -1; }
            if position > 0 && position + 1 < active_count && intersects(segments[active[position - 1]], segments[active[position + 1]]) { return 1; }
            for move_index in position..active_count - 1 { active[move_index] = active[move_index + 1]; }
            active_count -= 1;
        }
    }
    0
}
