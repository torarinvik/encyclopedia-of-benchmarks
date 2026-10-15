export fn faraday_lenz_law(values: [*]const i64, length: usize) i64 {
    if (length != 3) return -9223372036854775807 - 1;
    if (values[0] < -1_000_000_000 or values[0] > 1_000_000_000
        or values[1] < -1_000_000_000 or values[1] > 1_000_000_000
        or values[2] < 1 or values[2] > 1_000_000_000) return -9223372036854775807 - 1;
    const numerator = -(values[0] - values[1]) * 10;
    const magnitude = if (numerator < 0) -numerator else numerator;
    var quotient = @divTrunc(magnitude, values[2]);
    const remainder = @rem(magnitude, values[2]);
    if (2 * remainder > values[2] or (2 * remainder == values[2] and @rem(quotient, 2) != 0)) quotient += 1;
    return if (numerator < 0) -quotient else quotient;
}
