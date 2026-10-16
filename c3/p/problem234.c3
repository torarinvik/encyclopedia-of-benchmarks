module problem234;

const long MAX_LIMIT = 999966663333;
const int SIEVE_CAP = 1000100;
const int PRIME_CAP = 80000;

fn long problem234(long limit) @export("problem234") {
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    bool[SIEVE_CAP] composite = {false};
    long[PRIME_CAP] primes;
    int prime_count = 0;
    long root = 0;
    while (root + 1 <= limit / (root + 1)) root++;
    long sieve_end = root + 100;
    for (long p = 2; p < sieve_end; p++) {
        if (composite[p]) continue;
        primes[prime_count++] = p;
        if (p * p < sieve_end)
            for (long multiple = p * p; multiple < sieve_end; multiple += p) composite[multiple] = true;
    }
    long total = 0;
    int index = 0;
    long p = primes[index];
    while (p * p <= limit) {
        long q = primes[index + 1];
        long lower = p * p;
        long upper = q * q;
        long current = lower + p;
        while (upper > current && current <= limit) { total += current; current += p; }
        while (upper - q > limit) upper -= q;
        current = upper - q;
        while (current > lower) { total += current; current -= q; }
        current = 0;
        while (upper > current && current <= limit) {
            if (current <= lower) { current += p * q; continue; }
            if (current > limit) break;
            total -= current * 2;
            current += p * q;
        }
        p = q;
        index++;
    }
    return total;
}
