const MAX_VERTICES: usize = 16;
const MAX_PARSEABLE_LENGTH: usize = 38;

const Point = struct { x: i64, y: i64 };
const Vector = struct { x: i64, y: i64 };
const Hit = struct { edge: i64, numerator: i64, denominator: i64 };

fn polarHalf(v: Vector) u8 {
    return if (v.y > 0 or (v.y == 0 and v.x >= 0)) 0 else 1;
}
fn angleBefore(a: Vector, b: Vector) bool {
    const ah = polarHalf(a);
    const bh = polarHalf(b);
    if (ah != bh) return ah < bh;
    return a.x * b.y - a.y * b.x > 0;
}
fn rotationMinimum(edges: []const Vector) usize {
    var low: usize = 0;
    var high: usize = edges.len - 1;
    while (low < high) {
        const middle = (low + high) / 2;
        if (angleBefore(edges[middle], edges[high])) high = middle else low = middle + 1;
    }
    return low;
}
fn supportEdge(edges: []const Vector, target: Vector) usize {
    const count = edges.len;
    const pivot = rotationMinimum(edges);
    var low: usize = 0;
    var high = count;
    while (low < high) {
        const middle = (low + high) / 2;
        if (angleBefore(edges[(pivot + middle) % count], target)) low = middle + 1 else high = middle;
    }
    return (pivot + low) % count;
}
fn lineValue(point: Point, origin: Point, direction: Vector) i64 {
    return direction.x * (point.y - origin.y) - direction.y * (point.x - origin.x);
}
fn lineParameter(point: Point, origin: Point, direction: Vector) i64 {
    return (point.x - origin.x) * direction.x + (point.y - origin.y) * direction.y;
}
fn crossing(points: []const Point, origin: Point, direction: Vector,
            start: usize, finish: usize, increasing: bool) Hit {
    const count = points.len;
    const span = (finish + count - start) % count;
    var low: usize = 0;
    var high = span;
    while (high - low > 1) {
        const middle = (low + high) / 2;
        const value = lineValue(points[(start + middle) % count], origin, direction);
        if ((increasing and value < 0) or (!increasing and value > 0)) low = middle else high = middle;
    }
    var index = (start + low) % count;
    if (lineValue(points[(start + high) % count], origin, direction) == 0) index = (start + high) % count;
    const value = lineValue(points[index], origin, direction);
    if (value == 0) return .{
        .edge = @intCast(index),
        .numerator = lineParameter(points[index], origin, direction),
        .denominator = 1,
    };
    const next = (index + 1) % count;
    const next_value = lineValue(points[next], origin, direction);
    var denominator = value - next_value;
    const edge_dot = (points[next].x - points[index].x) * direction.x +
        (points[next].y - points[index].y) * direction.y;
    var numerator = lineParameter(points[index], origin, direction) * denominator + value * edge_dot;
    if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
    return .{ .edge = @intCast(index), .numerator = numerator, .denominator = denominator };
}
fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn line_hull_intersection(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = input_opt.?;
    const count_value = input[0];
    if (count_value < 3 or count_value > MAX_VERTICES) return -1;
    const count: usize = @intCast(count_value);
    if (length != 5 + 2 * count) return -1;
    const origin = Point{ .x = input[1], .y = input[2] };
    const line_end = Point{ .x = input[3], .y = input[4] };
    if (origin.x < -50 or origin.x > 50 or origin.y < -50 or origin.y > 50 or
        line_end.x < -50 or line_end.x > 50 or line_end.y < -50 or line_end.y > 50) return -1;
    const direction = Vector{ .x = line_end.x - origin.x, .y = line_end.y - origin.y };
    if (direction.x == 0 and direction.y == 0) return -1;

    var points: [MAX_VERTICES]Point = undefined;
    var edges: [MAX_VERTICES]Vector = undefined;
    for (0..count) |i| {
        points[i] = .{ .x = input[5 + 2 * i], .y = input[6 + 2 * i] };
        if (points[i].x < -50 or points[i].x > 50 or points[i].y < -50 or points[i].y > 50) return -1;
        for (0..i) |j| if (points[j].x == points[i].x and points[j].y == points[i].y) { return -1; };
    }
    var area2: i64 = 0;
    for (0..count) |i| {
        const next = (i + 1) % count;
        edges[i] = .{ .x = points[next].x - points[i].x, .y = points[next].y - points[i].y };
        area2 += points[i].x * points[next].y - points[next].x * points[i].y;
    }
    if (area2 <= 0) return -1;
    for (0..count) |i| {
        const next = (i + 1) % count;
        for (0..count) |j| {
            if (j == i or j == next) continue;
            const side = edges[i].x * (points[j].y - points[i].y) - edges[i].y * (points[j].x - points[i].x);
            if (side <= 0) return -1;
        }
    }

    const maximum = supportEdge(edges[0..count], .{ .x = -direction.x, .y = -direction.y });
    const minimum = supportEdge(edges[0..count], direction);
    const max_value = lineValue(points[maximum], origin, direction);
    const min_value = lineValue(points[minimum], origin, direction);
    var first: i64 = -1;
    var second: i64 = -1;
    if (min_value > 0 or max_value < 0) {
        first = -1;
        second = -1;
    } else if (min_value == 0 or max_value == 0) {
        const touch = if (min_value == 0) minimum else maximum;
        const next = (touch + 1) % count;
        const previous = (touch + count - 1) % count;
        if (lineValue(points[touch], origin, direction) == 0 and lineValue(points[next], origin, direction) == 0) {
            first = @intCast(touch); second = @intCast(touch);
        } else if (lineValue(points[previous], origin, direction) == 0 and lineValue(points[touch], origin, direction) == 0) {
            first = @intCast(previous); second = @intCast(previous);
        } else {
            first = @intCast(touch); second = -1;
        }
    } else {
        const a = crossing(points[0..count], origin, direction, maximum, minimum, false);
        const b = crossing(points[0..count], origin, direction, minimum, maximum, true);
        if (a.numerator * b.denominator <= b.numerator * a.denominator) {
            first = a.edge; second = b.edge;
        } else {
            first = b.edge; second = a.edge;
        }
    }
    if (output_opt == null or capacity < 16) return -2;
    const output = output_opt.?;
    storeI64Le(output, 0, first);
    storeI64Le(output, 8, second);
    return 16;
}
