/// Emit permutations in depth-first input-index order; equal values keep multiplicity.
const MAX_LENGTH: usize = 6;
const BYTES_PER_VALUE: usize = 4;

fn storeI32Le(output: [*]u8, position: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[position + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
}

fn generate(values: *[MAX_LENGTH]i32, n: usize, depth: usize,
    current: *[MAX_LENGTH]i32, used: *[MAX_LENGTH]bool,
    output: [*]u8, result_count: *usize) void {
    if (depth == n) {
        const row_start = result_count.* * n * BYTES_PER_VALUE;
        for (0..n) |index| storeI32Le(output, row_start + index * BYTES_PER_VALUE, current[index]);
        result_count.* += 1;
        return;
    }
    for (0..n) |index| {
        if (used[index]) continue;
        current[depth] = values[index];
        used[index] = true;
        generate(values, n, depth + 1, current, used, output, result_count);
        used[index] = false;
    }
}

export fn all_permutations(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > MAX_LENGTH + 1) return -1;
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
    const required = permutation_count * n * BYTES_PER_VALUE;
    if (output_capacity < required) return -2;
    var current: [MAX_LENGTH]i32 = undefined;
    var used: [MAX_LENGTH]bool = @splat(false);
    var result_count: usize = 0;
    generate(&values, n, 0, &current, &used, output, &result_count);
    return @intCast(result_count);
}
