const max_q: usize = 8;
const max_n: i64 = 10_000;
const max_output_bytes: usize = 6_496;

fn integerSqrt(value: i64) i64 {
    var low: i64 = 0;
    var high = value + 1;
    while (high - low > 1) {
        const middle = low + (high - low) / 2;
        if (middle * middle <= value) low = middle else high = middle;
    }
    return low;
}

fn writeU32(output: [*]u8, offset: usize, value: u32) void {
    output[offset] = @truncate(value);
    output[offset + 1] = @truncate(value >> 8);
    output[offset + 2] = @truncate(value >> 16);
    output[offset + 3] = @truncate(value >> 24);
}

export fn two_square_sum(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_q + 1) return -1;
    const input = input_opt.?;
    const q64 = input[0];
    if (q64 < 1 or q64 > @as(i64, @intCast(max_q))) return -1;
    const q: usize = @intCast(q64);
    if (length != q + 1) return -1;

    var numbers: [max_q]i64 = @splat(0);
    var counts: [max_q]usize = @splat(0);
    var total_pairs: usize = 0;
    for (0..q) |query| {
        const n = input[query + 1];
        if (n < 0 or n > max_n) return -1;
        numbers[query] = n;
        var a: i64 = 0;
        while (a * a <= n) : (a += 1) {
            const remainder = n - a * a;
            const b = integerSqrt(remainder);
            if (b * b == remainder) counts[query] += 1;
        }
        total_pairs += counts[query];
    }

    const required = 4 * (q + 2 * total_pairs);
    if (output_opt == null or capacity < required or required > max_output_bytes) return -2;
    const output = output_opt.?;
    var offset: usize = 0;
    for (0..q) |query| {
        writeU32(output, offset, @intCast(counts[query]));
        offset += 4;
        const n = numbers[query];
        var a: i64 = 0;
        while (a * a <= n) : (a += 1) {
            const remainder = n - a * a;
            const b = integerSqrt(remainder);
            if (b * b != remainder) continue;
            writeU32(output, offset, @intCast(a));
            writeU32(output, offset + 4, @intCast(b));
            offset += 8;
        }
    }
    return @intCast(offset);
}
