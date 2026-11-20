module sieve_of_sundaram;

// Count primes through limit with Sundaram's index sieve.
fn long sieve_of_sundaram(long limit) @export("sieve_of_sundaram") {
    if (limit < 0 || limit > 4096) return -1;
    if (limit < 2) return 0;

    long max_index = (limit - 1) / 2;
    bool[2048] composite = zeroed;
    for (long i = 1; 2 * i * (i + 1) <= max_index; i++) {
        long j = i;
        while (true) {
            long index = i + j + 2 * i * j;
            if (index > max_index) break;
            composite[(usz)index] = true;
            j++;
        }
    }
    long count = 1;
    for (long index = 1; index <= max_index; index++)
        if (!composite[(usz)index]) count++;
    return count;
}
