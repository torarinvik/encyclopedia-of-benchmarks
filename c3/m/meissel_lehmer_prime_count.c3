module meissel_lehmer_prime_count;

const long MAX_INPUT = 100000000;
const usz SIEVE_LIMIT = 10000;
const usz MAX_PRIMES = 1300;
const usz PHI_CACHE_X = 2048;
const usz PHI_CACHE_S = 32;

struct Context {
    u8[SIEVE_LIMIT + 1] composite;
    int[MAX_PRIMES] primes;
    int[SIEVE_LIMIT + 1] prime_count_prefix;
    int[PHI_CACHE_X + 1][PHI_CACHE_S + 1] phi_cache;
}

fn ulong integer_sqrt(ulong value) {
    ulong low = 0, high = value + 1;
    while (low + 1 < high) {
        ulong middle = low + (high - low) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle;
    }
    return low;
}

fn ulong integer_cuberoot(ulong value) {
    ulong low = 0, high = value + 1;
    while (low + 1 < high) {
        ulong middle = low + (high - low) / 2;
        if (middle <= value / middle / middle) low = middle;
        else high = middle;
    }
    return low;
}

fn long phi(Context* context, ulong value, usz prime_count) {
    if (value == 0) return 0;
    if (prime_count == 0) return (long)value;
    if (prime_count == 1) return (long)(value - value / 2);
    ulong prime = (ulong)context->primes[prime_count - 1];
    if (value < prime) return 1;
    if (value <= PHI_CACHE_X && prime_count <= PHI_CACHE_S) {
        int cached = context->phi_cache[value.usz()][prime_count];
        if (cached != 0) return (long)cached;
        long result = phi(context, value, prime_count - 1) -
            phi(context, value / prime, prime_count - 1);
        context->phi_cache[value.usz()][prime_count] = (int)result;
        return result;
    }
    return phi(context, value, prime_count - 1) -
        phi(context, value / prime, prime_count - 1);
}

fn long lehmer_count(Context* context, ulong value) {
    if (value <= SIEVE_LIMIT) return (long)context->prime_count_prefix[value.usz()];
    usz a = (usz)context->prime_count_prefix[integer_sqrt(integer_sqrt(value)).usz()];
    usz b = (usz)context->prime_count_prefix[integer_sqrt(value).usz()];
    usz c = (usz)context->prime_count_prefix[integer_cuberoot(value).usz()];
    long result = phi(context, value, a) + (long)(b + a - 2) * (long)(b - a + 1) / 2;
    for (usz i = a; i < b; i++) {
        ulong quotient = value / (ulong)context->primes[i];
        result -= lehmer_count(context, quotient);
        if (i < c) {
            usz limit = (usz)lehmer_count(context, integer_sqrt(quotient));
            for (usz j = i; j < limit; j++)
                result -= lehmer_count(context, quotient / (ulong)context->primes[j]) - (long)j;
        }
    }
    return result;
}

fn long meissel_lehmer_prime_count(long value) @export("meissel_lehmer_prime_count") {
    if (value < 0 || value > MAX_INPUT) return -1;
    Context context = {};
    for (usz candidate = 2; candidate * candidate <= SIEVE_LIMIT; candidate++) {
        if (context.composite[candidate] != 0) continue;
        for (usz multiple = candidate * candidate; multiple <= SIEVE_LIMIT; multiple += candidate)
            context.composite[multiple] = 1;
    }
    usz prime_count = 0;
    for (usz candidate = 2; candidate <= SIEVE_LIMIT; candidate++) {
        if (context.composite[candidate] == 0) context.primes[prime_count++] = (int)candidate;
        context.prime_count_prefix[candidate] = context.prime_count_prefix[candidate - 1] +
            (int)(context.composite[candidate] == 0);
    }
    return lehmer_count(&context, (ulong)value);
}
