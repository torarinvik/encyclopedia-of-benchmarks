const max_n: usize = 10;
const max_input_values: usize = 3;
const output_bytes: usize = 8;

fn cycleCount(n: usize, shift: usize, reflection: bool) usize {
    var seen = [_]bool{false} ** max_n;
    var cycles: usize = 0;
    for (0..n) |start| {
        if (seen[start]) continue;
        cycles += 1;
        var position = start;
        while (!seen[position]) {
            seen[position] = true;
            position = if (reflection)
                (shift + n - position) % n
            else
                (position + shift) % n;
        }
    }
    return cycles;
}

fn fixedColorings(n: usize, shift: usize, reflection: bool, colors: i64) i64 {
    const cycles = cycleCount(n, shift, reflection);
    var result: i64 = 1;
    for (0..cycles) |_| result *= colors;
    return result;
}

fn storeI64Le(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..output_bytes) |byte| {
        output[byte] = @truncate(bits >> @intCast(8 * byte));
    }
}

export fn burnside_bracelets(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > max_input_values) return -1;
    if (length != 2) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const colors = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(max_n)) or colors < 0 or colors > 3) return -1;
    const n: usize = @intCast(n_value);

    var fixed_sum: i64 = 0;
    for (0..n) |shift| {
        fixed_sum += fixedColorings(n, shift, false, colors);
        fixed_sum += fixedColorings(n, shift, true, colors);
    }
    const answer = @divTrunc(fixed_sum, @as(i64, @intCast(2 * n)));
    if (output_opt == null or capacity < output_bytes) return -2;
    storeI64Le(output_opt.?, answer);
    return output_bytes;
}
