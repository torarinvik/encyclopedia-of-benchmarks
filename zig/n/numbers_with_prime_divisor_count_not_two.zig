const MAX_INPUT_LENGTH: usize = 2;
const MAX_LIMIT: usize = 1000;
const MAX_LIMIT_I64: i64 = 1000;

fn isPrimeCount(value: u16) bool {
    if (value < 2) return false;
    var divisor: u16 = 2;
    while (divisor <= value / divisor) : (divisor += 1) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn storeI64(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn numbers_with_prime_divisor_count_not_two(
    input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?[0..length];
    if (length != 1 or input[0] < 1 or input[0] > MAX_LIMIT_I64) return -1;
    if (output_opt == null) return -2;

    const limit: usize = @intCast(input[0]);
    var divisor_counts: [MAX_LIMIT]u16 = @splat(0);
    for (1..limit) |divisor| {
        var multiple = divisor;
        while (multiple < limit) : (multiple += divisor) divisor_counts[multiple] += 1;
    }
    var selected_count: usize = 0;
    for (1..limit) |n| {
        const count = divisor_counts[n];
        if (count != 2 and isPrimeCount(count)) selected_count += 1;
    }
    const output_bytes = selected_count * 8;
    if (capacity < output_bytes) return -2;
    const output = output_opt.?[0..output_bytes];
    var output_index: usize = 0;
    for (1..limit) |n| {
        const count = divisor_counts[n];
        if (count != 2 and isPrimeCount(count)) {
            storeI64(output, output_index * 8, @intCast(n));
            output_index += 1;
        }
    }
    return @intCast(output_bytes);
}
