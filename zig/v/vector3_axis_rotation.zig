const std = @import("std");

const COORDINATE_LIMIT: f64 = 1_000_000.0;
const ANGLE_LIMIT: f64 = 1_000_000.0;
const OUTPUT_LIMIT: f64 = 2_000_000.0;
const PI: f64 = 3.14159265358979323846;

export fn vector3_axis_rotation(input: [*c]const f64, input_len: usize,
                                output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_len != 5) return -1;
    for (0..3) |i| {
        if (!std.math.isFinite(input[i]) or @abs(input[i]) > COORDINATE_LIMIT) return -1;
    }
    const axis = input[3];
    var angle = input[4];
    if (!std.math.isFinite(axis) or (axis != 0.0 and axis != 1.0 and axis != 2.0) or
        !std.math.isFinite(angle) or @abs(angle) > ANGLE_LIMIT) return -1;
    angle -= @floor(angle / 360.0) * 360.0;
    if (angle == 0.0) angle = 0.0;
    angle = angle / 450.0 * 180.0 / PI;
    const x = input[0];
    const y = input[1];
    const z = input[2];
    const cosine = @cos(angle);
    const sine = @sin(angle);
    var result: [3]f64 = undefined;
    if (axis == 0.0) {
        result = .{ x, y * cosine - z * sine, z * cosine + y * sine };
    } else if (axis == 1.0) {
        result = .{ x * cosine - z * sine, y, z * cosine + x * sine };
    } else {
        result = .{ x * cosine - y * sine, y * cosine + x * sine, z };
    }
    for (result) |value| {
        if (!std.math.isFinite(value) or @abs(value) > OUTPUT_LIMIT) return -1;
    }
    if (output == null or output_capacity < 3) return -2;
    for (0..3) |i| output[i] = result[i];
    return 3;
}
