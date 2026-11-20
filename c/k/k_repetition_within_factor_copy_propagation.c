#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_K = 3, MAX_SYMBOL = 5, MAX_INPUT = 1557,
       MAX_RECORDS = 372, MAX_PERIODS = 9, SEEN_BITS = 16 * 17 * 9,
       SEEN_WORDS = (SEEN_BITS + 63) / 64, MAX_OUTPUT = 11912 };

typedef struct { int32_t start, end, period, errors; } Record;
typedef struct {
    int32_t word[MAX_N];
    int32_t factor_start[MAX_N], factor_end[MAX_N], factor_copy[MAX_N];
    Record records[MAX_RECORDS];
    uint64_t known[SEEN_WORDS], generated[SEEN_WORDS];
    int32_t n, budget;
    size_t factor_count, record_count;
} State;

static int lce(const int32_t *word, int n, int left, int right) {
    int length = 0;
    while (left + length < n && right + length < n &&
           word[left + length] == word[right + length]) ++length;
    return length;
}

static int tuple_less(const Record *a, const Record *b) {
    if (a->start != b->start) return a->start < b->start;
    if (a->end != b->end) return a->end < b->end;
    if (a->period != b->period) return a->period < b->period;
    return a->errors < b->errors;
}

static size_t record_bit(int start, int end, int period) {
    return ((size_t)start * (MAX_N + 1) + (size_t)end) * MAX_PERIODS + (size_t)period;
}

static int is_marked(const uint64_t *bits, size_t bit) {
    return (int)((bits[bit / 64] >> (bit % 64)) & UINT64_C(1));
}

static void add_record(State *s, Record record, int is_generated) {
    const size_t bit = record_bit(record.start, record.end, record.period);
    if (is_marked(s->known, bit)) return;
    s->known[bit / 64] |= UINT64_C(1) << (bit % 64);
    if (is_generated) s->generated[bit / 64] |= UINT64_C(1) << (bit % 64);
    size_t at = s->record_count;
    while (at > 0 && tuple_less(&record, &s->records[at - 1])) {
        s->records[at] = s->records[at - 1];
        --at;
    }
    s->records[at] = record;
    ++s->record_count;
}

static int validate_factors(State *s) {
    if (s->factor_count == 0 || s->factor_count > (size_t)s->n) return 0;
    int position = 0;
    for (size_t i = 0; i < s->factor_count; ++i) {
        int start = s->factor_start[i], end = s->factor_end[i], copy = s->factor_copy[i];
        if (start != position || start < 0 || end <= start || end > s->n) return 0;
        if (i == 0) {
            if (start != 0 || end != 1 || copy != -1) return 0;
            position = end;
            continue;
        }
        int longest = 0;
        for (int earlier = 0; earlier < start; ++earlier) {
            int match = lce(s->word, s->n, earlier, start);
            if (match > longest) longest = match;
        }
        int expected_end = start + longest + 1;
        if (expected_end > s->n) expected_end = s->n;
        if (end != expected_end) return 0;
        int prefix = end - start - 1;
        if (prefix == 0) {
            if (copy != -1) return 0;
        } else if (copy < 0 || copy >= start || lce(s->word, s->n, copy, start) != prefix) {
            return 0;
        }
        position = end;
    }
    return position == s->n;
}

static int mismatch_count(const int32_t *word, int start, int end, int period) {
    int count = 0;
    for (int i = start; i < end - period; ++i)
        if (word[i] != word[i + period]) ++count;
    return count;
}

static int valid_seed(const State *s, Record record) {
    int start = record.start, end = record.end, period = record.period;
    if (start < 0 || start >= end || end > s->n || period < 1 ||
        period > s->n / 2 || end - start < 2 * period) return 0;
    int errors = mismatch_count(s->word, start, end, period);
    if (errors != record.errors || errors > s->budget) return 0;
    if (start > 0 && errors + (s->word[start - 1] != s->word[start + period - 1]) <= s->budget) return 0;
    if (end < s->n && errors + (s->word[end - period] != s->word[end]) <= s->budget) return 0;
    return 1;
}

static void propagate(State *s) {
    for (size_t f = 0; f < s->factor_count; ++f) {
        int a = s->factor_start[f], b = s->factor_end[f], c = s->factor_copy[f];
        int copied = b - a - 1;
        if (copied <= 0) continue;
        int delta = a - c, copy_end = c + copied;
        for (int target = a + 1; target < b - 1; ++target) {
            int source_start = target - delta;
            size_t index = 0;
            while (index < s->record_count && s->records[index].start < source_start) ++index;
            while (index < s->record_count && s->records[index].start == source_start) {
                Record source = s->records[index];
                if (source.end > copy_end) break;
                int target_end = source.end + delta;
                if (target_end <= b - 2) {
                    Record shifted = {target, target_end, source.period, source.errors};
                    add_record(s, shifted, 1);
                }
                ++index;
            }
        }
    }
}

static void put_i64(uint8_t *out, size_t at, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte) out[at + byte] = (uint8_t)(value >> (8 * byte));
}

int64_t k_repetition_within_factor_copy_propagation(const int64_t *input, size_t length,
                                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_K) return -1;
    const int n = (int)input[0], budget = (int)input[1];
    if (length < (size_t)n + 3) return -1;
    State state = {0};
    state.n = n;
    state.budget = budget;
    size_t cursor = 2;
    for (int i = 0; i < n; ++i) {
        if (input[cursor] < 0 || input[cursor] > MAX_SYMBOL) return -1;
        state.word[i] = (int32_t)input[cursor++];
    }
    for (int i = 0; i + 1 < n; ++i) if (state.word[i] == state.word[n - 1]) return -1;
    if (cursor >= length || input[cursor] < 1 || input[cursor] > n) return -1;
    state.factor_count = (size_t)input[cursor++];
    if (cursor + 3 * state.factor_count >= length) return -1;
    for (size_t i = 0; i < state.factor_count; ++i) {
        int64_t a = input[cursor], b = input[cursor + 1], c = input[cursor + 2];
        if (a < 0 || a > n || b < 0 || b > n || c < -1 || c > n) return -1;
        state.factor_start[i] = (int32_t)a;
        state.factor_end[i] = (int32_t)b;
        state.factor_copy[i] = (int32_t)c;
        cursor += 3;
    }
    if (cursor >= length || !validate_factors(&state)) return -1;
    int64_t seed_count_value = input[cursor++];
    if (seed_count_value < 0 || seed_count_value > MAX_RECORDS ||
        cursor + 4 * (size_t)seed_count_value != length) return -1;
    const size_t seed_count = (size_t)seed_count_value;
    for (size_t i = 0; i < seed_count; ++i) {
        int64_t a = input[cursor], b = input[cursor + 1], p = input[cursor + 2], e = input[cursor + 3];
        if (a < 0 || a > n || b < 0 || b > n || p < 0 || p > n || e < 0 || e > MAX_K) return -1;
        Record seed = {(int32_t)a, (int32_t)b, (int32_t)p, (int32_t)e};
        if (!valid_seed(&state, seed)) return -1;
        add_record(&state, seed, 0);
        cursor += 4;
    }
    propagate(&state);
    size_t count = 0;
    for (size_t i = 0; i < state.record_count; ++i) {
        Record record = state.records[i];
        if (is_marked(state.generated, record_bit(record.start, record.end, record.period))) ++count;
    }
    const size_t bytes = 8 + 32 * count;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == NULL || capacity < bytes) return -2;
    put_i64(output, 0, count);
    size_t offset = 8;
    for (size_t i = 0; i < state.record_count; ++i) {
        Record record = state.records[i];
        if (!is_marked(state.generated, record_bit(record.start, record.end, record.period))) continue;
        put_i64(output, offset, (uint64_t)record.start); offset += 8;
        put_i64(output, offset, (uint64_t)record.end); offset += 8;
        put_i64(output, offset, (uint64_t)record.period); offset += 8;
        put_i64(output, offset, (uint64_t)record.errors); offset += 8;
    }
    return (int64_t)bytes;
}
