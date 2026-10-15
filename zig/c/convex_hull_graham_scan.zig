const MAX_POINTS: usize = 1024;
const Point = struct { x: i64, y: i64, id: usize };

fn cross(a: Point, b: Point, c: Point) i64 {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}
fn radiusSquared(pivot: Point, point: Point) i64 {
    const dx = point.x - pivot.x;
    const dy = point.y - pivot.y;
    return dx * dx + dy * dy;
}
fn beforeX(left: usize, right: usize, points: []const Point) bool {
    if (points[left].x != points[right].x) return points[left].x < points[right].x;
    if (points[left].y != points[right].y) return points[left].y < points[right].y;
    return points[left].id < points[right].id;
}
fn beforeAngle(left: usize, right: usize, points: []const Point, pivot_index: usize) bool {
    const pivot = points[pivot_index];
    const turn = cross(pivot, points[left], points[right]);
    if (turn != 0) return turn > 0;
    const left_radius = radiusSquared(pivot, points[left]);
    const right_radius = radiusSquared(pivot, points[right]);
    if (left_radius != right_radius) return left_radius < right_radius;
    return points[left].id < points[right].id;
}
fn sortIndices(items: []usize, scratch: []usize, begin: usize, end: usize,
    points: []const Point, pivot_index: usize, by_angle: bool) void {
    if (end - begin < 2) return;
    const middle = begin + (end - begin) / 2;
    sortIndices(items, scratch, begin, middle, points, pivot_index, by_angle);
    sortIndices(items, scratch, middle, end, points, pivot_index, by_angle);
    var left = begin;
    var right = middle;
    var out = begin;
    while (left < middle and right < end) {
        const right_first = if (by_angle)
            beforeAngle(items[right], items[left], points, pivot_index)
        else
            beforeX(items[right], items[left], points);
        if (right_first) {
            scratch[out] = items[right];
            right += 1;
        } else {
            scratch[out] = items[left];
            left += 1;
        }
        out += 1;
    }
    while (left < middle) : (left += 1) { scratch[out] = items[left]; out += 1; }
    while (right < end) : (right += 1) { scratch[out] = items[right]; out += 1; }
    for (begin..end) |index| items[index] = scratch[index];
}
fn writeIndex(output: [*c]u8, position: usize, id: usize) void {
    const value: u32 = @intCast(id);
    for (0..4) |byte| output[4 * position + byte] = @truncate(value >> @intCast(8 * byte));
}

export fn convex_hull_graham_scan(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (length > 2 * MAX_POINTS or length % 2 != 0 or (length != 0 and values == null)) return -1;
    const count = length / 2;
    var input_points: [MAX_POINTS]Point = undefined;
    var points: [MAX_POINTS]Point = undefined;
    var order: [MAX_POINTS]usize = undefined;
    var scratch: [MAX_POINTS]usize = undefined;
    var hull: [MAX_POINTS]usize = undefined;
    for (0..count) |index| {
        const x = values[2 * index];
        const y = values[2 * index + 1];
        if (x < -1_000_000_000 or x > 1_000_000_000 or y < -1_000_000_000 or y > 1_000_000_000) return -1;
        input_points[index] = .{ .x = x, .y = y, .id = index };
        order[index] = index;
    }
    if (count == 0) return 0;
    const input_slice = input_points[0..count];
    const order_slice = order[0..count];
    const scratch_slice = scratch[0..count];
    sortIndices(order_slice, scratch_slice, 0, count, input_slice, 0, false);
    var unique_count: usize = 0;
    for (0..count) |index| {
        const point = input_slice[order_slice[index]];
        if (unique_count == 0 or points[unique_count - 1].x != point.x or points[unique_count - 1].y != point.y) {
            points[unique_count] = point;
            unique_count += 1;
        }
    }
    if (unique_count == 1) {
        if (output == null or output_capacity < 4) return -2;
        writeIndex(output, 0, points[0].id);
        return 1;
    }
    const points_slice = points[0..unique_count];
    var pivot: usize = 0;
    for (1..unique_count) |index| {
        if (points_slice[index].y < points_slice[pivot].y or
            (points_slice[index].y == points_slice[pivot].y and points_slice[index].x < points_slice[pivot].x)) pivot = index;
        order_slice[index] = index;
    }
    order_slice[0] = 0;
    sortIndices(order_slice, scratch[0..unique_count], 0, unique_count, points_slice, pivot, true);
    var all_collinear = true;
    for (2..unique_count) |index| {
        if (cross(points_slice[pivot], points_slice[order_slice[1]], points_slice[order_slice[index]]) != 0) all_collinear = false;
    }
    if (!all_collinear) {
        var ray_begin = unique_count - 1;
        while (ray_begin > 1 and cross(points_slice[pivot], points_slice[order_slice[ray_begin - 1]],
            points_slice[order_slice[unique_count - 1]]) == 0) : (ray_begin -= 1) {}
        var left = ray_begin;
        var right = unique_count - 1;
        while (left < right) {
            const temporary = order_slice[left];
            order_slice[left] = order_slice[right];
            order_slice[right] = temporary;
            left += 1;
            right -= 1;
        }
    }
    var hull_count: usize = 0;
    for (0..unique_count) |index| {
        const point = order_slice[index];
        while (hull_count >= 2 and cross(points_slice[hull[hull_count - 2]], points_slice[hull[hull_count - 1]], points_slice[point]) < 0)
            hull_count -= 1;
        hull[hull_count] = point;
        hull_count += 1;
    }
    if (output == null or output_capacity < 4 * hull_count) return -2;
    for (0..hull_count) |index| writeIndex(output, index, points_slice[hull[index]].id);
    return @intCast(hull_count);
}
