const SIEVE_LIMIT: usize = 8192;
const MAX_ITERATIONS: i64 = 64;

export fn sieve(iterations: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (iterations < 0 or iterations > MAX_ITERATIONS) return -1;

    var flags: [SIEVE_LIMIT + 1]u8 = @splat(0);
    var count: i64 = 0;
    var pass: i64 = 0;
    while (pass < iterations) : (pass += 1) {
        count = 0;
        var value: usize = 2;
        while (value <= SIEVE_LIMIT) : (value += 1) flags[value] = 1;
        value = 2;
        while (value <= SIEVE_LIMIT) : (value += 1) {
            if (flags[value] != 0) {
                count += 1;
                var multiple = value + value;
                while (multiple <= SIEVE_LIMIT) : (multiple += value)
                    flags[multiple] = 0;
            }
        }
    }

    var reversed_digits: [10]u8 = @splat(0);
    var digit_count: usize = 0;
    var remaining = count;
    while (true) {
        reversed_digits[digit_count] = @intCast(48 + remaining % 10);
        digit_count += 1;
        remaining /= 10;
        if (remaining == 0) break;
    }
    const required = 8 + digit_count;
    if (output_opt == null or output_capacity < required) return -2;
    const output = output_opt.?;
    output[0] = 67; output[1] = 111; output[2] = 117;
    output[3] = 110; output[4] = 116; output[5] = 58;
    output[6] = 32;
    for (0..digit_count) |index|
        output[7 + index] = reversed_digits[digit_count - index - 1];
    output[required - 1] = 10;
    return @intCast(required);
}
