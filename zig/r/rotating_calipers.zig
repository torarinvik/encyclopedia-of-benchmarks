const MAX_POINTS: usize = 1024;
const MAX_COORDINATE: i64 = 1_000_000_000;
const INVALID_RESULT: f64 = -1.0e300;

const Point = struct { x: i64, y: i64 };

fn before(a: Point, b: Point) bool {
    return a.x < b.x or (a.x == b.x and a.y < b.y);
}

fn cross(origin: Point, a: Point, b: Point) i64 {
    return (a.x - origin.x) * (b.y - origin.y) - (a.y - origin.y) * (b.x - origin.x);
}

fn distanceSquared(a: Point, b: Point) i64 {
    const dx = a.x - b.x;
    const dy = a.y - b.y;
    return dx * dx + dy * dy;
}

fn sortPoints(points: []Point, scratch: []Point, begin: usize, end: usize) void {
    if (end - begin < 2) return;
    const middle = begin + (end - begin) / 2;
    sortPoints(points, scratch, begin, middle);
    sortPoints(points, scratch, middle, end);
    var left = begin;
    var right = middle;
    var out = begin;
    while (left < middle and right < end) {
        if (before(points[right], points[left])) {
            scratch[out] = points[right];
            right += 1;
        } else {
            scratch[out] = points[left];
            left += 1;
        }
        out += 1;
    }
    while (left < middle) : (left += 1) {
        scratch[out] = points[left];
        out += 1;
    }
    while (right < end) : (right += 1) {
        scratch[out] = points[right];
        out += 1;
    }
    @memcpy(points[begin..end], scratch[begin..end]);
}

export fn rotating_calipers(values: [*]const i64, length: usize) f64 {
    if (length < 5 or length > 2 * MAX_POINTS + 1 or length % 2 == 0) return INVALID_RESULT;
    const count_value = values[0];
    if (count_value < 2 or count_value > MAX_POINTS or length != 1 + 2 * @as(usize, @intCast(count_value)))
        return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    var points_buffer: [MAX_POINTS]Point = undefined;
    var scratch_buffer: [MAX_POINTS]Point = undefined;
    for (0..count) |index| {
        const x = values[1 + 2 * index];
        const y = values[2 + 2 * index];
        if (x < -MAX_COORDINATE or x > MAX_COORDINATE or y < -MAX_COORDINATE or y > MAX_COORDINATE)
            return INVALID_RESULT;
        points_buffer[index] = .{ .x = x, .y = y };
    }
    var points = points_buffer[0..count];
    sortPoints(points, scratch_buffer[0..count], 0, count);
    var unique_count: usize = 0;
    for (0..count) |index| {
        if (unique_count == 0 or points[index].x != points[unique_count - 1].x or points[index].y != points[unique_count - 1].y) {
            points[unique_count] = points[index];
            unique_count += 1;
        }
    }
    points = points[0..unique_count];
    if (unique_count == 1) return 0.0;

    var lower_buffer: [MAX_POINTS]Point = undefined;
    var upper_buffer: [MAX_POINTS]Point = undefined;
    var lower = lower_buffer[0..0];
    for (points) |point| {
        while (lower.len >= 2 and cross(lower[lower.len - 2], lower[lower.len - 1], point) <= 0)
            lower = lower[0 .. lower.len - 1];
        lower_buffer[lower.len] = point;
        lower = lower_buffer[0 .. lower.len + 1];
    }
    var upper = upper_buffer[0..0];
    var index = unique_count;
    while (index > 0) {
        index -= 1;
        const point = points[index];
        while (upper.len >= 2 and cross(upper[upper.len - 2], upper[upper.len - 1], point) <= 0)
            upper = upper[0 .. upper.len - 1];
        upper_buffer[upper.len] = point;
        upper = upper_buffer[0 .. upper.len + 1];
    }
    var hull_buffer: [2 * MAX_POINTS]Point = undefined;
    var hull_count: usize = 0;
    for (lower[0 .. lower.len - 1]) |point| {
        hull_buffer[hull_count] = point;
        hull_count += 1;
    }
    for (upper[0 .. upper.len - 1]) |point| {
        hull_buffer[hull_count] = point;
        hull_count += 1;
    }
    const hull = hull_buffer[0..hull_count];
    if (hull_count == 2) return @sqrt(@as(f64, @floatFromInt(distanceSquared(hull[0], hull[1]))));

    var antipodal: usize = 1;
    var advances: usize = 0;
    while (advances < hull_count and cross(hull[0], hull[1], hull[(antipodal + 1) % hull_count]) >
        cross(hull[0], hull[1], hull[antipodal])) : (advances += 1) {
        antipodal = (antipodal + 1) % hull_count;
    }
    var maximum_squared: i64 = 0;
    for (0..hull_count) |current| {
        const next = (current + 1) % hull_count;
        advances = 0;
        while (advances < hull_count and cross(hull[current], hull[next], hull[(antipodal + 1) % hull_count]) >
            cross(hull[current], hull[next], hull[antipodal])) : (advances += 1) {
            antipodal = (antipodal + 1) % hull_count;
        }
        const after = (antipodal + 1) % hull_count;
        maximum_squared = @max(maximum_squared, distanceSquared(hull[current], hull[antipodal]));
        maximum_squared = @max(maximum_squared, distanceSquared(hull[next], hull[antipodal]));
        maximum_squared = @max(maximum_squared, distanceSquared(hull[current], hull[after]));
        maximum_squared = @max(maximum_squared, distanceSquared(hull[next], hull[after]));
    }
    return @sqrt(@as(f64, @floatFromInt(maximum_squared)));
}
