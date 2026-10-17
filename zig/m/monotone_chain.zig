const MAX_POINT_COUNT: usize = 64;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 130;
const MAX_COORDINATE: i64 = 1_000_000;

const Point = struct { x: i64, y: i64 };

fn pointLess(a: Point, b: Point) bool {
    return a.x < b.x or (a.x == b.x and a.y < b.y);
}

fn crossProduct(origin: Point, first: Point, second: Point) i64 {
    const dx1 = first.x - origin.x;
    const dy1 = first.y - origin.y;
    const dx2 = second.x - origin.x;
    const dy2 = second.y - origin.y;
    return dx1 * dy2 - dy1 * dx2;
}

fn sortPoints(points: []Point, scratch: []Point) void {
    const count = points.len;
    var width: usize = 1;
    while (width < count) : (width *= 2) {
        var start: usize = 0;
        while (start < count) : (start += 2 * width) {
            const middle = @min(start + width, count);
            const end = @min(middle + width, count);
            var left = start;
            var right = middle;
            var destination = start;
            while (left < middle and right < end) {
                if (pointLess(points[right], points[left])) {
                    scratch[destination] = points[right];
                    right += 1;
                } else {
                    scratch[destination] = points[left];
                    left += 1;
                }
                destination += 1;
            }
            while (left < middle) : (left += 1) {
                scratch[destination] = points[left];
                destination += 1;
            }
            while (right < end) : (right += 1) {
                scratch[destination] = points[right];
                destination += 1;
            }
        }
        @memcpy(points, scratch);
    }
}

fn storeI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
}

/// Bounded Andrew monotone-chain convex hull.
export fn monotone_chain(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const raw_count = values[0];
    if (raw_count < 0 or raw_count > MAX_POINT_COUNT) return -1;
    const count: usize = @intCast(raw_count);
    if (length != 1 + 2 * count) return -1;

    var points: [MAX_POINT_COUNT]Point = undefined;
    var scratch: [MAX_POINT_COUNT]Point = undefined;
    var hull: [2 * MAX_POINT_COUNT]Point = undefined;
    for (0..count) |index| {
        const x = values[1 + 2 * index];
        const y = values[2 + 2 * index];
        if (x < -MAX_COORDINATE or x > MAX_COORDINATE or y < -MAX_COORDINATE or y > MAX_COORDINATE) return -1;
        points[index] = .{ .x = x, .y = y };
    }

    sortPoints(points[0..count], scratch[0..count]);
    var unique_count: usize = 0;
    for (0..count) |index| {
        if (unique_count == 0 or points[index].x != points[unique_count - 1].x or
            points[index].y != points[unique_count - 1].y) {
            points[unique_count] = points[index];
            unique_count += 1;
        }
    }

    var hull_count: usize = 0;
    if (unique_count == 1) {
        hull[hull_count] = points[0];
        hull_count += 1;
    } else if (unique_count > 1) {
        for (0..unique_count) |index| {
            while (hull_count >= 2 and
                crossProduct(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0)
                hull_count -= 1;
            hull[hull_count] = points[index];
            hull_count += 1;
        }
        const lower_count = hull_count;
        var index = unique_count - 1;
        while (index > 0) {
            index -= 1;
            while (hull_count > lower_count and
                crossProduct(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0)
                hull_count -= 1;
            hull[hull_count] = points[index];
            hull_count += 1;
        }
        hull_count -= 1;
    }

    const byte_count = 8 * hull_count;
    if (output == null or output_capacity < byte_count) return -2;
    for (0..hull_count) |index| {
        storeI32Le(output, 8 * index, @intCast(hull[index].x));
        storeI32Le(output, 8 * index + 4, @intCast(hull[index].y));
    }
    return @intCast(byte_count);
}
