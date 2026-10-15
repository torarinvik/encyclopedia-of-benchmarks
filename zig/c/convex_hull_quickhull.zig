const MAX_POINTS: usize = 1024;
const Point = struct { x: i64, y: i64, id: usize };

fn before(a: Point, b: Point) bool {
    if (a.x != b.x) return a.x < b.x;
    if (a.y != b.y) return a.y < b.y;
    return a.id < b.id;
}
fn cross(a: Point, b: Point, c: Point) i64 {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
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
    while (left < middle) : (left += 1) { scratch[out] = points[left]; out += 1; }
    while (right < end) : (right += 1) { scratch[out] = points[right]; out += 1; }
    for (begin..end) |index| points[index] = scratch[index];
}
fn quickHull(points: []const Point, left: usize, right: usize, on_hull: []bool) void {
    var farthest: usize = MAX_POINTS;
    var greatest_area: i64 = 0;
    for (points, 0..) |point, index| {
        const area = cross(points[left], points[right], point);
        if (area > greatest_area) { greatest_area = area; farthest = index; }
    }
    if (farthest == MAX_POINTS) return;
    on_hull[farthest] = true;
    quickHull(points, left, farthest, on_hull);
    quickHull(points, farthest, right, on_hull);
}
fn writeIndex(output: [*c]u8, position: usize, id: usize) void {
    const value: u32 = @intCast(id);
    for (0..4) |byte| output[4 * position + byte] = @truncate(value >> @intCast(8 * byte));
}

export fn convex_hull_quickhull(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (length > 2 * MAX_POINTS or length % 2 != 0 or (length != 0 and values == null)) return -1;
    const input_count = length / 2;
    var points: [MAX_POINTS]Point = undefined;
    var scratch: [MAX_POINTS]Point = undefined;
    for (0..input_count) |index| {
        const x = values[2 * index];
        const y = values[2 * index + 1];
        if (x < -1_000_000_000 or x > 1_000_000_000 or y < -1_000_000_000 or y > 1_000_000_000) return -1;
        points[index] = .{ .x = x, .y = y, .id = index };
    }
    if (input_count == 0) return 0;
    const input_slice = points[0..input_count];
    sortPoints(input_slice, scratch[0..input_count], 0, input_count);
    var count: usize = 0;
    for (0..input_count) |index| {
        const point = points[index];
        if (count == 0 or points[count - 1].x != point.x or points[count - 1].y != point.y) {
            points[count] = point;
            count += 1;
        }
    }
    var on_hull: [MAX_POINTS]bool = undefined;
    for (0..count) |index| on_hull[index] = false;
    const unique_points = points[0..count];
    if (count == 1) {
        on_hull[0] = true;
    } else {
        on_hull[0] = true;
        on_hull[count - 1] = true;
        quickHull(unique_points, 0, count - 1, on_hull[0..count]);
        quickHull(unique_points, count - 1, 0, on_hull[0..count]);
    }
    var hull_count: usize = 0;
    for (0..count) |index| {
        if (on_hull[index]) hull_count += 1;
    }
    if (output == null or output_capacity < 4 * hull_count) return -2;
    var position: usize = 0;
    for (0..count) |index| {
        if (!on_hull[index]) continue;
        writeIndex(output, position, unique_points[index].id);
        position += 1;
    }
    return @intCast(hull_count);
}
