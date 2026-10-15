/// Encode the first n palindrome primes as little-endian u32 values.
export fn palindrome_prime(n: i64, output: [*]u8, output_capacity: usize) i64 {
    if (n > 16) return -1;
    if (n <= 0) return 0;
    const required: usize = @as(usize, @intCast(n)) * 4;
    if (output_capacity < required) return -2;

    write_u32_le(output, 0, 2);
    var count: usize = 1;
    var candidate: u32 = 3;
    while (count < @as(usize, @intCast(n))) : (candidate += 2) {
        if (candidate == reverse_decimal(candidate) and is_prime(candidate)) {
            write_u32_le(output, count * 4, candidate);
            count += 1;
        }
    }
    return @intCast(required);
}

fn is_prime(value: u32) bool {
    if (value < 2) return false;
    var divisor: u32 = 2;
    while (divisor <= value / divisor) : (divisor += 1) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn reverse_decimal(value: u32) u32 {
    var remaining = value;
    var reversed: u32 = 0;
    while (remaining > 0) : (remaining /= 10) {
        reversed = reversed * 10 + remaining % 10;
    }
    return reversed;
}

fn write_u32_le(output: [*]u8, position: usize, value: u32) void {
    output[position] = @truncate(value);
    output[position + 1] = @truncate(value >> 8);
    output[position + 2] = @truncate(value >> 16);
    output[position + 3] = @truncate(value >> 24);
}
