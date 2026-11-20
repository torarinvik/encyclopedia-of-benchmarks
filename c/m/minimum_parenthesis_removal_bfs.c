#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_TEXT 16
#define MAX_PARENS 8
#define MAX_RESULTS (1u << MAX_PARENS)
#define MAX_OUTPUT 4354

static unsigned popcount(unsigned value) {
    unsigned count = 0;
    while (value != 0) { count += value & 1u; value >>= 1; }
    return count;
}

static int balanced(const uint8_t *text, size_t length) {
    int depth = 0;
    for (size_t i = 0; i < length; ++i) {
        if (text[i] == '(') ++depth;
        else if (text[i] == ')' && --depth < 0) return 0;
    }
    return depth == 0;
}

static int lex_less(const uint8_t *a, size_t al, const uint8_t *b, size_t bl) {
    size_t common = al < bl ? al : bl;
    int cmp = memcmp(a, b, common);
    return cmp < 0 || (cmp == 0 && al < bl);
}

int64_t minimum_parenthesis_removal_bfs(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_TEXT + 1) return -1;
    int64_t n_arg = input[0];
    if (n_arg < 0 || n_arg > MAX_TEXT || length != (size_t)n_arg + 1) return -1;
    size_t n = (size_t)n_arg;
    uint8_t text[MAX_TEXT];
    uint8_t positions[MAX_PARENS];
    size_t p = 0;
    for (size_t i = 0; i < n; ++i) {
        int64_t value = input[i + 1];
        if (value == '(' || value == ')') {
            if (p == MAX_PARENS) return -1;
            positions[p++] = (uint8_t)i;
        } else if (value < 'a' || value > 'z') return -1;
        text[i] = (uint8_t)value;
    }

    uint8_t rows[MAX_RESULTS][MAX_TEXT] = {{0}};
    uint8_t row_lengths[MAX_RESULTS] = {0};
    size_t result_count = 0;
    unsigned state_count = 1u << p;
    for (size_t removals = 0; removals <= p && result_count == 0; ++removals) {
        for (unsigned mask = 0; mask < state_count; ++mask) {
            if (popcount(mask) != removals) continue;
            uint8_t candidate[MAX_TEXT];
            size_t candidate_length = 0;
            size_t ordinal = 0;
            for (size_t i = 0; i < n; ++i) {
                int remove = ordinal < p && positions[ordinal] == i &&
                             (mask & (1u << ordinal)) != 0;
                if (ordinal < p && positions[ordinal] == i) ++ordinal;
                if (!remove) candidate[candidate_length++] = text[i];
            }
            if (!balanced(candidate, candidate_length)) continue;
            size_t r = 0;
            while (r < result_count &&
                   (row_lengths[r] != candidate_length ||
                    memcmp(rows[r], candidate, candidate_length) != 0)) ++r;
            if (r == result_count) {
                memcpy(rows[result_count], candidate, candidate_length);
                row_lengths[result_count++] = (uint8_t)candidate_length;
            }
        }
    }
    if (result_count == 0) {
        rows[0][0] = 0;
        row_lengths[0] = 0;
        result_count = 1;
    }
    for (size_t i = 1; i < result_count; ++i) {
        uint8_t key[MAX_TEXT];
        size_t key_length = row_lengths[i];
        memcpy(key, rows[i], key_length);
        size_t j = i;
        while (j > 0 && lex_less(key, key_length, rows[j - 1], row_lengths[j - 1])) {
            memcpy(rows[j], rows[j - 1], row_lengths[j - 1]);
            row_lengths[j] = row_lengths[j - 1];
            --j;
        }
        memcpy(rows[j], key, key_length);
        row_lengths[j] = (uint8_t)key_length;
    }
    size_t needed = 2;
    for (size_t i = 0; i < result_count; ++i) needed += 1 + row_lengths[i];
    if (needed > MAX_OUTPUT) return -1;
    if (output == NULL || capacity < needed) return -2;
    output[0] = (uint8_t)result_count;
    output[1] = (uint8_t)(result_count >> 8);
    size_t pos = 2;
    for (size_t i = 0; i < result_count; ++i) {
        output[pos++] = row_lengths[i];
        memcpy(output + pos, rows[i], row_lengths[i]);
        pos += row_lengths[i];
    }
    return (int64_t)pos;
}
