/// Reverse half the digits to avoid overflow.
export fn palindrome_number(value: i64) i64 {
    if (value < 0 or value > 2_147_483_647) return -1;
    if (value != 0 and @mod(value, 10) == 0) return 0;
    var remaining = value;
    var reversed_half: i64 = 0;
    while (remaining > reversed_half) {
        reversed_half = reversed_half * 10 + @mod(remaining, 10);
        remaining = @divTrunc(remaining, 10);
    }
    return if (remaining == reversed_half or remaining == @divTrunc(reversed_half, 10)) 1 else 0;
}
