module problem800;

extern fn double log2(double value);
extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);

fn bool is_composite(u64* bits, long value) {
    return (bits[(usz)(value / 64)] & ((u64)1 << (value % 64))) != 0;
}
fn void mark_composite(u64* bits, long value) {
    bits[(usz)(value / 64)] |= (u64)1 << (value % 64);
}

fn long problem800(long base, long degree) @export("problem800") {
    if (base < 2 || base > 1000000 || degree < 1 || degree > 1000000) return -1;
    double upper_bound = (double)degree * log2((double)base);
    long prime_limit = (long)upper_bound;
    if (prime_limit <= 2) return 0;

    usz words = (usz)((prime_limit + 63) / 64);
    u64* composite = (u64*)calloc(words, sizeof(u64));
    if (composite == null) return -1;
    defer free(composite);
    for (long prime = 2; prime <= (prime_limit - 1) / prime; prime++) {
        if (is_composite(composite, prime)) continue;
        for (long multiple = prime * prime; multiple < prime_limit; multiple += prime)
            mark_composite(composite, multiple);
    }

    long right_value = 0;
    long prime_count = 0;
    for (long value = 2; value < prime_limit; value++) {
        if (!is_composite(composite, value)) { right_value = value; prime_count++; }
    }
    if (prime_count < 2) return 0;

    long right_rank = prime_count - 1;
    long left_rank = 0;
    long left_value = 2;
    long count = 0;
    while (left_rank < right_rank) {
        while (is_composite(composite, left_value)) left_value++;
        double left_log = log2((double)left_value);
        while ((double)right_value * left_log + (double)left_value * log2((double)right_value) > upper_bound) {
            right_rank--;
            right_value--;
            while (right_value >= 2 && is_composite(composite, right_value)) right_value--;
        }
        count += right_rank - left_rank;
        left_rank++;
        left_value++;
    }
    return count;
}
