/// Count decimal zero digits at the end of a nonnegative integer.
export fn trailing_zeroes(input: i64) i64 {
    if (input < 0) return -1;
    if (input == 0) return 1;
    var n = input;
    var count: i64 = 0;
    while (@rem(n, 10) == 0) {
        count += 1;
        n = @divTrunc(n, 10);
    }
    return count;
}
