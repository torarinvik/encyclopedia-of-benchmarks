const MAX_LIMIT: i64 = 61;
const MAX_TRIPLES: usize = 69;
const MAX_OUTPUT_BYTES: usize = 4 + 12 * MAX_TRIPLES;

fn is_prime(value: i64) bool {
    if (value < 2) return false;
    if (@rem(value, 2) == 0) return value == 2;
    var divisor: i64 = 3;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 2) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

fn put_u32_le(output: *[MAX_OUTPUT_BYTES]u8, offset: usize, value: u32) void {
    for (0..4) |byte| {
        output[offset + byte] = @truncate(value >> @intCast(8 * byte));
    }
}

export fn three_prime_carmichael_enumerator(
    input: [*c]const i64,
    length: usize,
    output_opt: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length != 1) return -1;
    const limit = input[0];
    if (limit < 2 or limit > MAX_LIMIT) return -1;

    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    var count: usize = 0;
    var position: usize = 4;
    var p1: i64 = 2;
    while (p1 <= limit) : (p1 += 1) {
        if (!is_prime(p1)) continue;
        var h3: i64 = 2;
        while (h3 < p1) : (h3 += 1) {
            const g = h3 + p1;
            var d: i64 = 1;
            while (d < g) : (d += 1) {
                if (@rem(g * (p1 - 1), d) != 0) continue;
                const square = @rem(p1 * p1, h3);
                const negative_square = if (square == 0) 0 else h3 - square;
                if (negative_square != @rem(d, h3)) continue;

                const p2 = 1 + @divTrunc((p1 - 1) * g, d);
                if (p2 <= p1 or !is_prime(p2)) continue;
                const p3 = 1 + @divTrunc(p1 * p2, h3);
                if (p3 <= p2 or !is_prime(p3)
                    or @rem(p2 * p3, p1 - 1) != 1) continue;
                if (count >= MAX_TRIPLES) return -1;

                put_u32_le(&staged, position, @intCast(p1));
                put_u32_le(&staged, position + 4, @intCast(p2));
                put_u32_le(&staged, position + 8, @intCast(p3));
                position += 12;
                count += 1;
            }
        }
    }

    put_u32_le(&staged, 0, @intCast(count));
    if (output_opt == null or capacity < position) return -2;
    const output = output_opt.?;
    for (0..position) |offset| output[offset] = staged[offset];
    return @intCast(position);
}
