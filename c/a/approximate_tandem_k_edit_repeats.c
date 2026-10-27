#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 12, MAX_INPUT = 14, MAX_OUTPUT = 1592 };

static size_t min_size(size_t a, size_t b) { return a < b ? a : b; }

static size_t edit_distance(const int64_t *text, size_t a, size_t a_len,
                            size_t b, size_t b_len) {
    size_t row[MAX_TEXT + 1];
    for (size_t j = 0; j <= b_len; ++j) row[j] = j;
    for (size_t i = 1; i <= a_len; ++i) {
        size_t diagonal = row[0];
        row[0] = i;
        for (size_t j = 1; j <= b_len; ++j) {
            const size_t above = row[j];
            const size_t deletion = above + 1;
            const size_t insertion = row[j - 1] + 1;
            const size_t substitution = diagonal + (text[a + i - 1] != text[b + j - 1]);
            row[j] = min_size(min_size(deletion, insertion), substitution);
            diagonal = above;
        }
    }
    return row[b_len];
}

static size_t minimum_edit_cost(const int64_t *text, size_t start, size_t length) {
    size_t best = 1000;
    size_t piece_start[MAX_TEXT], piece_length[MAX_TEXT];
    for (size_t prefix = 0; prefix <= length; ++prefix) {
        for (size_t suffix = 0; suffix + prefix <= length; ++suffix) {
            const size_t middle = length - prefix - suffix;
            if (middle < 2) continue;
            const uint32_t end_mask = (uint32_t)1u << (middle - 1);
            for (uint32_t mask = 1; mask < end_mask; ++mask) {
                size_t segments = 0, previous = 0;
                for (size_t cut = 1; cut < middle; ++cut) {
                    if ((mask & ((uint32_t)1u << (cut - 1))) != 0) {
                        piece_start[segments] = start + prefix + previous;
                        piece_length[segments++] = cut - previous;
                        previous = cut;
                    }
                }
                piece_start[segments] = start + prefix + previous;
                piece_length[segments++] = middle - previous;

                size_t left = 1000, right = 1000, internal = 0;
                for (size_t fragment = 0; fragment <= piece_length[0]; ++fragment) {
                    const size_t cost = edit_distance(text, start, prefix,
                        piece_start[0] + piece_length[0] - fragment, fragment);
                    if (cost < left) left = cost;
                }
                const size_t last = segments - 1;
                for (size_t fragment = 0; fragment <= piece_length[last]; ++fragment) {
                    const size_t cost = edit_distance(text, piece_start[last], fragment,
                        start + length - suffix, suffix);
                    if (cost < right) right = cost;
                }
                for (size_t i = 0; i + 1 < segments; ++i)
                    internal += edit_distance(text, piece_start[i], piece_length[i],
                                              piece_start[i + 1], piece_length[i + 1]);
                const size_t total = left + internal + right;
                if (total < best) best = total;
            }
        }
    }
    return best;
}

static size_t count_records(const int64_t *text, size_t n, size_t budget) {
    size_t count = 0;
    for (size_t start = 0; start < n; ++start)
        for (size_t length = 2; length <= n - start; ++length)
            count += minimum_edit_cost(text, start, length) <= budget;
    return count;
}

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[offset + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t approximate_tandem_k_edit_repeats(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    const int64_t n0 = input[0], budget0 = input[1];
    if (n0 < 2 || n0 > MAX_TEXT || budget0 < 0 || budget0 > 4 || length != (size_t)n0 + 2) return -1;
    const size_t n = (size_t)n0, budget = (size_t)budget0;
    const int64_t *text = input + 2;
    for (size_t i = 0; i < n; ++i) if (text[i] < 0 || text[i] > 3) return -1;
    const size_t count = count_records(text, n, budget);
    const size_t bytes = 8 * (1 + 3 * count);
    if (bytes > MAX_OUTPUT) return -1;
    if (output == NULL || capacity < bytes) return -2;
    store_i64_le(output, 0, (int64_t)count);
    size_t record = 0;
    for (size_t start = 0; start < n; ++start)
        for (size_t factor_length = 2; factor_length <= n - start; ++factor_length) {
            const size_t cost = minimum_edit_cost(text, start, factor_length);
            if (cost <= budget) {
                const size_t offset = 8 * (1 + 3 * record++);
                store_i64_le(output, offset, (int64_t)start);
                store_i64_le(output, offset + 8, (int64_t)factor_length);
                store_i64_le(output, offset + 16, (int64_t)cost);
            }
        }
    return (int64_t)bytes;
}
