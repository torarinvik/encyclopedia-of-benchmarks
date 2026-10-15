/// Return the first source-ordered Goldbach pair as two little-endian i32 values.
fn goldbachPrime(value: i64) bool {
    if (value == 2) return true;
    if (value < 2 or @rem(value, 2) == 0) return false;
    var divisor: i64 = 3;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 2) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

export fn goldbach_conjecture(number: i64, output: [*]u8, output_capacity: usize) i64 {
    if (number < 4 or number > 4096 or @rem(number, 2) != 0) return -1;
    if (output_capacity < 8) return -2;
    var first: i64 = 0;
    while (first <= @divTrunc(number, 2)) : (first += 1) {
        const second = number - first;
        if (goldbachPrime(first) and goldbachPrime(second)) {
            const pair = [_]u32{@intCast(first), @intCast(second)};
            for (0..2) |j| {
                for (0..4) |b| {
                    output[4 * j + b] = @truncate((pair[j] >> @intCast(8 * b)) & 0xff);
                }
            }
            return 8;
        }
    }
    return -1;
}
