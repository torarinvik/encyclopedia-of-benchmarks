const std = @import("std");

export fn vector2(values: [*c]const f64, length: usize, output: [*c]f64, capacity: usize) i64 {
    if (values == null or length != 6) return -1;
    for (0..6) |i| if (!std.math.isFinite(values[i])) return -1;
    if (values[0] < 0.0 or values[0] > 10.0 or @floor(values[0]) != values[0]) return -1;
    for (1..5) |i| if (values[i] < -1000.0 or values[i] > 1000.0) return -1;

    const op: usize = @intFromFloat(values[0]);
    const ax = values[1];
    const ay = values[2];
    const bx = values[3];
    const by = values[4];
    const scalar = values[5];
    if (op == 1) {
        if (scalar < 0.0 or scalar > 2000.0) return -1;
    } else if (op == 6) {
        if (bx != 0.0 or by != 0.0 or scalar < -1000.0 or scalar > 1000.0) return -1;
    } else if (op == 9) {
        if (bx != 0.0 or by != 0.0 or scalar < -6.283185307179586 or scalar > 6.283185307179586) return -1;
    } else if (scalar != 0.0) return -1;
    if ((op == 2 or op == 3) and (bx != 0.0 or by != 0.0)) return -1;

    var result = [2]f64{ 0.0, 0.0 };
    var result_length: usize = 1;
    switch (op) {
        0 => result[0] = if (ax == bx and ay == by) 1.0 else 0.0,
        1 => result[0] = if (@abs(ax - bx) < scalar and @abs(ay - by) < scalar) 1.0 else 0.0,
        2 => result[0] = @sqrt(ax * ax + ay * ay),
        3 => {
            const magnitude = @sqrt(ax * ax + ay * ay);
            if (magnitude == 0.0) return -1;
            result_length = 2;
            result[0] = ax / magnitude;
            result[1] = ay / magnitude;
        },
        4 => {
            result_length = 2;
            result[0] = ax + bx;
            result[1] = ay + by;
        },
        5 => {
            result_length = 2;
            result[0] = ax - bx;
            result[1] = ay - by;
        },
        6 => {
            result_length = 2;
            result[0] = ax * scalar;
            result[1] = ay * scalar;
        },
        7 => {
            const dx = bx - ax;
            const dy = by - ay;
            result[0] = @sqrt(dx * dx + dy * dy);
        },
        8 => result[0] = ax * bx + ay * by,
        9 => {
            const cosine = @cos(scalar);
            const sine = @sin(scalar);
            result_length = 2;
            result[0] = cosine * ax - sine * ay;
            result[1] = sine * ax + cosine * ay;
        },
        10 => result[0] = @atan2(by, bx) - @atan2(ay, ax),
        else => return -1,
    }

    if (output == null or capacity < result_length) return -2;
    for (0..result_length) |i| output[i] = result[i];
    return @intCast(result_length);
}
