/// Enumerate narcissistic numbers below limit, memoizing digit powers.
export fn narcissistic_number(limit: i64, output: [*]u8, output_capacity: usize) i64 {
    if (limit > 100000) return -1;
    if (limit <= 0) return 0;
    var numbers: [32]i64 = [_]i64{0} ** 32;
    var powers: [60]i64 = [_]i64{0} ** 60;
    var cached: [60]bool = [_]bool{false} ** 60;
    var count: usize = 0;
    var number: i64 = 0;
    while (number < limit) : (number += 1) {
        var digits: usize = 1;
        var remaining = number;
        while (remaining >= 10) : (remaining /= 10) { digits += 1; }
        var sum: i64 = 0;
        remaining = number;
        while (remaining > 0) : (remaining /= 10) {
            const digit: usize = @intCast(@mod(remaining, 10));
            const key = digits * 10 + digit;
            if (!cached[key]) {
                var power: i64 = 1;
                for (0..digits) |_| power *= @intCast(digit);
                powers[key] = power;
                cached[key] = true;
            }
            sum += powers[key];
        }
        if (sum == number) {
            if (count == numbers.len) return -1;
            numbers[count] = number;
            count += 1;
        }
    }
    const required = count * 8;
    if (required == 0) return 0;
    if (output_capacity < required) return -2;
    var position: usize = 0;
    for (numbers[0..count]) |value| {
        for (0..8) |byte| {
            const shift: u6 = @intCast((7 - byte) * 8);
            output[position] = @truncate(@as(u64, @intCast(value)) >> shift);
            position += 1;
        }
    }
    return @intCast(required);
}
