const std = @import("std");

const component_limit: f64 = 1_000_000.0;
const epsilon: f64 = 1.0e-9;

fn dotProduct(ax: f32, ay: f32, az: f32, bx: f32, by: f32, bz: f32) f32 {
    var dot = ax * bx;
    dot += ay * by;
    dot += az * bz;
    return dot;
}

fn vectorNorm(x: f32, y: f32, z: f32) f32 {
    return @sqrt(dotProduct(x, y, z, x, y, z));
}

export fn vectors_3d(input: [*c]const f64, input_len: usize,
                     output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_len == 0) return -1;
    const operation_value = input[0];
    if (!std.math.isFinite(operation_value) or operation_value < 0.0 or operation_value > 7.0 or
        @floor(operation_value) != operation_value) return -1;
    const operation: usize = @intFromFloat(operation_value);
    const required_length: usize = if (operation <= 3 or operation == 7) 7 else 4;
    if (input_len != required_length) return -1;

    var components: [6]f32 = @splat(0.0);
    const component_count = required_length - 1;
    for (0..component_count) |index| {
        const value = input[index + 1];
        if (!std.math.isFinite(value) or @abs(value) > component_limit) return -1;
        components[index] = @floatCast(value);
    }
    const ax, const ay, const az = .{ components[0], components[1], components[2] };
    const bx, const by, const bz = .{ components[3], components[4], components[5] };
    var result: [9]f64 = @splat(0.0);
    var result_length: usize = 0;
    switch (operation) {
        0 => {
            result_length = 3;
            result[0] = @floatCast(ax + bx);
            result[1] = @floatCast(ay + by);
            result[2] = @floatCast(az + bz);
        },
        1 => {
            result_length = 3;
            result[0] = @floatCast(ax - bx);
            result[1] = @floatCast(ay - by);
            result[2] = @floatCast(az - bz);
        },
        2 => {
            result_length = 1;
            result[0] = @floatCast(dotProduct(ax, ay, az, bx, by, bz));
        },
        3 => {
            result_length = 3;
            result[0] = @floatCast(ay * bz - az * by);
            result[1] = @floatCast(-ax * bz + az * bx);
            result[2] = @floatCast(ax * by - ay * bx);
        },
        4 => {
            result_length = 1;
            result[0] = @floatCast(vectorNorm(ax, ay, az));
        },
        5 => {
            result_length = 3;
            const norm = vectorNorm(ax, ay, az);
            if (@as(f64, norm) >= epsilon and norm != 1.0) {
                result[0] = @floatCast(ax / norm);
                result[1] = @floatCast(ay / norm);
                result[2] = @floatCast(az / norm);
            }
        },
        6 => {
            result_length = 9;
            result = .{ 0.0, @floatCast(-az), @floatCast(ay), @floatCast(az), 0.0,
                        @floatCast(-ax), @floatCast(-ay), @floatCast(ax), 0.0 };
        },
        7 => {
            result_length = 1;
            const norm_a = vectorNorm(ax, ay, az);
            const norm_b = vectorNorm(bx, by, bz);
            if (@as(f64, norm_a) < epsilon or @as(f64, norm_b) < epsilon) {
                result[0] = @acos(@as(f64, 2.0));
            } else {
                const cosine = dotProduct(ax, ay, az, bx, by, bz) / (norm_a * norm_b);
                result[0] = @acos(@as(f64, cosine));
            }
        },
        else => return -1,
    }

    if (output == null or output_capacity < result_length) return -2;
    for (0..result_length) |index| output[index] = result[index];
    return @intCast(result_length);
}
