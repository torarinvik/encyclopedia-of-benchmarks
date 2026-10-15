/// Check whether a square can be split into two parts that sum to n.
export fn kaprekar_number(number: i64) i64 {
    if (number < 1) return 0;
    if (number > 2_000_000_000) return -1;
    if (number == 1) return 1;
    const square = number * number;
    var split: i64 = 10;
    while (split <= square) {
        const right = @mod(square, split);
        if (right > 0 and @divTrunc(square, split) + right == number) return 1;
        if (split > @divTrunc(square, 10)) break;
        split *= 10;
    }
    return 0;
}
