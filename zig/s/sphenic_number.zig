fn source_sieve_flag(value: i64) bool {
    if (value < 2) return true;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

export fn sphenic_number(value: i64) i64 {
    if (value < 0 or value > 1000) return -1;
    var first = [_]i64{ 0, 0, 0 };
    var count: i64 = 0;
    var divisor: i64 = 1;
    while (divisor <= value) : (divisor += 1) {
        if (@rem(value, divisor) == 0 and count < 9) {
            if (count < 3) first[@intCast(count)] = divisor;
            count += 1;
        }
    }
    return if (count == 8 and source_sieve_flag(first[0])
        and source_sieve_flag(first[1]) and source_sieve_flag(first[2])) 1 else 0;
}
