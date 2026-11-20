const max_value: usize = 64;
const max_queries: usize = 64;
const max_input_length: usize = 2 + 2 * max_queries;
const max_small: usize = 8;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn batch_gcd_small_range_precomputed(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input_length + 1) return -1;
    const input = input_opt.?;
    const limit_value = input[0];
    const query_value = input[1];
    if (limit_value < 1 or limit_value > @as(i64, @intCast(max_value)) or
        query_value < 0 or query_value > @as(i64, @intCast(max_queries))) return -1;
    const limit: usize = @intCast(limit_value);
    const queries: usize = @intCast(query_value);
    if (length != 2 + 2 * queries) return -1;
    for (0..queries) |query| {
        const left = input[2 + 2 * query];
        const right = input[3 + 2 * query];
        if (left < 0 or left > limit_value or right < 0 or right > limit_value) return -1;
    }
    const required = 8 * queries;
    if (output_opt == null or capacity < required) return -2;

    var least: [max_value + 1]usize = @splat(0);
    var primes: [max_value + 1]usize = @splat(0);
    var prime_count: usize = 0;
    for (2..limit + 1) |value| {
        if (least[value] == 0) {
            least[value] = value;
            primes[prime_count] = value;
            prime_count += 1;
        }
        for (0..prime_count) |index| {
            const prime = primes[index];
            const composite = value * prime;
            if (composite > limit or prime > least[value]) break;
            least[composite] = prime;
        }
    }

    var factors: [max_value + 1][3]usize = @splat(@splat(0));
    factors[1] = .{ 1, 1, 1 };
    for (2..limit + 1) |value| {
        const prime = least[value];
        const quotient = value / prime;
        var triple = factors[quotient];
        triple[0] *= prime;
        for (0..3) |_| {
            if (triple[0] > triple[1]) {
                const temp = triple[0]; triple[0] = triple[1]; triple[1] = temp;
            }
            if (triple[1] > triple[2]) {
                const temp = triple[1]; triple[1] = triple[2]; triple[2] = temp;
            }
        }
        factors[value] = triple;
    }

    var small_limit: usize = 1;
    while ((small_limit + 1) * (small_limit + 1) <= limit) : (small_limit += 1) {}
    var gcd_table: [max_small + 1][max_small + 1]usize = @splat(@splat(0));
    for (1..small_limit + 1) |left| {
        gcd_table[left][0] = left;
        for (1..left) |right| gcd_table[left][right] = gcd_table[right][left % right];
    }

    const output = output_opt.?;
    for (0..queries) |query| {
        const left: usize = @intCast(input[2 + 2 * query]);
        var remaining: usize = @intCast(input[3 + 2 * query]);
        var result: usize = 0;
        if (left == 0) {
            result = remaining;
        } else {
            result = 1;
            for (0..3) |part| {
                const factor = factors[left][part];
                const common = if (factor <= small_limit)
                    gcd_table[factor][remaining % factor]
                else if (remaining % factor == 0)
                    factor
                else
                    1;
                remaining /= common;
                result *= common;
            }
        }
        storeI64Le(output, 8 * query, @intCast(result));
    }
    @intCast(required)
}
