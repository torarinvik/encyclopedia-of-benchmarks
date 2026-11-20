const MAX_SAMPLES: usize = 32;
const MAX_ORDER: usize = 4;
const MAX_INPUT_WORDS: usize = 45;

export fn digital_filter_direct_form_ii_transposed(input_ptr: ?[*]const i64,
    length: usize, output_ptr: ?[*]u8, capacity: usize) i64 {
    if (input_ptr == null or length < 2 or length > MAX_INPUT_WORDS) return -1;
    const input = input_ptr.?[0..length];
    const count_word = input[0];
    const order_word = input[1];
    if (count_word < 0 or count_word > 32 or order_word < 0 or order_word > 4) return -1;
    const count: usize = @intCast(count_word);
    const order: usize = @intCast(order_word);
    if (length != count + 2 * order + 4) return -1;
    const a_start: usize = 2;
    const b_start = order + 3;
    const x_start = 2 * order + 4;
    if (input[a_start] != 1) return -1;
    for (1..order + 1) |index| {
        if (input[a_start + index] < -1 or input[a_start + index] > 1) return -1;
    }
    for (0..order + 1) |index| {
        if (input[b_start + index] < -1 or input[b_start + index] > 1) return -1;
    }
    for (input[x_start..]) |sample| {
        if (sample < -16 or sample > 16) return -1;
    }
    const bytes = count * 8;
    if (bytes > 0 and (output_ptr == null or capacity < bytes)) return -2;
    if (count == 0) return 0;
    const output = output_ptr.?[0..bytes];
    var state: [MAX_ORDER]i64 = @splat(0);
    for (0..count) |sample_index| {
        const sample = input[x_start + sample_index];
        const value = input[b_start] * sample + (if (order > 0) state[0] else 0);
        for (0..order) |stage| {
            const next_state: i64 = if (stage + 1 < order) state[stage + 1] else 0;
            state[stage] = next_state + input[b_start + stage + 1] * sample
                         - input[a_start + stage + 1] * value;
        }
        const bits: u64 = @bitCast(value);
        for (0..8) |byte_index| {
            output[sample_index * 8 + byte_index] = @truncate(bits >> (byte_index * 8));
        }
    }
    return @intCast(bytes);
}
