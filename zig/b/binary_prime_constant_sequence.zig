const MAX_COUNT: i64 = 4096;

fn isPrime(candidate: i64) bool {
    if (candidate < 2) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(candidate, divisor)) : (divisor += 1) {
        if (@mod(candidate, divisor) == 0) return false;
    }
    return true;
}

export fn binary_prime_constant_sequence(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length != 1 or input[0] < 0 or input[0] > MAX_COUNT) return -1;
    const count_value = input[0];
    const count: usize = @intCast(count_value);
    if (output_capacity < count) return -2;

    var next: usize = 1;
    var candidate: i64 = 2;
    while (candidate <= count_value) : (candidate += 1) {
        if (!isPrime(candidate)) continue;
        while (next < @as(usize, @intCast(candidate))) : (next += 1) {
            output[next - 1] = 0;
        }
        output[@as(usize, @intCast(candidate)) - 1] = 1;
        next = @as(usize, @intCast(candidate)) + 1;
    }
    while (next <= count) : (next += 1) {
        output[next - 1] = 0;
    }
    return @intCast(count);
}
