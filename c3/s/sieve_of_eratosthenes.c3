module sieve_of_eratosthenes;

// Count the primes through limit using the Sieve of Eratosthenes.
fn long sieve_of_eratosthenes(long limit) @export("sieve_of_eratosthenes")
{
    if (limit < 0 || limit > 4096) return -1;
    bool[4097] prime;
    for (usz value = 0; value < 4097; value++) prime[value] = false;
    for (long value = 2; value <= limit; value++) prime[(usz)value] = true;
    for (long factor = 2; factor <= limit / factor; factor++) {
        if (prime[(usz)factor]) {
            for (long multiple = factor * factor; multiple <= limit; multiple += factor) {
                prime[(usz)multiple] = false;
            }
        }
    }
    long count = 0;
    for (long value = 2; value <= limit; value++) {
        if (prime[(usz)value]) count++;
    }
    return count;
}
