module nthprime;

const MAX_SIEVE_SIZE = 1600;

// Expanding sieve strategy from the pinned Rust nth-prime routine.
fn long nthprime(long nth) @export("nthprime")
{
    if (nth < 1 || nth > 100) return -1;
    ulong[1600] primes;
    ulong total_prime = 0;
    ulong size_factor = 2;
    ulong size = (ulong)nth * size_factor;

    while (total_prime < (ulong)nth) {
        if (size > MAX_SIEVE_SIZE) return -1;
        for (ulong index = 0; index < size; index++) primes[index] = 1;
        for (ulong index = 2; index < size; index++) {
            if (primes[index] == 1) {
                for (ulong multiple = index; multiple < size; multiple++) {
                    ulong product = index * multiple;
                    if (product < size) primes[product] = 0;
                    else break;
                }
            }
        }
        total_prime = 0;
        for (ulong index = 2; index < size; index++) total_prime += primes[index];
        size_factor++;
        size = (ulong)nth * size_factor;
    }

    ulong count = 0;
    ulong used_size = size - (ulong)nth;
    for (ulong index = 2; index < used_size; index++) {
        count += primes[index];
        if (count == (ulong)nth) return (long)index;
    }
    return -1;
}
