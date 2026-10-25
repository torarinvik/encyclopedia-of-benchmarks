const MAX_N: usize = 16;
const MAX_INPUT_LENGTH: usize = 2 + 5 * MAX_N;
const MAX_OPERAND: i64 = 1_000_000;

fn boundedOperand(value: i64) bool {
    return value >= -MAX_OPERAND and value <= MAX_OPERAND;
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_indexed_gather_scatter(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 6 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const mode = values[0];
    const n_raw = values[1];
    if ((mode != 491 and mode != 4113) or n_raw < 1 or n_raw > MAX_N) return -1;
    const n: usize = @intCast(n_raw);
    const arrays_per_index: usize = if (mode == 491) 5 else 4;
    if (length != 2 + arrays_per_index * n) return -1;

    const index_start = 2;
    const a_start = index_start + n;
    const b_start = a_start + n;
    const c_start = b_start + n;
    const d_start = c_start + n;
    var state = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        const index = values[index_start + i];
        if (index < 0 or index >= n_raw) return -1;
        state[i] = values[a_start + i];
        if (!boundedOperand(values[b_start + i]) or !boundedOperand(values[c_start + i])) return -1;
        if (mode == 491 and !boundedOperand(values[d_start + i])) return -1;
    }
    if (output == null or output_capacity < 8 * n) return -2;

    for (0..n) |i| {
        const index: usize = @intCast(values[index_start + i]);
        if (mode == 491) {
            state[index] = values[b_start + i] + values[c_start + i] * values[d_start + i];
        } else {
            state[index] = values[b_start + index] + values[c_start + i];
        }
    }
    for (0..n) |i| storeI64Le(output, 8 * i, state[i]);
    return @intCast(n);
}
