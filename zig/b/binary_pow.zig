/// Integer binary exponentiation with Java int wraparound semantics.
fn mul32(x: i64, y: i64) i64 {
    const x_low = @mod(x, 65_536);
    const x_high = @divTrunc(x, 65_536);
    const y_low = @mod(y, 65_536);
    const y_high = @divTrunc(y, 65_536);
    const cross = @mod(x_low * y_high + x_high * y_low, 65_536);
    return @mod(x_low * y_low + cross * 65_536, 4_294_967_296);
}

export fn binary_pow(first: i64, second: i64) i64 {
    if (first < -2_147_483_648 or first > 2_147_483_647 or second < -2_147_483_648 or second > 2_147_483_647) return -2_147_483_649;
    if (second <= 0) return 1;
    var base: i64 = first;
    if (base < 0) base += 4_294_967_296;
    var exponent: i64 = second;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@mod(exponent, 2) == 1) result = mul32(result, base);
        base = mul32(base, base);
        exponent = @divTrunc(exponent, 2);
    }
    return if (result >= 2_147_483_648) result - 4_294_967_296 else result;
}
