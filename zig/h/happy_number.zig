/// Standard happy-number test using Floyd cycle detection.
fn digitSquareSum(input: i64) i64 {
    var n = input;
    var total: i64 = 0;
    while (n > 0) {
        const digit = @mod(n, 10);
        total += digit * digit;
        n = @divTrunc(n, 10);
    }
    return total;
}

export fn happy_number(n: i64) i64 {
    if (n <= 0) return -1;
    var slow = digitSquareSum(n);
    var fast = digitSquareSum(digitSquareSum(n));
    while (slow != fast) {
        slow = digitSquareSum(slow);
        fast = digitSquareSum(digitSquareSum(fast));
    }
    return if (slow == 1) 1 else 0;
}
