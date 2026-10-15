module primes_sequence;

// Generate zero-based prime terms using divisibility by all earlier primes.
fn long primes_sequence(long index) @export("primes_sequence")
{
    if (index < 0 || index > 99) return -1;
    long[100] primes;
    primes[0] = 2;
    long count = 1;
    long candidate = 3;
    while (count <= index) {
        bool is_prime = true;
        for (long i = 0; i < count; i++) {
            if (candidate % primes[(usz)i] == 0) {
                is_prime = false;
                break;
            }
        }
        if (is_prime) {
            primes[(usz)count] = candidate;
            count++;
        }
        candidate += 2;
    }
    return primes[(usz)index];
}
