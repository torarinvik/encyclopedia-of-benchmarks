module new_man_shanks_prime;

const long MAX_INDEX = 25L;
const long INT32_MIN_VALUE = -2147483648L;
const long INT32_MAX_VALUE = 2147483647L;

// Compare the source recurrence term a[n] with expected; no primality test.
fn long new_man_shanks_prime(long n, long expected) @export("new_man_shanks_prime") {
    if (n < 1L || n > MAX_INDEX || expected < INT32_MIN_VALUE || expected > INT32_MAX_VALUE) return -1L;
    int previous_previous = 1;
    int previous = 1;
    if (n == 1L) return expected == (long)previous ? 1L : 0L;
    for (long index = 2L; index <= n; index++) {
        int current = 2 * previous + previous_previous;
        previous_previous = previous;
        previous = current;
    }
    return (long)previous == expected ? 1L : 0L;
}
