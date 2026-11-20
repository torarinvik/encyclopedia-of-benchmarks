const max_n: usize = 64;
const max_events: usize = 128;
const max_input_length: usize = 130;

fn siftDown(events: *[max_events]i64, root_start: usize, end: usize) void {
    var root = root_start;
    while (root < end / 2) {
        var child = 2 * root + 1;
        if (child + 1 < end and events[child] < events[child + 1]) child += 1;
        if (events[root] >= events[child]) break;
        const temporary = events[root];
        events[root] = events[child];
        events[child] = temporary;
        root = child;
    }
}

export fn segment_union_length_klee(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > max_input_length) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 2 * n) return -1;
    var events = [_]i64{0} ** max_events;
    for (0..n) |i| {
        const left = input[1 + 2 * i];
        const right = input[2 + 2 * i];
        if (left < -1000 or left > right or right > 1000) return -1;
        events[2 * i] = 2 * (left + 1000);
        events[2 * i + 1] = 2 * (right + 1000) + 1;
    }
    const event_count = 2 * n;
    if (event_count == 0) return 0;
    var start = event_count / 2;
    while (start > 0) {
        start -= 1;
        siftDown(&events, start, event_count);
    }
    var end = event_count;
    while (end > 1) {
        end -= 1;
        const temporary = events[0];
        events[0] = events[end];
        events[end] = temporary;
        siftDown(&events, 0, end);
    }
    var active: i64 = 0;
    var total: i64 = 0;
    var previous: i64 = 0;
    var index: usize = 0;
    while (index < event_count) {
        const coordinate_code = events[index] / 2;
        const coordinate = coordinate_code - 1000;
        if (index > 0 and active > 0) total += coordinate - previous;
        var delta: i64 = 0;
        while (index < event_count and events[index] / 2 == coordinate_code) {
            if (events[index] % 2 == 0) delta += 1 else delta -= 1;
            index += 1;
        }
        active += delta;
        previous = coordinate;
    }
    return total;
}
