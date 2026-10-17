const std = @import("std");

const MAX_ANGLE: f64 = 1000.0;

export fn rotation_matrix(input: [*c]const f64, input_len: usize,
                          output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_len != 1) return -1;
    const theta = input[0];
    if (!std.math.isFinite(theta) or theta < -MAX_ANGLE or theta > MAX_ANGLE) return -1;
    const cosine = @cos(theta);
    const sine = @sin(theta);
    const matrix = [4]f64{ cosine, -sine, sine, cosine };
    if (output == null or output_capacity < matrix.len) return -2;
    for (matrix, 0..) |value, index| output[index] = value;
    return @intCast(matrix.len);
}
