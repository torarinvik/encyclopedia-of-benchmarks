const MAX_SUPPORT_LENGTH: usize = 4;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 20;
const MAX_OUTPUT_ELEMENTS: usize = 48;

export fn joint_probability_distribution(input: [*c]const f64, input_len: usize,
                                         output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_len < 2 or input_len > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const nx_value = input[0];
    const ny_value = input[1];
    if (!std.math.isFinite(nx_value) or !std.math.isFinite(ny_value)
        or nx_value < 1.0 or nx_value > @as(f64, @floatFromInt(MAX_SUPPORT_LENGTH))
        or ny_value < 1.0 or ny_value > @as(f64, @floatFromInt(MAX_SUPPORT_LENGTH))
        or @trunc(nx_value) != nx_value or @trunc(ny_value) != ny_value) return -1;
    const nx: usize = @intFromFloat(nx_value);
    const ny: usize = @intFromFloat(ny_value);
    if (input_len != 2 + 2 * nx + 2 * ny) return -1;

    const x_start: usize = 2;
    const y_start = x_start + nx;
    const x_probability_start = y_start + ny;
    const y_probability_start = x_probability_start + nx;
    var x_values: [MAX_SUPPORT_LENGTH]i64 = undefined;
    var y_values: [MAX_SUPPORT_LENGTH]i64 = undefined;
    var x_probabilities: [MAX_SUPPORT_LENGTH]f64 = undefined;
    var y_probabilities: [MAX_SUPPORT_LENGTH]f64 = undefined;

    for (0..nx) |index| {
        const raw = input[x_start + index];
        if (!std.math.isFinite(raw) or raw < -1000.0 or raw > 1000.0 or @trunc(raw) != raw) return -1;
        x_values[index] = @intFromFloat(raw);
        const probability = input[x_probability_start + index];
        if (!std.math.isFinite(probability) or probability < -1_000_000.0 or probability > 1_000_000.0) return -1;
        x_probabilities[index] = probability;
        for (0..index) |previous| if (x_values[previous] == x_values[index]) return -1;
    }
    for (0..ny) |index| {
        const raw = input[y_start + index];
        if (!std.math.isFinite(raw) or raw < -1000.0 or raw > 1000.0 or @trunc(raw) != raw) return -1;
        y_values[index] = @intFromFloat(raw);
        const probability = input[y_probability_start + index];
        if (!std.math.isFinite(probability) or probability < -1_000_000.0 or probability > 1_000_000.0) return -1;
        y_probabilities[index] = probability;
        for (0..index) |previous| if (y_values[previous] == y_values[index]) return -1;
    }

    const required = 3 * nx * ny;
    if (required > MAX_OUTPUT_ELEMENTS) return -1;
    if (output == null or output_capacity < required) return -2;
    for (0..nx) |x_index| {
        for (0..ny) |y_index| {
            const position = 3 * (x_index * ny + y_index);
            output[position] = @floatFromInt(x_values[x_index]);
            output[position + 1] = @floatFromInt(y_values[y_index]);
            output[position + 2] = x_probabilities[x_index] * y_probabilities[y_index];
        }
    }
    return @intCast(required);
}
