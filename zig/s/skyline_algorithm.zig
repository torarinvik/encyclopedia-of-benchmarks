const std = @import("std");
const MAX_POINTS: usize = 64;
const MAX_INPUT_LENGTH: usize = 130;
const MAX_OUTPUT_BYTES: usize = 513;

const Point = struct { x: i32, y: i32 };

fn dominates(left: Point, right: Point) bool {
    return (left.x < right.x and left.y <= right.y)
        or (left.x <= right.x and left.y < right.y);
}

fn produceSkyline(points: []const Point, output: []Point) usize {
    if (points.len == 1) {
        output[0] = points[0];
        return 1;
    }
    if (points.len == 2) {
        if (dominates(points[0], points[1])) {
            output[0] = points[0];
            return 1;
        }
        if (dominates(points[1], points[0])) {
            output[0] = points[1];
            return 1;
        }
        output[0] = points[0];
        output[1] = points[1];
        return 2;
    }

    const middle = points.len / 2;
    var left = [_]Point{.{ .x = 0, .y = 0 }} ** MAX_POINTS;
    var right = [_]Point{.{ .x = 0, .y = 0 }} ** MAX_POINTS;
    var left_count = produceSkyline(points[0..middle], &left);
    var right_count = produceSkyline(points[middle..], &right);

    var index: usize = 0;
    while (index + 1 < left_count) {
        if (left[index].x == left[index + 1].x and left[index].y > left[index + 1].y) {
            var move = index;
            while (move + 1 < left_count) : (move += 1) left[move] = left[move + 1];
            left_count -= 1;
            if (index > 0) index -= 1;
        } else {
            index += 1;
        }
    }

    var minimum_y = left[0].y;
    index = 1;
    while (index < left_count) : (index += 1) {
        if (minimum_y > left[index].y) {
            minimum_y = left[index].y;
            if (minimum_y == 1) break;
        }
    }

    index = 0;
    while (index < right_count) {
        if (right[index].y >= minimum_y) {
            var move = index;
            while (move + 1 < right_count) : (move += 1) right[move] = right[move + 1];
            right_count -= 1;
        } else {
            index += 1;
        }
    }
    @memcpy(output[0..left_count], left[0..left_count]);
    @memcpy(output[left_count .. left_count + right_count], right[0..right_count]);
    return left_count + right_count;
}

export fn skyline_algorithm(
    input: ?[*]const i64,
    input_length: usize,
    output: ?[*]u8,
    output_capacity: usize,
) i64 {
    const values = input orelse return -1;
    if (input_length < 1 or input_length > MAX_INPUT_LENGTH) return -1;
    const count_value = values[0];
    if (count_value < 1 or count_value > @as(i64, @intCast(MAX_POINTS))) return -1;
    const count: usize = @intCast(count_value);
    if (input_length != 1 + 2 * count) return -1;

    var points = [_]Point{.{ .x = 0, .y = 0 }} ** MAX_POINTS;
    for (0..count) |index| {
        const x = values[1 + 2 * index];
        const y = values[2 + 2 * index];
        if (x < @as(i64, std.math.minInt(i32)) or x > @as(i64, std.math.maxInt(i32))
            or y < 1 or y > @as(i64, std.math.maxInt(i32))) return -1;
        if (index > 0 and x <= values[1 + 2 * (index - 1)]) return -1;
        points[index] = .{ .x = @intCast(x), .y = @intCast(y) };
    }

    var skyline = [_]Point{.{ .x = 0, .y = 0 }} ** MAX_POINTS;
    const skyline_count = produceSkyline(points[0..count], &skyline);
    var staged = [_]u8{0} ** MAX_OUTPUT_BYTES;
    staged[0] = @intCast(skyline_count);
    for (skyline[0..skyline_count], 0..) |point, index| {
        const offset = 1 + 8 * index;
        const x_bits: u32 = @bitCast(point.x);
        const y_bits: u32 = @bitCast(point.y);
        for (0..4) |byte| {
            staged[offset + byte] = @truncate(x_bits >> @intCast(8 * byte));
            staged[offset + 4 + byte] = @truncate(y_bits >> @intCast(8 * byte));
        }
    }
    const written = 1 + 8 * skyline_count;
    const destination = output orelse return -2;
    if (output_capacity < written) return -2;
    @memcpy(destination[0..written], staged[0..written]);
    return @intCast(written);
}
