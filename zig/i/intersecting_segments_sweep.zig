const MAX_SEGMENTS: usize = 24;
const MAX_INPUT: usize = 98;
const COORD_MIN: i64 = -100;
const COORD_MAX: i64 = 100;

const Segment = struct { x1: i64, y1: i64, x2: i64, y2: i64 };
const Event = struct { x: i64, id: usize, starts: bool };

fn orient(ax: i64, ay: i64, bx: i64, by: i64, cx: i64, cy: i64) i64 {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

fn between(a: i64, b: i64, point: i64) bool {
    if (a <= b) return a <= point and point <= b;
    return b <= point and point <= a;
}

fn onSegment(ax: i64, ay: i64, bx: i64, by: i64, px: i64, py: i64) bool {
    return orient(ax, ay, bx, by, px, py) == 0 and between(ax, bx, px) and between(ay, by, py);
}

fn intersects(a: Segment, b: Segment) bool {
    const ab_c = orient(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1);
    const ab_d = orient(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2);
    const cd_a = orient(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1);
    const cd_b = orient(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2);
    if (ab_c == 0 and onSegment(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1)) return true;
    if (ab_d == 0 and onSegment(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2)) return true;
    if (cd_a == 0 and onSegment(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1)) return true;
    if (cd_b == 0 and onSegment(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2)) return true;
    return ((ab_c < 0 and ab_d > 0) or (ab_c > 0 and ab_d < 0)) and
        ((cd_a < 0 and cd_b > 0) or (cd_a > 0 and cd_b < 0));
}

fn compareAtX(a: Segment, id_a: usize, b: Segment, id_b: usize, x: i64) i8 {
    const adx = a.x2 - a.x1;
    const bdx = b.x2 - b.x1;
    const anum = a.y1 * adx + (a.y2 - a.y1) * (x - a.x1);
    const bnum = b.y1 * bdx + (b.y2 - b.y1) * (x - b.x1);
    const left = anum * bdx;
    const right = bnum * adx;
    if (left < right) return -1;
    if (left > right) return 1;
    const aslope = (a.y2 - a.y1) * bdx;
    const bslope = (b.y2 - b.y1) * adx;
    if (aslope < bslope) return -1;
    if (aslope > bslope) return 1;
    if (id_a < id_b) return -1;
    if (id_a > id_b) return 1;
    return 0;
}

export fn intersecting_segments_sweep(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 1 or length > MAX_INPUT) return -1;
    const count_raw = input[0];
    if (count_raw < 0 or count_raw > 24 or length != 1 + 4 * @as(usize, @intCast(count_raw))) return -1;
    const count: usize = @intCast(count_raw);
    var used_x = [_]bool{false} ** 201;
    var segments: [MAX_SEGMENTS]Segment = undefined;
    var events: [2 * MAX_SEGMENTS]Event = undefined;
    var event_count: usize = 0;
    for (0..count) |id| {
        const offset = 1 + 4 * id;
        const segment = Segment{ .x1 = input[offset], .y1 = input[offset + 1], .x2 = input[offset + 2], .y2 = input[offset + 3] };
        if (segment.x1 < COORD_MIN or segment.x1 > COORD_MAX or segment.x2 < COORD_MIN or segment.x2 > COORD_MAX or
            segment.y1 < COORD_MIN or segment.y1 > COORD_MAX or segment.y2 < COORD_MIN or segment.y2 > COORD_MAX or segment.x1 >= segment.x2) return -1;
        const first_x: usize = @intCast(segment.x1 - COORD_MIN);
        const second_x: usize = @intCast(segment.x2 - COORD_MIN);
        if (used_x[first_x] or used_x[second_x]) return -1;
        used_x[first_x] = true;
        used_x[second_x] = true;
        segments[id] = segment;
        events[event_count] = .{ .x = segment.x1, .id = id, .starts = true };
        event_count += 1;
        events[event_count] = .{ .x = segment.x2, .id = id, .starts = false };
        event_count += 1;
    }
    var sort_index: usize = 1;
    while (sort_index < event_count) : (sort_index += 1) {
        const item = events[sort_index];
        var position = sort_index;
        while (position > 0 and events[position - 1].x > item.x) : (position -= 1) {
            events[position] = events[position - 1];
        }
        events[position] = item;
    }

    var active: [MAX_SEGMENTS]usize = undefined;
    var active_count: usize = 0;
    for (0..event_count) |event_index| {
        const event = events[event_index];
        if (event.starts) {
            var position: usize = 0;
            while (position < active_count and compareAtX(segments[active[position]], active[position], segments[event.id], event.id, event.x) < 0) : (position += 1) {}
            if (position > 0 and intersects(segments[active[position - 1]], segments[event.id])) return 1;
            if (position < active_count and intersects(segments[active[position]], segments[event.id])) return 1;
            var move = active_count;
            while (move > position) : (move -= 1) active[move] = active[move - 1];
            active[position] = event.id;
            active_count += 1;
        } else {
            var position: usize = 0;
            while (position < active_count and active[position] != event.id) : (position += 1) {}
            if (position == active_count) return -1;
            if (position > 0 and position + 1 < active_count and intersects(segments[active[position - 1]], segments[active[position + 1]])) return 1;
            var move = position;
            while (move + 1 < active_count) : (move += 1) active[move] = active[move + 1];
            active_count -= 1;
        }
    }
    return 0;
}
