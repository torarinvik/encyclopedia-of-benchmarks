const MAX_INDEX: i64 = 25;
const INT32_MIN_VALUE: i64 = -2_147_483_648;
const INT32_MAX_VALUE: i64 = 2_147_483_647;

/// Compare the source recurrence term a[n] with expected; this is not primality testing.
export fn new_man_shanks_prime(n: i64, expected: i64) i64 {
    if (n < 1 or n > MAX_INDEX or expected < INT32_MIN_VALUE or expected > INT32_MAX_VALUE) return -1;
    var previous_previous: i32 = 1;
    var previous: i32 = 1;
    if (n == 1) return if (expected == @as(i64, previous)) 1 else 0;
    var index: i64 = 2;
    while (index <= n) : (index += 1) {
        const current: i32 = 2 * previous + previous_previous;
        previous_previous = previous;
        previous = current;
    }
    return if (expected == @as(i64, previous)) 1 else 0;
}
