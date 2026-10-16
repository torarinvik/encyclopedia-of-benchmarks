module problem60;

const int MAX_PRIMES = 1000;
const int TARGET_SIZE = 5;
const usz PAIR_CACHE_SIZE = 1000000;

fn bool is_prime(long value) {
    if (value < 2) return false;
    if (value == 2 || value == 3) return true;
    if (value % 2 == 0 || value % 3 == 0) return false;
    for (long divisor = 5; divisor <= value / divisor; divisor += 6) {
        if (value % divisor == 0 || value % (divisor + 2) == 0) return false;
    }
    return true;
}

fn long concatenate(long left, long right) {
    long scale = 10;
    while (scale <= right) scale *= 10;
    return left * scale + right;
}

fn bool pair_works(int left_index, int right_index, int* primes, u8* cache) {
    usz key = (usz)left_index * (usz)MAX_PRIMES + (usz)right_index;
    if (cache[key] != 0) return cache[key] == 2;
    usz reverse_key = (usz)right_index * (usz)MAX_PRIMES + (usz)left_index;
    if (cache[reverse_key] != 0) return cache[reverse_key] == 2;
    bool result = is_prime(concatenate((long)primes[left_index], (long)primes[right_index]))
               && is_prime(concatenate((long)primes[right_index], (long)primes[left_index]));
    u8 state = result ? 2 : 1;
    cache[key] = state;
    cache[reverse_key] = state;
    return result;
}

fn long search_set(int* primes, int prime_count, u8* cache, int* chain,
                   int depth, int start, long sum) {
    if (depth == TARGET_SIZE) return sum;
    for (int index = start; index < prime_count; ++index) {
        bool compatible = true;
        for (int member = 0; member < depth; ++member) {
            if (!pair_works(index, chain[member], primes, cache)) {
                compatible = false;
                break;
            }
        }
        if (!compatible) continue;
        chain[depth] = index;
        long result = search_set(primes, prime_count, cache, chain, depth + 1,
                                 index + 1, sum + (long)primes[index]);
        if (result != 0) return result;
    }
    return 0;
}

fn long problem60(long placeholder) @export("problem60") {
    if (placeholder != 0) return -1;
    int[MAX_PRIMES] primes = {3, 7, 13, 19};
    u8[PAIR_CACHE_SIZE] cache = {0};
    int[TARGET_SIZE] chain = {0};
    int prime_count = 4;
    while (prime_count < MAX_PRIMES) {
        long candidate = (long)primes[prime_count - 1] + 3;
        while (!is_prime(candidate)) candidate += 3;
        primes[prime_count++] = (int)candidate;
    }
    for (int start = 0; start < prime_count; ++start) {
        chain[0] = start;
        long result = search_set(&primes[0], prime_count, &cache[0], &chain[0],
                                 1, start + 1, (long)primes[start]);
        if (result != 0) return result;
    }
    return -1;
}
