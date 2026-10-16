const MAX_MODULUS: i64 = 1_000_000;
const MAX_INDEX: usize = 55_374;

fn positiveMod(value: i64, modulus: i64) i64 {
    const remainder = @rem(value, modulus);
    return if (remainder < 0) remainder + modulus else remainder;
}

pub export fn problem78(modulus: i64) i64 {
    if (modulus < 1 or modulus > MAX_MODULUS) return -1;
    var partitions = [_]u32{0} ** (MAX_INDEX + 1);
    partitions[0] = 1;
    for (1..MAX_INDEX + 1) |n| {
        var value: i64 = 0;
        var j: i64 = 1;
        while (true) {
            const first = @divTrunc(3 * j * j - j, 2);
            if (first > @as(i64, @intCast(n))) break;
            const sign: i64 = if (@mod(j, 2) == 0) -1 else 1;
            value = positiveMod(value + sign * @as(i64, partitions[n - @as(usize, @intCast(first))]), modulus);
            const second = first + j;
            if (second > @as(i64, @intCast(n))) break;
            value = positiveMod(value + sign * @as(i64, partitions[n - @as(usize, @intCast(second))]), modulus);
            j += 1;
        }
        if (value == 0) return @intCast(n);
        partitions[n] = @intCast(value);
    }
    return -1;
}
