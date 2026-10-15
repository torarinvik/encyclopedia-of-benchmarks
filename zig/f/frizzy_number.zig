/// Sum base powers at the set-bit positions of n.
export fn frizzy_number(base: i64, input_n: i64) i64 {
    if (base < 2 or base > 10 or input_n < 0 or input_n > 1023) return -1;
    var remaining: u64 = @intCast(input_n);
    const radix: u64 = @intCast(base);
    var result: u64 = 0;
    var power: u64 = 1;
    while (remaining > 0) {
        if (remaining % 2 == 1) result += power;
        remaining /= 2;
        if (remaining > 0) power *= radix;
    }
    return @intCast(result);
}
