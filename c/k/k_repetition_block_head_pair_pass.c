#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 24, MAX_K = 3, MAX_INPUT = 27, MAX_CONTEXT = 48,
       MAX_FACTORS = 25, MAX_PERIODS = 13, BIT_WORDS = 117,
       MAX_OUTPUT = 39112 };

typedef struct {
    int text[MAX_N];
    int n;
    int budget;
    int starts[MAX_FACTORS];
    int ends[MAX_FACTORS];
    int factor_count;
    uint64_t seen[BIT_WORDS];
} State;

static int min_int(int a, int b) { return a < b ? a : b; }

static int forward_length(const int *w, int n, int center, int period, int allowed) {
    int errors = 0;
    const int limit = min_int(n - (center - period), n - center);
    for (int i = 0; i < limit; ++i) {
        if (w[center - period + i] != w[center + i] && ++errors > allowed) return i;
    }
    return limit;
}

static int backward_length(const int *w, int center, int period, int allowed) {
    int errors = 0;
    const int limit = min_int(center - period, center);
    for (int i = 0; i < limit; ++i) {
        if (w[center - period - 1 - i] != w[center - 1 - i] && ++errors > allowed) return i;
    }
    return limit;
}

static void mark(State *s, int base, int context_size, int center, int next_head,
                 int start, int end, int period) {
    if (start < 0 || end >= context_size || end - start + 1 < 2 * period) return;
    if (start > center + 1 || end < center - 1) return;
    if (start <= next_head + 1 && end >= next_head - 1) return;
    const int global_start = base + start;
    const int global_end = base + end;
    if (global_start < 0 || global_end >= s->n) return;
    const int index = (global_start * MAX_N + global_end) * MAX_PERIODS + period;
    s->seen[index / 64] |= UINT64_C(1) << (index % 64);
}

static void algorithm1_at(State *s, const int *w, int size, int base,
                          int center, int next_head) {
    if (center < 1 || center + 1 >= size) return;
    for (int period = 1; period <= center; ++period) {
        for (int k = 0; k <= s->budget; ++k) {
            const int f = forward_length(w, size, center, period, k);
            const int b = backward_length(w, center, period, s->budget - k);
            if (f <= period && f + b >= period)
                mark(s, base, size, center, next_head, center - period - b,
                     center + f - 1, period);
        }
    }
    int reversed[MAX_CONTEXT];
    for (int i = 0; i < size; ++i) reversed[i] = w[size - 1 - i];
    const int rc = size - 1 - center;
    for (int period = 1; period <= rc; ++period) {
        for (int k = 0; k <= s->budget; ++k) {
            const int f = forward_length(reversed, size, rc, period, k);
            const int b = backward_length(reversed, rc, period, s->budget - k);
            if (f <= period && f + b >= period) {
                const int rs = rc - period - b;
                const int re = rc + f - 1;
                mark(s, base, size, center, next_head, size - 1 - re,
                     size - 1 - rs, period);
            }
        }
    }
}

static void factorize(State *s) {
    int pos = 0;
    while (pos < s->n) {
        int best = 0;
        for (int earlier = 0; earlier < pos; ++earlier) {
            int match = 0;
            while (pos + match < s->n && earlier + match < s->n &&
                   s->text[earlier + match] == s->text[pos + match]) ++match;
            if (match > best) best = match;
        }
        const int end = min_int(s->n, pos + best + 1);
        s->starts[s->factor_count] = pos;
        s->ends[s->factor_count++] = end;
        pos = end;
    }
}

static void paired_head_pass(State *s) {
    const int block = s->budget + 2;
    const int block_count = (s->factor_count + block - 1) / block;
    for (int bi = 0; bi + 1 < block_count; ++bi) {
        const int first = bi * block;
        const int first_end = min_int(s->factor_count, first + block);
        const int second_end = min_int(s->factor_count, first_end + block);
        const int head = s->ends[first_end - 1] - 1;
        const int next_head = s->ends[second_end - 1] - 1;
        const int pair_start = s->starts[first];
        const int pair_end = s->ends[second_end - 1];
        const int pair_length = pair_end - pair_start;
        const int context_start = (pair_start > pair_length) ? pair_start - pair_length : 0;
        const int size = pair_end - context_start;
        int context[MAX_CONTEXT];
        for (int i = 0; i < size; ++i) context[i] = s->text[context_start + i];
        algorithm1_at(s, context, size, context_start, head - context_start,
                      next_head - context_start);
    }
}

static void put_i64(uint8_t *out, size_t at, uint64_t value) {
    for (size_t b = 0; b < 8; ++b) out[at + b] = (uint8_t)(value >> (8 * b));
}

int64_t k_repetition_block_head_pair_pass(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_K) return -1;
    const int n = (int)input[0], budget = (int)input[1];
    if (length != (size_t)n + 2) return -1;
    State s = {0};
    s.n = n;
    s.budget = budget;
    for (int i = 0; i < n; ++i) {
        if (input[i + 2] < 0 || input[i + 2] > 4) return -1;
        s.text[i] = (int)input[i + 2];
    }
    for (int i = 0; i + 1 < n; ++i) if (s.text[i] == s.text[n - 1]) return -1;
    factorize(&s);
    paired_head_pass(&s);

    size_t count = 0;
    for (int start = 0; start < n; ++start)
        for (int len = 2; len <= n - start; ++len) {
            const int end = start + len - 1;
            for (int period = 1; period <= len / 2; ++period) {
                const int bit = (start * MAX_N + end) * MAX_PERIODS + period;
                if ((s.seen[bit / 64] & (UINT64_C(1) << (bit % 64))) != 0) ++count;
            }
        }
    const size_t bytes = 8 + count * 32;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == NULL || capacity < bytes) return -2;
    put_i64(output, 0, count);
    size_t offset = 8;
    for (int start = 0; start < n; ++start)
        for (int len = 2; len <= n - start; ++len) {
            const int end = start + len - 1;
            for (int period = 1; period <= len / 2; ++period) {
                const int bit = (start * MAX_N + end) * MAX_PERIODS + period;
                if ((s.seen[bit / 64] & (UINT64_C(1) << (bit % 64))) == 0) continue;
                int errors = 0;
                for (int i = start; i <= end - period; ++i)
                    if (s.text[i] != s.text[i + period]) ++errors;
                put_i64(output, offset, (uint64_t)start); offset += 8;
                put_i64(output, offset, (uint64_t)len); offset += 8;
                put_i64(output, offset, (uint64_t)period); offset += 8;
                put_i64(output, offset, (uint64_t)errors); offset += 8;
            }
        }
    return (int64_t)bytes;
}
