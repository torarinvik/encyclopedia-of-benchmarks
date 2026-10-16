const MAX_SEQUENCE_LENGTH: usize = 256;

export fn lyndon_factorization(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_SEQUENCE_LENGTH + 1) return -1;
    const values = input.?;
    const count = values[0];
    if (count < 0 or count > MAX_SEQUENCE_LENGTH or length != @as(usize, @intCast(count)) + 1) return -1;
    const n: usize = @intCast(count);
    for (0..n) |i| if (values[i + 1] < 97 or values[i + 1] > 122) return -1;
    const required = 2 * n;
    if (capacity < required) return -2;
    if (required == 0) return 0;
    if (output == null) return -2;
    const output_bytes = output.?;
    var start: usize = 0;
    var out: usize = 0;
    while (start < n) {
        var candidate = start + 1;
        var matched = start;
        while (candidate < n and values[matched + 1] <= values[candidate + 1]) {
            if (values[matched + 1] < values[candidate + 1]) { matched = start; } else { matched += 1; }
            candidate += 1;
        }
        const factor_length = candidate - matched;
        while (start <= matched) {
            for (0..factor_length) |j| { output_bytes[out] = @intCast(values[start + j + 1]); out += 1; }
            output_bytes[out] = 0; out += 1;
            start += factor_length;
        }
    }
    return @intCast(out);
}
