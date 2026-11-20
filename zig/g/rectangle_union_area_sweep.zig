const MAX_EVENTS: usize = 128;
const TREE_SIZE: usize = 512;
const MIN_COORDINATE: i64 = -1_000_000_000;
const MAX_COORDINATE: i64 = 1_000_000_000;

const Event = struct { x: i64, y1: i64, y2: i64, delta: i64 };

fn siftValues(values: *[MAX_EVENTS]i64, root_start: usize, end_value: usize) void {
    var root = root_start;
    while (root * 2 + 1 < end_value) {
        var child = root * 2 + 1;
        if (child + 1 < end_value and values[0][child] < values[0][child + 1]) child += 1;
        if (values[0][root] >= values[0][child]) return;
        const value = values[0][root];
        values[0][root] = values[0][child];
        values[0][child] = value;
        root = child;
    }
}

fn sortValues(values: *[MAX_EVENTS]i64, count: usize) void {
    var start = count / 2;
    while (start > 0) { start -= 1; siftValues(values, start, count); }
    var end_value = count;
    while (end_value > 1) {
        end_value -= 1;
        const value = values[0][0]; values[0][0] = values[0][end_value]; values[0][end_value] = value;
        siftValues(values, 0, end_value);
    }
}

fn siftEvents(events: *[MAX_EVENTS]Event, root_start: usize, end_value: usize) void {
    var root = root_start;
    while (root * 2 + 1 < end_value) {
        var child = root * 2 + 1;
        if (child + 1 < end_value and events[0][child].x < events[0][child + 1].x) child += 1;
        if (events[0][root].x >= events[0][child].x) return;
        const value = events[0][root]; events[0][root] = events[0][child]; events[0][child] = value;
        root = child;
    }
}

fn sortEvents(events: *[MAX_EVENTS]Event, count: usize) void {
    var start = count / 2;
    while (start > 0) { start -= 1; siftEvents(events, start, count); }
    var end_value = count;
    while (end_value > 1) {
        end_value -= 1;
        const value = events[0][0]; events[0][0] = events[0][end_value]; events[0][end_value] = value;
        siftEvents(events, 0, end_value);
    }
}

fn lowerBound(values: *const [MAX_EVENTS]i64, count: usize, target: i64) usize {
    var low: usize = 0;
    var high = count;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (values[0][middle] < target) low = middle + 1 else high = middle;
    }
    return low;
}

fn update(node: usize, left: usize, right: usize, ql: usize, qr: usize, delta: i64,
          ys: *const [MAX_EVENTS]i64, cover: *[TREE_SIZE]i64,
          covered: *[TREE_SIZE]i64) void {
    if (ql <= left and right <= qr) cover[0][node] += delta else {
        const middle = left + (right - left) / 2;
        if (ql < middle) update(node * 2, left, middle, ql, qr, delta, ys, cover, covered);
        if (qr > middle) update(node * 2 + 1, middle, right, ql, qr, delta, ys, cover, covered);
    }
    if (cover[0][node] > 0) covered[0][node] = ys[0][right] - ys[0][left]
    else if (right - left == 1) covered[0][node] = 0
    else covered[0][node] = covered[0][node * 2] + covered[0][node * 2 + 1];
}

pub export fn rectangle_union_area_sweep(input: [*c]const i64, length: usize) i64 {
    if (input == null or length == 0 or length > 258) return -1;
    if (input[0] < 0 or input[0] > 64) return -1;
    const count: usize = @intCast(input[0]);
    if (length != 1 + 4 * count) return -1;
    var ys: [MAX_EVENTS]i64 = @splat(0);
    var events: [MAX_EVENTS]Event = undefined;
    var y_count: usize = 0;
    var event_count: usize = 0;
    for (0..count) |i| {
        const x1 = input[1 + 4 * i]; const y1 = input[2 + 4 * i];
        const x2 = input[3 + 4 * i]; const y2 = input[4 + 4 * i];
        if (x1 < MIN_COORDINATE or x1 > MAX_COORDINATE or x2 < MIN_COORDINATE or x2 > MAX_COORDINATE
            or y1 < MIN_COORDINATE or y1 > MAX_COORDINATE or y2 < MIN_COORDINATE or y2 > MAX_COORDINATE
            or x1 >= x2 or y1 >= y2) return -1;
        ys[y_count] = y1; ys[y_count + 1] = y2; y_count += 2;
        events[event_count] = .{ .x = x1, .y1 = y1, .y2 = y2, .delta = 1 };
        events[event_count + 1] = .{ .x = x2, .y1 = y1, .y2 = y2, .delta = -1 };
        event_count += 2;
    }
    if (count == 0) return 0;
    sortValues(&ys, y_count);
    var unique_count: usize = 1;
    for (1..y_count) |i| {
        if (ys[i] != ys[unique_count - 1]) { ys[unique_count] = ys[i]; unique_count += 1; }
    }
    sortEvents(&events, event_count);
    var cover: [TREE_SIZE]i64 = @splat(0);
    var covered: [TREE_SIZE]i64 = @splat(0);
    const intervals = unique_count - 1;
    var area: i64 = 0;
    var previous_x = events[0].x;
    var event: usize = 0;
    while (event < event_count) {
        const x = events[event].x;
        area += covered[1] * (x - previous_x);
        var finish = event;
        while (finish < event_count and events[finish].x == x) finish += 1;
        for ([_]i64{ 1, -1 }) |delta| {
            for (event..finish) |i| {
                if (events[i].delta != delta) continue;
                const low = lowerBound(&ys, unique_count, events[i].y1);
                const high = lowerBound(&ys, unique_count, events[i].y2);
                update(1, 0, intervals, low, high, delta, &ys, &cover, &covered);
            }
        }
        previous_x = x;
        event = finish;
    }
    return area;
}
