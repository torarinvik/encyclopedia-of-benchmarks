const MAX_INPUT_LENGTH: usize = 3;
const MAX_STACK: usize = 128;
const MAX_DIVISOR_COUNT: i64 = 63;
const MAX_LIMIT: i64 = 1_000_000;
const PRIMES = [_]i64{ 2, 3, 5, 7, 11 };

fn execute(input: []const i64) ?i64 {
    if (input.len < 2 or input.len > MAX_INPUT_LENGTH or input.len != 2) return null;
    const divisor_count = input[0];
    const limit = input[1];
    if (divisor_count < 1 or divisor_count > MAX_DIVISOR_COUNT or
        limit < 1 or limit > MAX_LIMIT) return null;

    var remaining_stack: [MAX_STACK]i64 = @splat(0);
    var max_factor_stack: [MAX_STACK]i64 = @splat(0);
    var prime_index_stack: [MAX_STACK]i64 = @splat(0);
    var product_stack: [MAX_STACK]i64 = @splat(0);
    var top: usize = 1;
    remaining_stack[0] = divisor_count;
    max_factor_stack[0] = divisor_count;
    product_stack[0] = 1;
    var best = limit + 1;

    while (top != 0) {
        top -= 1;
        const remaining = remaining_stack[top];
        const max_factor = max_factor_stack[top];
        const prime_index = prime_index_stack[top];
        const product = product_stack[top];
        if (remaining == 1) {
            best = @min(best, product);
            continue;
        }
        if (prime_index < 0 or prime_index >= @as(i64, @intCast(PRIMES.len))) continue;
        const prime = PRIMES[@intCast(prime_index)];
        const factor_limit = @min(max_factor, remaining);
        var factor: i64 = 2;
        while (factor <= factor_limit) : (factor += 1) {
            if (@mod(remaining, factor) != 0) continue;
            var candidate = product;
            var valid = true;
            var step: i64 = 1;
            while (step < factor) : (step += 1) {
                if (candidate > @divTrunc(limit, prime)) {
                    valid = false;
                    break;
                }
                candidate *= prime;
            }
            if (valid and candidate < best) {
                if (top >= MAX_STACK) return null;
                remaining_stack[top] = @divTrunc(remaining, factor);
                max_factor_stack[top] = factor;
                prime_index_stack[top] = prime_index + 1;
                product_stack[top] = candidate;
                top += 1;
            }
        }
    }
    return if (best <= limit) best else 0;
}

export fn smallest_number_with_n_divisors(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    return execute(input[0..length]) orelse -1;
}
