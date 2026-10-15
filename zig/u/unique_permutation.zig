/// Emit unique ASCII permutations in sorted depth-first order.
const MAX_LENGTH: usize = 6;

fn generate(values: *[MAX_LENGTH]i64, n: usize, depth: usize,
    current: *[MAX_LENGTH]i64, used: *[MAX_LENGTH]bool,
    output: [*]u8, result_count: *usize) void {
    if (depth == n) {
        const row = result_count.* * n;
        for (0..n) |i| output[row + i] = @intCast(current[i]);
        result_count.* += 1;
        return;
    }
    for (0..n) |i| {
        if (used[i]) continue;
        if (i > 0 and values[i] == values[i - 1] and !used[i - 1]) continue;
        current[depth] = values[i];
        used[i] = true;
        generate(values, n, depth + 1, current, used, output, result_count);
        used[i] = false;
    }
}

export fn unique_permutation(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > MAX_LENGTH + 1) return -1;
    const n_value = input[0];
    if (n_value < 0 or n_value > MAX_LENGTH or length != @as(usize, @intCast(n_value)) + 1) return -1;
    const n: usize = @intCast(n_value);
    var values: [MAX_LENGTH]i64 = undefined;
    for (0..n) |i| {
        const value = input[i + 1];
        if (value < 0 or value > 127) return -1;
        values[i] = value;
    }
    var sort_index: usize = 1;
    while (sort_index < n) : (sort_index += 1) {
        const value = values[sort_index];
        var position = sort_index;
        while (position > 0 and values[position - 1] > value) : (position -= 1) {
            values[position] = values[position - 1];
        }
        values[position] = value;
    }
    var max_count: usize = 1;
    var factor: usize = 2;
    while (factor <= n) : (factor += 1) max_count *= factor;
    const required = max_count * n;
    if (output_capacity < required) return -2;
    var current: [MAX_LENGTH]i64 = undefined;
    var used: [MAX_LENGTH]bool = @splat(false);
    var result_count: usize = 0;
    generate(&values, n, 0, &current, &used, output, &result_count);
    return @intCast(result_count);
}

