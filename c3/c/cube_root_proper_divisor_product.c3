module cube_root_proper_divisor_product;

const usz MAX_INPUT_LENGTH = 2;
const usz MAX_VALUE = 600000;
const long MAX_K = 50000;

fn void build_prime_prefix(uint* prefix) {
    prefix[0] = 0;
    prefix[1] = 0;
    for (usz value = 2; value <= MAX_VALUE; value++) prefix[value] = 1;
    for (usz prime = 2; prime <= MAX_VALUE / prime; prime++) {
        if (prefix[prime] != 0) {
            for (usz multiple = prime * prime; multiple <= MAX_VALUE; multiple += prime)
                prefix[multiple] = 0;
        }
    }
    for (usz value = 1; value <= MAX_VALUE; value++)
        prefix[value] += prefix[value - 1];
}

fn bool is_prime(usz value, uint* prefix) {
    return value >= 2 && prefix[value] - prefix[value - 1] == 1;
}

fn long count_tau_eight(usz limit, uint* prefix) {
    long count = 0;
    for (usz prime = 2; ; prime++) {
        ulong power = 1;
        for (usz exponent = 0; exponent < 7; exponent++) {
            if (power > limit / prime) { power = limit + 1; break; }
            power *= prime;
        }
        if (power > limit) break;
        if (is_prime(prime, prefix)) count++;
    }

    for (usz prime = 2; ; prime++) {
        ulong cube = prime * prime * prime;
        if (cube > limit) break;
        if (is_prime(prime, prefix)) {
            usz q_max = (usz)(limit / cube);
            count += prefix[q_max];
            if (prime <= q_max) count--;
        }
    }

    for (usz prime = 2; prime * prime * prime < limit; prime++) {
        if (!is_prime(prime, prefix)) continue;
        for (usz other = prime + 1; ; other++) {
            if (prime > limit / other) break;
            usz product = prime * other;
            usz last_prime = (usz)(limit / product);
            if (last_prime <= other) break;
            if (is_prime(other, prefix)) count += prefix[last_prime] - prefix[other];
        }
    }
    return count;
}

fn long cube_root_proper_divisor_product(long* input, usz length)
    @export("cube_root_proper_divisor_product") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (length != 1 || input[0] < 1 || input[0] > MAX_K) return -1;
    if (input[0] == 1) return 1;
    uint[MAX_VALUE + 1] prime_prefix;
    build_prime_prefix(&prime_prefix[0]);
    long target = input[0] - 1;
    if (count_tau_eight(MAX_VALUE, &prime_prefix[0]) < target) return -1;
    usz low = 1;
    usz high = MAX_VALUE;
    while (low < high) {
        usz middle = low + (high - low) / 2;
        if (count_tau_eight(middle, &prime_prefix[0]) >= target) high = middle;
        else low = middle + 1;
    }
    return (long)low;
}
