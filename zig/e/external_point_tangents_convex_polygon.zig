const MAX_VERTICES: usize = 32;
const MAX_QUERIES: usize = 16;
const MAX_INPUT: usize = 99;
const MAX_COORDINATE: i64 = 1000;

const Point = struct { x: i64, y: i64 };
const Pair = struct { first: i64, second: i64 };

fn sub(a: Point, b: Point) Point { return .{ .x = a.x - b.x, .y = a.y - b.y }; }
fn cross(a: Point, b: Point) i64 { return a.x * b.y - a.y * b.x; }

fn validPolygon(p: []const Point) bool {
    for (0..p.len) |i| {
        const next = (i + 1) % p.len;
        if (p[i].x == p[next].x and p[i].y == p[next].y) return false;
        const edge = sub(p[next], p[i]);
        for (0..p.len) |j| {
            if (j != i and j != next and cross(edge, sub(p[j], p[i])) <= 0) return false;
        }
    }
    return true;
}

fn validQuery(p: []const Point, q: Point) bool {
    var outside = false;
    for (0..p.len) |i| {
        const side = cross(sub(p[(i + 1) % p.len], p[i]), sub(q, p[i]));
        if (side == 0) return false;
        if (side < 0) outside = true;
    }
    return outside;
}

fn buildChain(chain: *[MAX_VERTICES]usize, n: usize, start: usize, stop: usize) usize {
    var length: usize = 0;
    var at = start;
    while (true) {
        if (length >= n) return 0;
        chain[length] = at;
        length += 1;
        if (at == stop) return length;
        at = (at + 1) % n;
    }
}

fn buildLayers(p: []const Point, lower: *[MAX_VERTICES]usize,
               upper: *[MAX_VERTICES]usize) ?struct { lower_len: usize, upper_len: usize } {
    var min_x: usize = 0;
    var max_x: usize = 0;
    for (1..p.len) |i| {
        if (p[i].x < p[min_x].x) min_x = i;
        if (p[i].x > p[max_x].x) max_x = i;
    }
    var left_bottom = min_x;
    var left_top = min_x;
    var right_bottom = max_x;
    var right_top = max_x;
    for (0..p.len) |i| {
        if (p[i].x == p[min_x].x) {
            if (p[i].y < p[left_bottom].y) left_bottom = i;
            if (p[i].y > p[left_top].y) left_top = i;
        }
        if (p[i].x == p[max_x].x) {
            if (p[i].y < p[right_bottom].y) right_bottom = i;
            if (p[i].y > p[right_top].y) right_top = i;
        }
    }
    const lower_len = buildChain(lower, p.len, left_bottom, right_bottom);
    const upper_len = buildChain(upper, p.len, right_top, left_top);
    if (lower_len == 0 or upper_len == 0) return null;
    return .{ .lower_len = lower_len, .upper_len = upper_len };
}

fn splitAscending(p: []const Point, chain: []const usize, qx: i64) usize {
    var lo: usize = 0;
    var hi = chain.len;
    while (lo < hi) {
        const mid = lo + (hi - lo) / 2;
        if (p[chain[mid]].x < qx) lo = mid + 1 else hi = mid;
    }
    return if (lo == 0) 0 else lo - 1;
}

fn splitDescending(p: []const Point, chain: []const usize, qx: i64) usize {
    var lo: usize = 0;
    var hi = chain.len;
    while (lo < hi) {
        const mid = lo + (hi - lo) / 2;
        if (p[chain[mid]].x > qx) lo = mid + 1 else hi = mid;
    }
    return if (lo == 0) 0 else lo - 1;
}

fn tangentSearch(p: []const Point, chain: []const usize, first: usize, last: usize,
                 q: Point, sign: i64) usize {
    var lo: isize = @intCast(first);
    var hi: isize = @intCast(last);
    var result = lo;
    while (lo <= hi) {
        const mid = lo + @divTrunc(hi - lo, 2);
        const index = chain[@intCast(mid)];
        const here = sub(p[index], q);
        const to_next = sign * cross(here, sub(p[(index + 1) % p.len], q));
        const to_prev = sign * cross(here, sub(p[(index + p.len - 1) % p.len], q));
        if (to_next >= 0 and to_prev >= 0) return @intCast(mid);
        if (to_next >= 0) { result = mid; hi = mid - 1; } else { lo = mid + 1; }
    }
    return @intCast(result);
}

fn supports(p: []const Point, index: usize, q: Point, sign: i64) bool {
    const here = sub(p[index], q);
    return sign * cross(here, sub(p[(index + p.len - 1) % p.len], q)) > 0 and
        sign * cross(here, sub(p[(index + 1) % p.len], q)) > 0;
}

fn findTangents(p: []const Point, lower: []const usize, upper: []const usize, q: Point) ?Pair {
    const lower_len = lower.len;
    const upper_len = upper.len;
    const lower_split = splitAscending(p, lower, q.x);
    const upper_split = splitDescending(p, upper, q.x);
    const left_a = lower[tangentSearch(p, lower, 0, lower_split, q, -1)];
    const left_b = upper[tangentSearch(p, upper, 0, upper_split, q, -1)];
    const right_a = lower[tangentSearch(p, lower, lower_split, lower_len - 1, q, 1)];
    const right_b = upper[tangentSearch(p, upper, upper_split, upper_len - 1, q, 1)];
    const left: ?usize = if (supports(p, left_a, q, -1)) left_a else if (supports(p, left_b, q, -1)) left_b else null;
    const right: ?usize = if (supports(p, right_a, q, 1)) right_a else if (supports(p, right_b, q, 1)) right_b else null;
    if (left == null or right == null or left.? == right.?) return null;
    return .{ .first = @intCast(@min(left.?, right.?)), .second = @intCast(@max(left.?, right.?)) };
}

fn putI64(out: [*]u8, offset: *usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| { out[offset.*] = @truncate(bits >> @as(u6, @intCast(8 * b))); offset.* += 1; }
}

export fn external_point_tangents_convex_polygon(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 3 or input[0] > MAX_VERTICES or input[1] < 0 or input[1] > MAX_QUERIES) return -1;
    const n: usize = @intCast(input[0]);
    const q_count: usize = @intCast(input[1]);
    if (length != 2 + 2 * n + 2 * q_count) return -1;
    var polygon_storage: [MAX_VERTICES]Point = @splat(.{ .x = 0, .y = 0 });
    var query_points: [MAX_QUERIES]Point = @splat(.{ .x = 0, .y = 0 });
    var answers: [2 * MAX_QUERIES]i64 = @splat(0);
    var at: usize = 2;
    for (0..n) |i| {
        polygon_storage[i] = .{ .x = input[at], .y = input[at + 1] }; at += 2;
        if (polygon_storage[i].x < -MAX_COORDINATE or polygon_storage[i].x > MAX_COORDINATE or
            polygon_storage[i].y < -MAX_COORDINATE or polygon_storage[i].y > MAX_COORDINATE) return -1;
    }
    const polygon = polygon_storage[0..n];
    if (!validPolygon(polygon)) return -1;
    var lower_storage: [MAX_VERTICES]usize = @splat(0);
    var upper_storage: [MAX_VERTICES]usize = @splat(0);
    const layers = buildLayers(polygon, &lower_storage, &upper_storage) orelse return -1;
    const lower = lower_storage[0..layers.lower_len];
    const upper = upper_storage[0..layers.upper_len];
    for (0..q_count) |i| {
        query_points[i] = .{ .x = input[at], .y = input[at + 1] }; at += 2;
        if (query_points[i].x < -MAX_COORDINATE or query_points[i].x > MAX_COORDINATE or
            query_points[i].y < -MAX_COORDINATE or query_points[i].y > MAX_COORDINATE or
            !validQuery(polygon, query_points[i])) return -1;
        const pair = findTangents(polygon, lower, upper, query_points[i]) orelse return -1;
        answers[2 * i] = pair.first;
        answers[2 * i + 1] = pair.second;
    }
    const needed = 16 * q_count;
    if (needed > capacity or output_opt == null) return -2;
    const output = output_opt.?;
    var offset: usize = 0;
    for (0..2 * q_count) |i| putI64(output, &offset, answers[i]);
    return @intCast(needed);
}
