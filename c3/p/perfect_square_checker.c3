module perfect_square_checker;

// Check whether a signed 32-bit integer is a perfect square.
fn long perfect_square_checker(long n) @export("perfect_square_checker")
{
    if (n < -2147483648 || n > 2147483647) return -1;
    if (n < 0) return 0;

    long low = 0;
    long high = 46340;
    while (low <= high) {
        long mid = low + (high - low) / 2;
        long square = mid * mid;
        if (square == n) return 1;
        if (square < n) low = mid + 1;
        else high = mid - 1;
    }
    return 0;
}
