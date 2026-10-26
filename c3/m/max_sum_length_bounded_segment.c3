module max_sum_length_bounded_segment;

const usz MAX_N = 32;
const usz MAX_INPUT = 35;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long max_sum_length_bounded_segment(long* input, usz length, char* output, usz capacity)
        @export("max_sum_length_bounded_segment") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long n64 = input[0], lower64 = input[1], upper64 = input[2];
    if (n64 < 1 || n64 > (long)MAX_N || lower64 < 1 || upper64 < lower64 || upper64 > n64 ||
        length != 3 + (usz)n64) return -1;
    usz n = (usz)n64, lower = (usz)lower64, upper = (usz)upper64;
    long[MAX_N + 1] prefix = zeroed;
    for (usz i = 0; i < n; i += 1) {
        long value = input[3 + i];
        if (value < -10000 || value > 10000) return -1;
        prefix[i + 1] = prefix[i] + value;
    }
    if (output == null || capacity < 24) return -2;
    usz[MAX_N + 1] deque = zeroed;
    usz head = 0, tail = 0;
    long best_sum = 0;
    usz best_start = 0, best_end = 0;
    bool have_best = false;
    for (usz end = lower; end <= n; end += 1) {
        usz added = end - lower;
        while (tail > head && prefix[deque[tail - 1]] > prefix[added]) tail -= 1;
        deque[tail] = added;
        tail += 1;
        usz earliest = end > upper ? end - upper : 0;
        while (head < tail && deque[head] < earliest) head += 1;
        usz start = deque[head];
        long sum = prefix[end] - prefix[start];
        if (!have_best || sum > best_sum ||
            (sum == best_sum && (start < best_start || (start == best_start && end < best_end)))) {
            best_sum = sum; best_start = start; best_end = end; have_best = true;
        }
    }
    store_i64_le(output, 0, best_sum);
    store_i64_le(output, 8, (long)best_start);
    store_i64_le(output, 16, (long)best_end);
    return 24;
}
