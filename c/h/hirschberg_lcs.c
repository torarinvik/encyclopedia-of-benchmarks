#include <stddef.h>
#include <stdint.h>

enum { MAX_SEQUENCE_LENGTH = 64, MAX_INPUT_LENGTH = 132 };

typedef struct {
    int32_t forward[MAX_SEQUENCE_LENGTH + 1];
    int32_t backward[MAX_SEQUENCE_LENGTH + 1];
    uint8_t result[MAX_SEQUENCE_LENGTH];
    size_t result_length;
} HirschbergState;

static void lcs_row(const int64_t *a, size_t a0, size_t a1,
                    const int64_t *b, size_t b0, size_t b1,
                    int reverse_a, int reverse_b, int32_t *row)
{
    const size_t width = b1 - b0;
    for (size_t j = 0; j <= width; ++j) row[j] = 0;
    for (size_t i = 0; i < a1 - a0; ++i) {
        const int64_t av = reverse_a ? a[a1 - 1 - i] : a[a0 + i];
        int32_t diagonal = 0;
        for (size_t j = 1; j <= width; ++j) {
            const int32_t above = row[j];
            const int64_t bv = reverse_b ? b[b1 - j] : b[b0 + j - 1];
            if (av == bv) row[j] = diagonal + 1;
            else if (row[j - 1] > row[j]) row[j] = row[j - 1];
            diagonal = above;
        }
    }
}

static void recover_lcs(const int64_t *a, size_t a0, size_t a1,
                        const int64_t *b, size_t b0, size_t b1,
                        HirschbergState *state)
{
    const size_t a_length = a1 - a0;
    const size_t b_length = b1 - b0;
    if (a_length == 0 || b_length == 0) return;
    if (a_length == 1) {
        for (size_t j = b0; j < b1; ++j) {
            if (a[a0] == b[j]) {
                state->result[state->result_length++] = (uint8_t)a[a0];
                return;
            }
        }
        return;
    }

    const size_t middle = a0 + a_length / 2;
    lcs_row(a, a0, middle, b, b0, b1, 0, 0, state->forward);
    lcs_row(a, middle, a1, b, b0, b1, 1, 1, state->backward);
    size_t split = 0;
    int32_t best_score = -1;
    for (size_t j = 0; j <= b_length; ++j) {
        const int32_t score = state->forward[j] + state->backward[b_length - j];
        if (score > best_score) {
            best_score = score;
            split = j;
        }
    }
    recover_lcs(a, a0, middle, b, b0, b0 + split, state);
    recover_lcs(a, middle, a1, b, b0 + split, b1, state);
}

int64_t hirschberg_lcs(const int64_t *input, size_t length,
                       uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_SEQUENCE_LENGTH
        || input[1] < 0 || input[1] > MAX_SEQUENCE_LENGTH) return -1;
    const size_t first_length = (size_t)input[0];
    const size_t second_length = (size_t)input[1];
    if (length != 2 + first_length + second_length) return -1;
    const int64_t *first = input + 2;
    const int64_t *second = first + first_length;
    for (size_t i = 0; i < first_length + second_length; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 127) return -1;

    HirschbergState state = {0};
    const int64_t *a = first;
    const int64_t *b = second;
    size_t a_length = first_length;
    size_t b_length = second_length;
    if (a_length < b_length) {
        a = second;
        b = first;
        a_length = second_length;
        b_length = first_length;
    }
    recover_lcs(a, 0, a_length, b, 0, b_length, &state);
    if (output == NULL || capacity < state.result_length) return -2;
    for (size_t i = 0; i < state.result_length; ++i) output[i] = state.result[i];
    return (int64_t)state.result_length;
}
