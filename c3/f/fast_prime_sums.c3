module fast_prime_sums;

const long MAX_INPUT = 1000000000;
const usz SIEVE_LIMIT = 32000;
const usz PRIME_CAPACITY = 3500;
const usz PHI_ROWS = 12;
const usz PHI_COLUMNS = 30000;

struct Context {
    char[SIEVE_LIMIT + 1] composite;
    long[PRIME_CAPACITY] primes;
    int[SIEVE_LIMIT + 1] prime_count;
    long[SIEVE_LIMIT + 1] prime_sum;
    long[PHI_ROWS][PHI_COLUMNS] phi;
}

fn long sqrt_floor(long n) {
    long low = 0; long high = n + 1;
    while (low + 1 < high) {
        long middle = low + (high - low) / 2;
        if (middle <= n / middle) low = middle;
        else high = middle;
    }
    return low;
}

fn long cbrt_floor(long n) {
    long low = 0; long high = 1;
    while (high * high * high <= n) high *= 2;
    while (low + 1 < high) {
        long middle = low + (high - low) / 2;
        if (middle * middle * middle <= n) low = middle;
        else high = middle;
    }
    return low;
}

fn long weighted_phi(Context* context, long n, usz count) {
    if (n <= 0) return 0;
    if (count == 0) return n * (n + 1) / 2;
    long prime = context.primes[count - 1];
    if (n <= prime) return 1;
    if (count < PHI_ROWS && n < (long)PHI_COLUMNS) return context.phi[count][(usz)n];
    if (n < (long)SIEVE_LIMIT && prime * prime >= n)
        return context.prime_sum[(usz)n] - context.prime_sum[(usz)prime] + 1;
    if (n < (long)SIEVE_LIMIT && prime * prime * prime >= n) {
        long result = context.prime_sum[(usz)n] - context.prime_sum[(usz)prime] + 1;
        usz limit = (usz)context.prime_count[(usz)sqrt_floor(n)];
        for (usz index = count; index < limit; index++) {
            long other = context.primes[index];
            result += other * (context.prime_sum[(usz)(n / other)] - context.prime_sum[(usz)(other - 1)]);
        }
        return result;
    }
    return weighted_phi(context, n, count - 1) - prime * weighted_phi(context, n / prime, count - 1);
}

fn long sum_primes(Context* context, long n) {
    if (n <= SIEVE_LIMIT) return context.prime_sum[(usz)n];
    usz cube = (usz)cbrt_floor(n);
    usz square = (usz)sqrt_floor(n);
    usz first = (usz)context.prime_count[cube];
    usz last = (usz)context.prime_count[square];
    long result = weighted_phi(context, n, first) + context.prime_sum[cube] - 1;
    for (usz index = first; index < last; index++) {
        long prime = context.primes[index];
        long quotient = n / prime;
        result -= (sum_primes(context, quotient) - context.prime_sum[(usz)(prime - 1)]) * prime;
    }
    return result;
}

fn long fast_prime_sums(long value) @export("fast_prime_sums") {
    if (value < 0 || value > MAX_INPUT) return -1;
    Context context = {};
    for (usz candidate = 2; candidate * candidate <= SIEVE_LIMIT; candidate++) {
        if (context.composite[candidate] != 0) continue;
        for (usz multiple = candidate * candidate; multiple <= SIEVE_LIMIT; multiple += candidate)
            context.composite[multiple] = 1;
    }
    usz count = 0;
    for (usz n = 2; n <= SIEVE_LIMIT; n++) {
        if (context.composite[n] == 0) context.primes[count++] = (long)n;
        context.prime_count[n] = context.prime_count[n - 1] + (context.composite[n] == 0 ? 1 : 0);
        context.prime_sum[n] = context.prime_sum[n - 1] +
            (context.composite[n] == 0 ? (long)n : 0);
    }
    for (usz n = 0; n < PHI_COLUMNS; n++) context.phi[0][n] = (long)n * ((long)n + 1) / 2;
    for (usz row = 1; row < PHI_ROWS; row++) {
        long prime = context.primes[row - 1];
        for (usz n = 0; n < PHI_COLUMNS; n++)
            context.phi[row][n] = context.phi[row - 1][n] - prime * context.phi[row - 1][n / (usz)prime];
    }
    return sum_primes(&context, value);
}
