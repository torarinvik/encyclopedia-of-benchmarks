#include <stddef.h>
#include <stdint.h>

#define PGP_MOD INT64_C(998244353)
#define PGP_MAX_STATES 7

static int64_t pgp_pow_mod(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % PGP_MOD;
        base = base * base % PGP_MOD;
        exponent >>= 1;
    }
    return result;
}

static int pgp_find_state(const int64_t codes[PGP_MAX_STATES],
                          const int64_t lengths[PGP_MAX_STATES], size_t count,
                          int64_t code, int64_t length) {
    for (size_t i = 0; i < count; ++i)
        if (codes[i] == code && lengths[i] == length) return (int)i;
    return -1;
}

static int64_t pgp_solve(int64_t word_length, int64_t first, int64_t second) {
    int64_t codes[PGP_MAX_STATES] = {0};
    int64_t lengths[PGP_MAX_STATES] = {0};
    size_t state_count = 1; /* The empty suffix. */
    const int64_t masks[2] = {first, second};

    for (int64_t prefix_length = 1; prefix_length < word_length; ++prefix_length) {
        for (size_t which = 0; which < 2; ++which) {
            const int64_t code = masks[which] >> (word_length - prefix_length);
            if (pgp_find_state(codes, lengths, state_count, code, prefix_length) < 0) {
                codes[state_count] = code;
                lengths[state_count] = prefix_length;
                ++state_count;
            }
        }
    }

    int64_t matrix[PGP_MAX_STATES][PGP_MAX_STATES + 1] = {{0}};
    for (size_t row = 0; row < state_count; ++row) {
        for (size_t column = 0; column < state_count; ++column)
            matrix[row][column] = row == column ? 2 : 0;
        for (int64_t bit = 0; bit <= 1; ++bit) {
            const int64_t candidate = (codes[row] << 1) | bit;
            const int64_t candidate_length = lengths[row] + 1;
            if (candidate_length == word_length && candidate == first) {
                ++matrix[row][state_count];
                continue;
            }
            if (candidate_length == word_length && candidate == second) continue;

            int64_t suffix_length = candidate_length;
            if (suffix_length > word_length - 1) suffix_length = word_length - 1;
            int destination = -1;
            for (; suffix_length >= 0 && destination < 0; --suffix_length) {
                const int64_t suffix_mask = (INT64_C(1) << suffix_length) - 1;
                const int64_t suffix = candidate & suffix_mask;
                destination = pgp_find_state(codes, lengths, state_count,
                                             suffix, suffix_length);
            }
            if (destination < 0) {
                /* The empty prefix is always the fallback suffix. */
                destination = 0;
            }
            matrix[row][destination] = (matrix[row][destination] - 1 + PGP_MOD) % PGP_MOD;
        }
    }

    for (size_t column = 0; column < state_count; ++column) {
        size_t pivot = column;
        while (pivot < state_count && matrix[pivot][column] == 0) ++pivot;
        if (pivot == state_count) return -1;
        if (pivot != column) {
            for (size_t j = 0; j <= state_count; ++j) {
                const int64_t temporary = matrix[column][j];
                matrix[column][j] = matrix[pivot][j];
                matrix[pivot][j] = temporary;
            }
        }
        const int64_t inverse = pgp_pow_mod(matrix[column][column], PGP_MOD - 2);
        for (size_t j = column; j <= state_count; ++j)
            matrix[column][j] = matrix[column][j] * inverse % PGP_MOD;
        for (size_t row = 0; row < state_count; ++row) {
            if (row == column) continue;
            const int64_t factor = matrix[row][column];
            for (size_t j = column; j <= state_count; ++j) {
                const int64_t product = factor * matrix[column][j] % PGP_MOD;
                matrix[row][j] = (matrix[row][j] - product + PGP_MOD) % PGP_MOD;
            }
        }
    }
    return matrix[0][state_count];
}

int64_t penney_game_pattern_probability(const int64_t *input, size_t length) {
    if (input == NULL || length != 3) return -1;
    const int64_t word_length = input[0];
    if (word_length < 1 || word_length > 4) return -1;
    const int64_t limit = INT64_C(1) << word_length;
    const int64_t first = input[1], second = input[2];
    if (first < 0 || second < 0 || first >= limit || second >= limit || first == second)
        return -1;
    return pgp_solve(word_length, first, second);
}
