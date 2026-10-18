#include <stddef.h>
#include <stdint.h>

#define MAX_SEQUENCE_LENGTH 16
#define MAX_PARSEABLE_INPUT_LENGTH 38
#define SCORE_STRIDE 17

int64_t smith_waterman_java(const int64_t *input, size_t length)
{
    if (input == NULL || length < 5 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t query_length_value = input[0];
    const int64_t subject_length_value = input[1];
    const int64_t match_score = input[2];
    const int64_t mismatch_score = input[3];
    const int64_t gap_score = input[4];
    if (query_length_value < 0 || query_length_value > MAX_SEQUENCE_LENGTH ||
        subject_length_value < 0 || subject_length_value > MAX_SEQUENCE_LENGTH ||
        match_score < 1 || match_score > 5 || mismatch_score < -5 || mismatch_score > -1 ||
        gap_score < -5 || gap_score > -1) return -1;
    const size_t query_length = (size_t)query_length_value;
    const size_t subject_length = (size_t)subject_length_value;
    if (length != 5 + query_length + subject_length) return -1;
    for (size_t index = 5; index < length; ++index) {
        const int64_t value = input[index];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') || value == '-')) return -1;
    }

    int64_t scores[SCORE_STRIDE * SCORE_STRIDE] = {0};
    int64_t maximum = 0;
    for (size_t row = 1; row <= query_length; ++row) {
        for (size_t column = 1; column <= subject_length; ++column) {
            const int64_t query_char = input[4 + row];
            const int64_t subject_char = input[4 + query_length + column];
            const int64_t pair_score = query_char == subject_char ? match_score : mismatch_score;
            const int64_t diagonal = scores[(row - 1) * SCORE_STRIDE + column - 1] + pair_score;
            const int64_t above = scores[(row - 1) * SCORE_STRIDE + column] + gap_score;
            const int64_t left = scores[row * SCORE_STRIDE + column - 1] + gap_score;
            int64_t value = diagonal;
            if (above > value) value = above;
            if (left > value) value = left;
            if (value < 0) value = 0;
            scores[row * SCORE_STRIDE + column] = value;
            if (value > maximum) maximum = value;
        }
    }
    return maximum;
}
