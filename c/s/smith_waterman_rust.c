#include <stddef.h>
#include <stdint.h>

#define MAX_SEQUENCE_LENGTH 16u
#define MAX_PARSEABLE_INPUT_LENGTH 38u
#define MAX_OUTPUT_BYTES 1233u
#define SCORE_STRIDE 17u
#define MAX_TRACE_STEPS (2u * MAX_SEQUENCE_LENGTH)

static int is_ascii_letter_or_gap(int64_t value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') || value == '-';
}

static char uppercase_ascii(int64_t value) {
    if (value >= 'a' && value <= 'z') value -= ('a' - 'A');
    return (char)value;
}

static int32_t pair_score(char left, char right, int32_t match, int32_t mismatch, int32_t gap) {
    if (left == '-' || right == '-') return gap;
    return left == right ? match : mismatch;
}

static void write_u32_le(uint8_t *output, size_t offset, uint32_t value) {
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(value >> (byte * 8));
}

static void write_i32_le(uint8_t *output, size_t offset, int32_t value) {
    write_u32_le(output, offset, (uint32_t)value);
}

int64_t smith_waterman_rust(const int64_t *input, size_t input_length,
                            uint8_t *output, size_t output_capacity) {
    if (input == NULL || input_length < 5u || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t query_length_value = input[0];
    const int64_t subject_length_value = input[1];
    const int64_t match_value = input[2];
    const int64_t mismatch_value = input[3];
    const int64_t gap_value = input[4];
    if (query_length_value < 0 || query_length_value > (int64_t)MAX_SEQUENCE_LENGTH ||
        subject_length_value < 0 || subject_length_value > (int64_t)MAX_SEQUENCE_LENGTH ||
        match_value < 1 || match_value > 5 || mismatch_value < -5 || mismatch_value > -1 ||
        gap_value < -5 || gap_value > -1) return -1;
    const size_t query_length = (size_t)query_length_value;
    const size_t subject_length = (size_t)subject_length_value;
    if (input_length != 5u + query_length + subject_length || input_length > 37u) return -1;
    for (size_t i = 5; i < input_length; ++i) if (!is_ascii_letter_or_gap(input[i])) return -1;

    char query[MAX_SEQUENCE_LENGTH];
    char subject[MAX_SEQUENCE_LENGTH];
    for (size_t i = 0; i < query_length; ++i) query[i] = uppercase_ascii(input[5u + i]);
    for (size_t i = 0; i < subject_length; ++i)
        subject[i] = uppercase_ascii(input[5u + query_length + i]);

    const size_t rows = query_length + 1u;
    const size_t columns = subject_length + 1u;
    const int32_t match = (int32_t)match_value;
    const int32_t mismatch = (int32_t)mismatch_value;
    const int32_t gap = (int32_t)gap_value;
    int32_t scores[SCORE_STRIDE * SCORE_STRIDE] = {0};
    int32_t maximum = 0;
    size_t max_row = 0, max_column = 0;
    for (size_t row = 1; row < rows; ++row) {
        for (size_t column = 1; column < columns; ++column) {
            const int32_t diagonal = scores[(row - 1u) * SCORE_STRIDE + column - 1u] +
                pair_score(query[row - 1u], subject[column - 1u], match, mismatch, gap);
            const int32_t above = scores[(row - 1u) * SCORE_STRIDE + column] + gap;
            const int32_t left = scores[row * SCORE_STRIDE + column - 1u] + gap;
            int32_t value = diagonal;
            if (above > value) value = above;
            if (left > value) value = left;
            if (value < 0) value = 0;
            scores[row * SCORE_STRIDE + column] = value;
            if (value > maximum) { maximum = value; max_row = row; max_column = column; }
        }
    }

    char reverse_query[MAX_TRACE_STEPS];
    char reverse_subject[MAX_TRACE_STEPS];
    size_t trace_steps = 0;
    size_t row = max_row, column = max_column;
    while (row > 0 && column > 0 && scores[row * SCORE_STRIDE + column] > 0) {
        const int32_t current = scores[row * SCORE_STRIDE + column];
        const int32_t diagonal = scores[(row - 1u) * SCORE_STRIDE + column - 1u] +
            pair_score(query[row - 1u], subject[column - 1u], match, mismatch, gap);
        if (current == diagonal) {
            reverse_query[trace_steps] = query[row - 1u];
            reverse_subject[trace_steps] = subject[column - 1u];
            --row; --column;
        } else if (current == scores[(row - 1u) * SCORE_STRIDE + column] + gap) {
            reverse_query[trace_steps] = query[row - 1u];
            reverse_subject[trace_steps] = '-';
            --row;
        } else {
            reverse_query[trace_steps] = '-';
            reverse_subject[trace_steps] = subject[column - 1u];
            --column;
        }
        ++trace_steps;
    }

    uint8_t staged[MAX_OUTPUT_BYTES];
    write_u32_le(staged, 0, (uint32_t)rows);
    write_u32_le(staged, 4, (uint32_t)columns);
    size_t offset = 8;
    for (size_t r = 0; r < rows; ++r) {
        for (size_t c = 0; c < columns; ++c) {
            write_i32_le(staged, offset, scores[r * SCORE_STRIDE + c]);
            offset += 4;
        }
    }
    const size_t alignment_length = trace_steps == 0 ? 0 : 2u * trace_steps + 1u;
    write_u32_le(staged, offset, (uint32_t)alignment_length);
    offset += 4;
    if (trace_steps > 0) {
        for (size_t i = 0; i < trace_steps; ++i)
            staged[offset++] = (uint8_t)reverse_query[trace_steps - i - 1u];
        staged[offset++] = (uint8_t)'\n';
        for (size_t i = 0; i < trace_steps; ++i)
            staged[offset++] = (uint8_t)reverse_subject[trace_steps - i - 1u];
    }
    const size_t required = offset;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t i = 0; i < required; ++i) output[i] = staged[i];
    return (int64_t)required;
}
