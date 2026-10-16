module problem70;

const long MAX_N = 10000000;
const usz PRIME_LIMIT = 3162;
const usz PRIME_CAPACITY = 500;
const usz SEGMENT_SIZE = 32768;

fn bool same_digits(u32 left, u32 right) {
    long[10] counts;
    for (usz digit = 0; digit < 10; digit++) counts[digit] = 0;
    while (left != 0) { counts[left % 10]++; left /= 10; }
    while (right != 0) { counts[right % 10]--; right /= 10; }
    for (usz digit = 0; digit < 10; digit++) if (counts[digit] != 0) return false;
    return true;
}

fn long problem70(long max_n) @export("problem70") {
    if (max_n < 0 || max_n > MAX_N) return -1;
    u32 limit = max_n.u32();
    bool[PRIME_LIMIT + 1] is_prime;
    u32[PRIME_CAPACITY] primes;
    usz prime_count = 0;
    for (usz value = 0; value <= PRIME_LIMIT; value++) is_prime[value] = false;
    for (usz value = 2; value <= PRIME_LIMIT && value <= limit.usz() / value; value++) is_prime[value] = true;
    for (usz prime = 2; prime <= PRIME_LIMIT && prime <= limit.usz() / prime; prime++) {
        if (!is_prime[prime]) continue;
        for (usz multiple = prime * prime; multiple <= PRIME_LIMIT && multiple <= limit.usz() / multiple; multiple += prime)
            is_prime[multiple] = false;
    }
    for (usz value = 2; value <= PRIME_LIMIT && value <= limit.usz() / value; value++)
        if (is_prime[value]) primes[prime_count++] = value.u32();

    u32[SEGMENT_SIZE] phi;
    u32[SEGMENT_SIZE] remainder;
    u32 best_n = 1;
    u32 best_phi = 0;
    u32 low = 0;
    while (low <= limit) {
        u32 high = low + SEGMENT_SIZE.u32() - 1;
        if (high < low || high > limit) high = limit;
        usz length = (high - low + 1).usz();
        for (usz offset = 0; offset < length; offset++) {
            phi[offset] = low + offset.u32();
            remainder[offset] = low + offset.u32();
        }
        for (usz index = 0; index < prime_count; index++) {
            u32 prime = primes[index];
            u32 first = low + (prime - low % prime) % prime;
            if (first < prime) first = prime;
            u32 multiple = first;
            while (multiple <= high) {
                usz offset = (multiple - low).usz();
                phi[offset] -= phi[offset] / prime;
                while (remainder[offset] % prime == 0) remainder[offset] /= prime;
                if (high - multiple < prime) break;
                multiple += prime;
            }
        }
        for (usz offset = 0; offset < length; offset++) {
            if (remainder[offset] > 1) phi[offset] -= phi[offset] / remainder[offset];
            u32 number = low + offset.u32();
            if (number < 2) continue;
            if (number.u64() * best_phi.u64() < best_n.u64() * phi[offset].u64()
                    && same_digits(number, phi[offset])) {
                best_n = number;
                best_phi = phi[offset];
            }
        }
        if (high == limit) break;
        low = high + 1;
    }
    return best_n.long();
}
