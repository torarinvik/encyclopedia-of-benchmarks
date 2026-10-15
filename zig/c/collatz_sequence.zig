const MAX_START: i64 = 1_000_000;

fn nextTerm(value: i64) i64 {
    if (@rem(value, 2) == 0) return @divTrunc(value, 2);
    return 3 * value + 1;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
    }
}

export fn collatz_sequence(input: [*]const i64, length: usize,
                           output: [*]u8, output_capacity: usize) i64 {
    if (length != 1 or input[0] < 1 or input[0] > MAX_START) return -1;
    const start = input[0];
    var current = start;
    var term_count: usize = 1;
    while (current != 1) {
        current = nextTerm(current);
        term_count += 1;
    }
    const required = term_count * 8;
    if (output_capacity < required) return -2;
    current = start;
    var written: usize = 0;
    while (true) {
        storeI64Le(output, written, current);
        written += 8;
        if (current == 1) break;
        current = nextTerm(current);
    }
    return @intCast(written);
}
