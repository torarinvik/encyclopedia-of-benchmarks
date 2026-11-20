const std = @import("std");

const COMPONENT_LIMIT: f64 = 1_000_000.0;
const ANGLE_LIMIT: f64 = 6.283185307179586;
const OUTPUT_LIMIT: f64 = 2_000_000.0;

export fn rodrigues_arbitrary_axis_rotation(input: ?[*]const f64, input_len: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_len != 7) return -1;
    for (0..6) |i| {
        if (!std.math.isFinite(values[i]) or @abs(values[i]) > COMPONENT_LIMIT) return -1;
    }
    const theta = values[6];
    if (!std.math.isFinite(theta) or @abs(theta) > ANGLE_LIMIT) return -1;
    const scale = @max(@abs(values[0]), @max(@abs(values[1]), @abs(values[2])));
    if (scale == 0.0) return -1;
    const qx = values[0] / scale;
    const qy = values[1] / scale;
    const qz = values[2] / scale;
    const norm = @sqrt((qx * qx + qy * qy) + qz * qz);
    if (!std.math.isFinite(norm) or norm == 0.0) return -1;
    const nx = qx / norm;
    const ny = qy / norm;
    const nz = qz / norm;
    const vx = values[3];
    const vy = values[4];
    const vz = values[5];
    const cosine = @cos(theta);
    const sine = @sin(theta);
    const one_minus_cosine = 1.0 - cosine;
    const cx = ny * vz - nz * vy;
    const cy = nz * vx - nx * vz;
    const cz = nx * vy - ny * vx;
    const dot = (nx * vx + ny * vy) + nz * vz;
    const result = [_]f64{
        (vx * cosine + cx * sine) + (nx * dot) * one_minus_cosine,
        (vy * cosine + cy * sine) + (ny * dot) * one_minus_cosine,
        (vz * cosine + cz * sine) + (nz * dot) * one_minus_cosine,
    };
    for (result) |value| {
        if (!std.math.isFinite(value) or @abs(value) > OUTPUT_LIMIT) return -1;
    }
    const destination = output orelse return -2;
    if (output_capacity < 3) return -2;
    for (0..3) |i| destination[i] = result[i];
    return 3;
}
