#include <stddef.h>
#include <stdint.h>

enum {
    MAX_N = 32, MAX_K = 3, MAX_INPUT = 35, MAX_OUTPUT = 91400,
    MAX_PERIODS = 17, BIT_WORDS = 272, MAX_FACTORS = 33
};

typedef struct {
    const int *text;
    int n;
    int budget;
    int factor_start[MAX_FACTORS];
    int factor_end[MAX_FACTORS];
    int factor_count;
    uint64_t seen[BIT_WORDS];
} Search;

static int min_int(int a, int b) { return a < b ? a : b; }

static int longest_forward(const int *text, int n, int center, int period, int budget) {
    const int left = center - period;
    const int limit = min_int(n - left, n - center);
    int mismatches = 0;
    for (int length = 0; length < limit; ++length) {
        if (text[left + length] != text[center + length] && ++mismatches > budget) return length;
    }
    return limit;
}

static int longest_backward(const int *text, int center, int period, int budget) {
    const int limit = min_int(center - period, center);
    int mismatches = 0;
    for (int length = 0; length < limit; ++length) {
        if (text[center - period - 1 - length] != text[center - 1 - length]
            && ++mismatches > budget) return length;
    }
    return limit;
}

static void mark_one(Search *search, int block_lo, int block_hi, int center,
                     int last_head, int start, int end, int period) {
    const int n = search->n;
    start += block_lo;
    end += block_lo;
    if (start <= block_lo || end >= n || end - start + 1 < 2 * period) return;
    if (start <= last_head + 1 && end >= last_head - 1) return;
    (void)block_hi;
    (void)center;
    const int index = (start * MAX_N + end) * MAX_PERIODS + period;
    search->seen[index / 64] |= UINT64_C(1) << (index % 64);
}

static void at_center(Search *search, const int *text, int n, int center,
                      int block_lo, int block_hi, int last_head) {
    if (center < 1 || center + 1 >= n) return;
    for (int period = 1; period <= center; ++period) {
        for (int right_budget = 0; right_budget <= search->budget; ++right_budget) {
            const int forward = longest_forward(text, n, center, period, right_budget);
            const int backward = longest_backward(text, center, period,
                                                    search->budget - right_budget);
            if (forward <= period && forward + backward >= period)
                mark_one(search, block_lo, block_hi, center,
                         last_head, center - period - backward,
                         center + forward - 1, period);
        }
    }

    int reversed[MAX_N];
    for (int i = 0; i < n; ++i) reversed[i] = text[n - 1 - i];
    const int reverse_center = n - 1 - center;
    for (int period = 1; period <= reverse_center; ++period) {
        for (int right_budget = 0; right_budget <= search->budget; ++right_budget) {
            const int forward = longest_forward(reversed, n, reverse_center,
                                                period, right_budget);
            const int backward = longest_backward(reversed, reverse_center, period,
                                                    search->budget - right_budget);
            if (forward <= period && forward + backward >= period) {
                const int reverse_start = reverse_center - period - backward;
                const int reverse_end = reverse_center + forward - 1;
                mark_one(search, block_lo, block_hi, center, last_head,
                         n - 1 - reverse_end, n - 1 - reverse_start, period);
            }
        }
    }
}

static void divide_block(Search *search, int first, int last) {
    if (first >= last) return;
    const int middle = first + (last - first) / 2;
    const int block_lo = search->factor_start[first];
    const int block_hi = search->factor_end[last];
    const int center = search->factor_end[middle] - 1;
    const int last_head = search->factor_end[last] - 1;
    at_center(search, search->text + block_lo, block_hi - block_lo,
              center - block_lo, block_lo, block_hi, last_head);
    divide_block(search, first, middle);
    divide_block(search, middle + 1, last);
}

static void encode_i64(uint8_t *output, size_t offset, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(value >> (8 * byte));
}

int64_t k_repetition_binary_division_kernel(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_K) return -1;
    const int n = (int)input[0], budget = (int)input[1];
    if (length != (size_t)n + 2) return -1;
    int text[MAX_N];
    for (int i = 0; i < n; ++i) {
        if (input[i + 2] < 0 || input[i + 2] > 4) return -1;
        text[i] = (int)input[i + 2];
    }
    for (int i = 0; i + 1 < n; ++i)
        if (text[i] == text[n - 1]) return -1;

    Search search = {0};
    search.text = text;
    search.n = n;
    search.budget = budget;
    int position = 0;
    while (position < n) {
        int best = 0;
        for (int earlier = 0; earlier < position; ++earlier) {
            int length_match = 0;
            while (position + length_match < n && earlier + length_match < n
                   && text[earlier + length_match] == text[position + length_match])
                ++length_match;
            if (length_match > best) best = length_match;
        }
        const int end = min_int(n, position + best + 1);
        search.factor_start[search.factor_count] = position;
        search.factor_end[search.factor_count] = end;
        ++search.factor_count;
        position = end;
    }

    const int block_size = budget + 2;
    for (int first = 0; first < search.factor_count; first += block_size) {
        const int last = min_int(search.factor_count, first + block_size) - 1;
        divide_block(&search, first, last);
    }

    int64_t record_count = 0;
    for (int start = 0; start < n; ++start) {
        for (int length_value = 2; length_value <= n - start; ++length_value) {
            const int end = start + length_value - 1;
            for (int period = 1; period <= length_value / 2; ++period) {
                const int index = (start * MAX_N + end) * MAX_PERIODS + period;
                if (search.seen[index / 64] & (UINT64_C(1) << (index % 64))) ++record_count;
            }
        }
    }
    const size_t written = 8 + (size_t)record_count * 32;
    if (written > MAX_OUTPUT) return -1;
    if (output == NULL || capacity < written) return -2;
    encode_i64(output, 0, (uint64_t)record_count);
    size_t offset = 8;
    for (int start = 0; start < n; ++start) {
        for (int length_value = 2; length_value <= n - start; ++length_value) {
            const int end = start + length_value - 1;
            for (int period = 1; period <= length_value / 2; ++period) {
                const int index = (start * MAX_N + end) * MAX_PERIODS + period;
                if (!(search.seen[index / 64] & (UINT64_C(1) << (index % 64)))) continue;
                int mismatches = 0;
                for (int i = start; i <= end - period; ++i)
                    if (text[i] != text[i + period]) ++mismatches;
                encode_i64(output, offset, (uint64_t)start); offset += 8;
                encode_i64(output, offset, (uint64_t)length_value); offset += 8;
                encode_i64(output, offset, (uint64_t)period); offset += 8;
                encode_i64(output, offset, (uint64_t)mismatches); offset += 8;
            }
        }
    }
    return (int64_t)written;
}
