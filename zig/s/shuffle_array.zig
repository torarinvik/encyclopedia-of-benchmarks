const MAX_N: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 67;
const MAX_OUTPUT_BYTES: usize = 520;
const I32_MIN: i64 = -2_147_483_648;
const I32_MAX: i64 = 2_147_483_647;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn shuffle_array(input: [*c]const i64, input_length: usize,
                        output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const variant = input[0];
    const n_value = input[1];
    if ((variant != 0 and variant != 1) or n_value < 0 or n_value > MAX_N) return -1;
    const n: usize = @intCast(n_value);
    const value_count = if (variant == 0) n else 2 * n;
    const draw_count = if (variant == 0 and n > 0) n - 1 else 0;
    if (input_length != 2 + value_count + draw_count) return -1;

    var result_values: [2 * MAX_N]i64 = @splat(0);
    const result_count = value_count;
    for (0..value_count) |index| {
        const value = input[2 + index];
        if (value < I32_MIN or value > I32_MAX) return -1;
        result_values[index] = value;
    }

    if (variant == 0) {
        for (0..draw_count) |draw_index| {
            const current_index = n - 1 - draw_index;
            const chosen_value = input[2 + n + draw_index];
            if (chosen_value < 0 or chosen_value > current_index) return -1;
            const chosen_index: usize = @intCast(chosen_value);
            const temporary = result_values[current_index];
            result_values[current_index] = result_values[chosen_index];
            result_values[chosen_index] = temporary;
        }
    } else {
        for (0..n) |index| {
            result_values[2 * index] = input[2 + index];
            result_values[2 * index + 1] = input[2 + n + index];
        }
    }

    const output_bytes = 8 * (result_count + 1);
    if (output_bytes > MAX_OUTPUT_BYTES or output == null or output_capacity < output_bytes) return -2;
    storeI64Le(output, 0, @intCast(result_count));
    for (0..result_count) |index| storeI64Le(output, 8 * (index + 1), result_values[index]);
    return @intCast(output_bytes);
}
