/// Return whether a value is abundant and not semiperfect.
export fn weird_number(value: i64) i64 {
    if (value < 0 or value > 512) return -1;
    if (value == 0) return 0;
    var reachable: [513]bool = @splat(false);
    reachable[0] = true;
    var divisor_sum: i64 = 0;
    var divisor: i64 = 1;
    while (divisor <= @divTrunc(value, 2)) : (divisor += 1) {
        if (@rem(value, divisor) != 0) continue;
        divisor_sum += divisor;
        var total = value;
        while (total >= divisor) : (total -= 1) {
            if (reachable[@intCast(total - divisor)]) reachable[@intCast(total)] = true;
        }
    }
    return if (divisor_sum > value and !reachable[@intCast(value)]) 1 else 0;
}
