module sieve_of_atkin;

// Count primes through limit with the Sieve of Atkin.
fn long sieve_of_atkin(long limit) @export("sieve_of_atkin")
{
    if (limit < 0 || limit > 4096) return -1;
    if (limit < 2) return 0;
    bool[4097] sieve;
    for (usz index = 0; index < 4097; index++) sieve[index] = false;
    for (long x = 1; x <= limit / x; x++) {
        long x_squared = x * x;
        for (long y = 1; y <= limit / y; y++) {
            long y_squared = y * y;
            long value = 4 * x_squared + y_squared;
            if (value <= limit && (value % 12 == 1 || value % 12 == 5)) sieve[(usz)value] = !sieve[(usz)value];
            value = 3 * x_squared + y_squared;
            if (value <= limit && value % 12 == 7) sieve[(usz)value] = !sieve[(usz)value];
            if (x > y) {
                value = 3 * x_squared - y_squared;
                if (value <= limit && value % 12 == 11) sieve[(usz)value] = !sieve[(usz)value];
            }
        }
    }
    for (long candidate = 5; candidate <= limit / candidate; candidate++) {
        if (sieve[(usz)candidate]) {
            long square = candidate * candidate;
            for (long multiple = square; multiple <= limit; multiple += square) sieve[(usz)multiple] = false;
        }
    }
    long count = 1;
    if (limit >= 3) count++;
    for (long value = 5; value <= limit; value++) {
        if (sieve[(usz)value]) count++;
    }
    return count;
}
