/// A neon number equals the sum of the digits of its square.
export fn neon_number(number: i64) i64 {
    if (number < 0) return 0;
    if (number > 3_000_000_000) return -1;
    var square = number * number;
    var digit_sum: i64 = 0;
    while (square > 0) {
        digit_sum += @mod(square, 10);
        square = @divTrunc(square, 10);
    }
    return if (digit_sum == number) 1 else 0;
}
