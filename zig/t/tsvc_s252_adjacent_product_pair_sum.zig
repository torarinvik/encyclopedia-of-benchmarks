// Clean-room bounded port of TSVC s252; see package README for provenance.
const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 129;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s252_adjacent_product_pair_sum(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + 2 * n) return -1;
    var b = [_]i64{0} ** MAX_N;
    var c = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        b[i] = values[1 + i];
        c[i] = values[1 + n + i];
        if (b[i] < -2 or b[i] > 2 or c[i] < -2 or c[i] > 2) return -1;
    }
    if (output == null or capacity < 8 * n) return -2;
    var previous_product: i64 = 0;
    for (0..n) |i| {
        const product = b[i] * c[i];
        storeI64Le(output, 8 * i, product + previous_product);
        previous_product = product;
    }
    return @intCast(n);
}
