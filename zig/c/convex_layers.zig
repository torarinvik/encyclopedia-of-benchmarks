const MAX_POINTS: usize = 64;
const COORD_LIMIT: i64 = 1_000_000;

const Point = struct { x: i64, y: i64 };

fn cross(a: Point, b: Point, c: Point) i64 {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

fn before(a: Point, b: Point) bool {
    return a.x < b.x or (a.x == b.x and a.y < b.y);
}

fn onSegment(point: Point, a: Point, b: Point) bool {
    return cross(a, b, point) == 0 and @min(a.x, b.x) <= point.x and point.x <= @max(a.x, b.x) and
        @min(a.y, b.y) <= point.y and point.y <= @max(a.y, b.y);
}

export fn convex_layers(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > 1 + 2 * MAX_POINTS) return -1;
    const input = input_opt.?;
    const count_value = input[0];
    if (count_value < 0 or count_value > @as(i64, @intCast(MAX_POINTS)) or
        length != 1 + 2 * @as(usize, @intCast(count_value))) return -1;
    var points: [MAX_POINTS]Point = undefined;
    var count: usize = 0;
    for (0..@as(usize, @intCast(count_value))) |index| {
        const x = input[1 + 2 * index];
        const y = input[2 + 2 * index];
        if (x < -COORD_LIMIT or x > COORD_LIMIT or y < -COORD_LIMIT or y > COORD_LIMIT) return -1;
        var duplicate = false;
        for (0..count) |old| {
            if (points[old].x == x and points[old].y == y) duplicate = true;
        }
        if (!duplicate) {
            points[count] = .{ .x = x, .y = y };
            count += 1;
        }
    }

    var layers: i64 = 0;
    while (count > 0) {
        for (1..count) |index| {
            const key = points[index];
            var position = index;
            while (position > 0 and before(key, points[position - 1])) : (position -= 1) {
                points[position] = points[position - 1];
            }
            points[position] = key;
        }

        var hull: [2 * MAX_POINTS]Point = undefined;
        var hull_count: usize = 0;
        for (0..count) |index| {
            while (hull_count >= 2 and cross(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0)
                hull_count -= 1;
            hull[hull_count] = points[index];
            hull_count += 1;
        }
        const lower_count = hull_count;
        var cursor = count - 1;
        while (cursor > 0) : (cursor -= 1) {
            const point = points[cursor - 1];
            while (hull_count > lower_count and
                cross(hull[hull_count - 2], hull[hull_count - 1], point) <= 0) hull_count -= 1;
            hull[hull_count] = point;
            hull_count += 1;
        }
        if (hull_count > 1) hull_count -= 1;
        var boundary: [MAX_POINTS]bool = undefined;
        for (0..count) |index| boundary[index] = false;
        if (hull_count <= 2) {
            for (0..count) |index| boundary[index] = true;
        } else {
            for (0..count) |index| {
                for (0..hull_count) |edge| {
                    if (onSegment(points[index], hull[edge], hull[(edge + 1) % hull_count])) {
                        boundary[index] = true;
                        break;
                    }
                }
            }
        }
        var kept: usize = 0;
        for (0..count) |index| {
            if (!boundary[index]) {
                points[kept] = points[index];
                kept += 1;
            }
        }
        if (kept == count) return -1;
        count = kept;
        layers += 1;
    }
    return layers;
}
