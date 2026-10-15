module segmented_sieve;
const usz MAX_N = 10000;
fn void put_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}
fn long segmented_sieve(long* input, usz length, char* output, usz capacity) @export("segmented_sieve") {
    if (input == null || length != 1 || input[0] < 2 || input[0] > MAX_N) return -1;
    usz n = (usz)input[0], end = 0;
    while ((end + 1) * (end + 1) <= n) end++;
    bool base_marks[101] = {};
    long base[25] = {};
    usz base_count = 0;
    for (usz i = 2; i <= end; i++) base_marks[i] = true;
    for (usz p = 2; p <= end; p++) {
        if (!base_marks[p]) continue;
        base[base_count++] = (long)p;
        for (usz m = p * p; m <= end; m += p) base_marks[m] = false;
    }
    long primes[1229] = {};
    usz prime_count = 0;
    for (usz i = 0; i < base_count; i++) primes[prime_count++] = base[i];
    usz low = end + 1, high = 2 * end < n ? 2 * end : n;
    while (low <= n) {
        bool segment[201] = {};
        usz segment_length = high - low + 1;
        for (usz i = 0; i < segment_length; i++) segment[i] = true;
        for (usz i = 0; i < base_count; i++) {
            usz p = (usz)base[i], first = (low / p) * p;
            if (first < low) first += p;
            for (usz m = first; m <= high; m += p) segment[m - low] = false;
        }
        for (usz i = 0; i < segment_length; i++) if (segment[i]) primes[prime_count++] = (long)(low + i);
        low = high + 1;
        high = high + end < n ? high + end : n;
    }
    usz output_length = prime_count * 8;
    if (capacity < output_length || (output_length > 0 && output == null)) return -2;
    for (usz i = 0; i < prime_count; i++) put_i64_le(primes[i], output, i * 8);
    return (long)output_length;
}
