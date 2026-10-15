/// Count factors of five in n!, which determine its trailing decimal zeros.
export fn factorial_trailing_zeroes(input: i64) i64 {
    if (input < 0 or input > 1_000_000_000) return -1;
    var n = input;
    var count: i64 = 0;
    while (n > 0) {
        n = @divTrunc(n, 5);
        count += n;
    }
    return count;
}
