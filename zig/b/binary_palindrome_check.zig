/// Test whether the significant binary digits of an int32 value form a palindrome.
export fn binary_palindrome_check(number: i64) i64 {
    if (number < -2147483648 or number > 2147483647) return -1;
    if (number < 0) return 0;
    var remaining = number;
    var reversed: i64 = 0;
    while (remaining > 0) {
        reversed = (reversed << 1) | (remaining & 1);
        remaining = @divTrunc(remaining, 2);
    }
    return if (reversed == number) 1 else 0;
}
