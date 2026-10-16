export fn problem3(number: i64) i64 {
    if (number < 2 or number > 600_851_475_143) return -1;
    var remaining = number;
    var largest: i64 = 1;
    var factor: i64 = 2;
    while (factor <= @divTrunc(remaining, factor)) {
        if (@rem(remaining, factor) == 0) {
            largest = factor;
            remaining = @divTrunc(remaining, factor);
        } else {
            factor += 1;
        }
    }
    return if (remaining > 1) remaining else largest;
}
