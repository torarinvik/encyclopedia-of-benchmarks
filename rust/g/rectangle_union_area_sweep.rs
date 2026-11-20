const MAX_RECTANGLES: usize = 64;
const MAX_EVENTS: usize = 128;
const TREE_SIZE: usize = 512;
const MIN_COORDINATE: i64 = -1_000_000_000;
const MAX_COORDINATE: i64 = 1_000_000_000;

#[derive(Clone, Copy, Default)]
struct Event { x: i64, y1: i64, y2: i64, delta: i64 }

fn sift_values(values: &mut [i64], mut root: usize, end: usize) {
    while root * 2 + 1 < end {
        let mut child = root * 2 + 1;
        if child + 1 < end && values[child] < values[child + 1] { child += 1; }
        if values[root] >= values[child] { return; }
        values.swap(root, child);
        root = child;
    }
}

fn sort_values(values: &mut [i64]) {
    for start in (0..values.len() / 2).rev() { sift_values(values, start, values.len()); }
    for end in (1..values.len()).rev() {
        values.swap(0, end);
        sift_values(values, 0, end);
    }
}

fn sift_events(events: &mut [Event], mut root: usize, end: usize) {
    while root * 2 + 1 < end {
        let mut child = root * 2 + 1;
        if child + 1 < end && events[child].x < events[child + 1].x { child += 1; }
        if events[root].x >= events[child].x { return; }
        events.swap(root, child);
        root = child;
    }
}

fn sort_events(events: &mut [Event]) {
    for start in (0..events.len() / 2).rev() { sift_events(events, start, events.len()); }
    for end in (1..events.len()).rev() {
        events.swap(0, end);
        sift_events(events, 0, end);
    }
}

fn lower_bound(values: &[i64], target: i64) -> usize {
    let (mut low, mut high) = (0, values.len());
    while low < high {
        let middle = low + (high - low) / 2;
        if values[middle] < target { low = middle + 1; } else { high = middle; }
    }
    low
}

fn update(node: usize, left: usize, right: usize, ql: usize, qr: usize, delta: i64,
          ys: &[i64], cover: &mut [i64; TREE_SIZE], covered: &mut [i64; TREE_SIZE]) {
    if ql <= left && right <= qr { cover[node] += delta; }
    else {
        let middle = left + (right - left) / 2;
        if ql < middle { update(node * 2, left, middle, ql, qr, delta, ys, cover, covered); }
        if qr > middle { update(node * 2 + 1, middle, right, ql, qr, delta, ys, cover, covered); }
    }
    covered[node] = if cover[node] > 0 { ys[right] - ys[left] }
        else if right - left == 1 { 0 }
        else { covered[node * 2] + covered[node * 2 + 1] };
}

fn solve(input: &[i64]) -> i64 {
    if input.is_empty() || input.len() > 258 { return -1; }
    if input[0] < 0 || input[0] > MAX_RECTANGLES as i64 { return -1; }
    let count = input[0] as usize;
    if input.len() != 1 + 4 * count { return -1; }
    let mut ys = [0_i64; MAX_EVENTS];
    let mut events = [Event::default(); MAX_EVENTS];
    let (mut y_count, mut event_count) = (0, 0);
    for i in 0..count {
        let (x1, y1, x2, y2) = (input[1 + 4*i], input[2 + 4*i], input[3 + 4*i], input[4 + 4*i]);
        if [x1, y1, x2, y2].iter().any(|&v| v < MIN_COORDINATE || v > MAX_COORDINATE)
            || x1 >= x2 || y1 >= y2 { return -1; }
        ys[y_count] = y1; ys[y_count + 1] = y2; y_count += 2;
        events[event_count] = Event { x: x1, y1, y2, delta: 1 };
        events[event_count + 1] = Event { x: x2, y1, y2, delta: -1 };
        event_count += 2;
    }
    if count == 0 { return 0; }
    sort_values(&mut ys[..y_count]);
    let mut unique_count = 1;
    for i in 1..y_count {
        if ys[i] != ys[unique_count - 1] { ys[unique_count] = ys[i]; unique_count += 1; }
    }
    sort_events(&mut events[..event_count]);
    let mut cover = [0_i64; TREE_SIZE];
    let mut covered = [0_i64; TREE_SIZE];
    let mut area = 0_i64;
    let mut previous_x = events[0].x;
    let intervals = unique_count - 1;
    let mut event = 0;
    while event < event_count {
        let x = events[event].x;
        area += covered[1] * (x - previous_x);
        let mut end = event;
        while end < event_count && events[end].x == x { end += 1; }
        for pass in [1_i64, -1_i64] {
            for i in event..end {
                if events[i].delta != pass { continue; }
                let low = lower_bound(&ys[..unique_count], events[i].y1);
                let high = lower_bound(&ys[..unique_count], events[i].y2);
                update(1, 0, intervals, low, high, events[i].delta, &ys, &mut cover, &mut covered);
            }
        }
        previous_x = x;
        event = end;
    }
    area
}

#[no_mangle]
pub unsafe extern "C" fn rectangle_union_area_sweep(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > 258 { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
