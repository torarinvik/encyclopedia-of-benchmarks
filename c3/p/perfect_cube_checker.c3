module perfect_cube_checker;

// Check whether a signed 32-bit integer is a perfect cube.
fn long perfect_cube_checker(long n) @export("perfect_cube_checker")
{
    if (n < -2147483648 || n > 2147483647) return -1;

    long magnitude = n < 0 ? -n : n;
    long low = 0;
    long high = 1290;
    while (low <= high) {
        long mid = low + (high - low) / 2;
        long cube = mid * mid * mid;
        if (cube == magnitude) return 1;
        if (cube < magnitude) low = mid + 1;
        else high = mid - 1;
    }
    return 0;
}
