/// Emit Java-style swap-recursion permutations, retaining duplicate rows.
const MAX_LENGTH: usize = 6;
const MAX_PARSEABLE_LENGTH: usize = 8;

fn storeI32Le(output: [*]u8, position: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[position + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
}

fn generate(values: *[MAX_LENGTH]i32, n: usize, index: usize,
    output: [*]u8, result_count: *usize) void {
    if (index == n) {
        const row_start = result_count.* * n * 4;
        for (0..n) |column| storeI32Le(output, row_start + column * 4, values[column]);
        result_count.* += 1;
        return;
    }
    for (index..n) |position| {
        const saved = values[index];
        values[index] = values[position];
        values[position] = saved;
        generate(values, n, index + 1, output, result_count);
        const restore = values[index];
        values[index] = values[position];
        values[position] = restore;
    }
}

export fn permutation_array(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const n_value = input[0];
    if (n_value < 0 or n_value > MAX_LENGTH or length != @as(usize, @intCast(n_value)) + 1) return -1;
    const n: usize = @intCast(n_value);
    var values: [MAX_LENGTH]i32 = undefined;
    for (0..n) |index| {
        const value = input[index + 1];
        if (value < -2147483648 or value > 2147483647) return -1;
        values[index] = @intCast(value);
    }
    var permutation_count: usize = 1;
    for (2..n + 1) |factor| permutation_count *= factor;
    const required = permutation_count * n * 4;
    if (output_capacity < required or (required != 0 and output == null)) return -2;
    if (n == 0) return 1;
    const output_ptr: [*]u8 = @ptrCast(output);
    var result_count: usize = 0;
    generate(&values, n, 0, output_ptr, &result_count);
    return @intCast(result_count);
}
