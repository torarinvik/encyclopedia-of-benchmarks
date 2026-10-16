module problem111;

const long MAX_N = 10000000000;
const int SIEVE_CAP = 100002;
const int PRIME_CAP = 100001;

fn bool is_prime(long value, long* primes, int count) {
    for (int i = 0; i < count; i++) { long p = primes[i]; if (value % p == 0) return false; }
    return true;
}

fn long problem111(long n) @export("problem111") {
    if (n < 1000 || n > MAX_N) return -1;
    bool[SIEVE_CAP] composite = {false};
    long[PRIME_CAP] primes;
    int prime_count = 0;
    long root = 0; while (root + 1 <= n / (root + 1)) root++;
    int sieve_limit = (int)root + 1;
    for (int p = 2; p <= sieve_limit; p++) {
        if (composite[p]) continue;
        primes[prime_count++] = p;
        if ((long)p * p <= sieve_limit) for (int multiple = p * p; multiple <= sieve_limit; multiple += p) composite[multiple] = true;
    }
    int digits = 0; for (long copy = n; copy > 0; copy /= 10) digits++;
    int width = digits - 1;
    int repeated_two = width - 2;
    long total = 0;
    for (int i = 1; i <= 9; i++) for (int j = 1; j <= 9; j++) {
        long value = i; for (int z = 0; z < width - 2; z++) value *= 10; value = value * 10 + j;
        if (is_prime(value, primes, prime_count)) total += value;
    }
    bool[10] one_digit = {false};
    for (int i = 1; i <= 9; i++) for (int j = 0; j < width; j++) for (int k = 0; k <= 9; k++) {
        long value = 0; for (int pos = 0; pos < width; pos++) value = value * 10 + (pos == j ? k : i);
        if (is_prime(value, primes, prime_count)) { one_digit[i] = true; total += value; }
    }
    for (int i = 1; i <= 9; i++) if (!one_digit[i])
        for (int j = 0; j <= repeated_two; j++) for (int k = 0; k <= repeated_two - j; k++)
            for (int m1 = 0; m1 <= 9; m1++) {
                if (m1 == 0 && j == 0) continue;
                for (int m2 = 0; m2 <= 9; m2++) {
                    long value = 0;
                    for (int pos = 0; pos < width; pos++) value = value * 10 + (pos == j ? m1 : (pos == j + k + 1 ? m2 : i));
                    if (is_prime(value, primes, prime_count)) total += value;
                }
            }
    return total;
}
