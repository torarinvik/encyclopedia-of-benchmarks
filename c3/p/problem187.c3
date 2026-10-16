module problem187;

extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);

fn bool is_composite(u64* bits, long value) {
    return (bits[(usz)(value / 64)] & ((u64)1 << (value % 64))) != 0;
}

fn void mark_composite(u64* bits, long value) {
    bits[(usz)(value / 64)] |= (u64)1 << (value % 64);
}

fn long problem187(long max_number) @export("problem187") {
    if (max_number < 0 || max_number > 100000000) return -1;
    long prime_limit = max_number / 2;
    if (prime_limit <= 2) return 0;

    usz words = (usz)((prime_limit + 63) / 64);
    u64* composite = (u64*)calloc(words, sizeof(u64));
    if (composite == null) return -1;
    defer free(composite);
    mark_composite(composite, 0);
    mark_composite(composite, 1);
    for (long prime = 2; prime <= (prime_limit - 1) / prime; prime++) {
        if (is_composite(composite, prime)) continue;
        for (long multiple = prime * prime; multiple < prime_limit; multiple += prime)
            mark_composite(composite, multiple);
    }

    long right_value = prime_limit - 1;
    while (right_value >= 2 && is_composite(composite, right_value)) right_value--;
    if (right_value < 2) return 0;
    long prime_count = 0;
    for (long value = 2; value <= right_value; value++)
        if (!is_composite(composite, value)) prime_count++;

    long right_rank = prime_count - 1;
    long left_rank = 0;
    long count = 0;
    for (long left_value = 2; left_value <= right_value; left_value++) {
        if (is_composite(composite, left_value)) continue;
        if (left_value > right_value) break;
        while (right_rank >= left_rank && left_value * right_value >= max_number) {
            right_rank--;
            right_value--;
            while (right_value >= 2 && is_composite(composite, right_value)) right_value--;
        }
        if (right_rank < left_rank) break;
        count += right_rank - left_rank + 1;
        left_rank++;
    }
    return count;
}
