// Count starts with the source's memoized digit-factorial chain length.
module problem74;

const long MAX_START = 1000000;
const usz CACHE_SIZE = 2540161;
const usz MAX_PATH_LENGTH = 128;

fn long sum_digit_factorials(long value) {
    long[10] factorials = {1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880};
    long total = 0;
    do {
        total += factorials[(usz)(value % 10)];
        value /= 10;
    } while (value > 0);
    return total;
}

fn long chain_length(long start, u8* cache) {
    long[MAX_PATH_LENGTH] path = {0};
    usz path_length = 0;
    long current = start;
    long result = 0;
    while (true) {
        u8 encoded = cache[(usz)current];
        if (encoded != 0) {
            result = (long)encoded - 1;
            break;
        }
        long next = sum_digit_factorials(current);
        bool repeats = false;
        for (usz index = 0; index < path_length; index++) {
            if (path[index] == next) { repeats = true; break; }
        }
        if (repeats) {
            cache[(usz)current] = 1;
            result = 0;
            break;
        }
        path[path_length++] = current;
        current = next;
    }
    while (path_length > 0) {
        path_length--;
        current = path[path_length];
        result++;
        cache[(usz)current] = (u8)(result + 1);
    }
    return (long)cache[(usz)start] - 1;
}

fn long problem74(long num_terms, long max_start) @export("problem74") {
    if (max_start > MAX_START) return -1;
    if (max_start <= 1) return 0;
    u8[CACHE_SIZE] cache = {0};
    cache[145] = 1;
    cache[169] = 4;
    cache[36301] = 4;
    cache[1454] = 4;
    cache[871] = 3;
    cache[45361] = 3;
    cache[872] = 3;
    long count = 0;
    for (long start = 1; start < max_start; start++) {
        if (chain_length(start, &cache[0]) == num_terms) count++;
    }
    return count;
}
