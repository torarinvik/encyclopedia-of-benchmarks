#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 97
#define MAX_TEXT 64
#define BOARD_SIZE 30
#define MAX_OUTPUT 128

static int parse_board(const int64_t *input, size_t length, int *hole_a, int *hole_b,
                       int64_t *text_length, int64_t *mode)
{
    if (input == NULL || length < 32 || length > MAX_INPUT) return 0;
    *mode = input[0];
    if (*mode != 0 && *mode != 1) return 0;
    int holes = 0;
    for (int position = 0; position < BOARD_SIZE; ++position) {
        const int64_t value = input[1 + position];
        if (position < 10 && value == 0) {
            if (holes == 0) *hole_a = position;
            else if (holes == 1) *hole_b = position;
            ++holes;
            continue;
        }
        if (value < 32 || value > 126) return 0;
        for (int prior = 0; prior < position; ++prior)
            if (input[1 + prior] == value) return 0;
    }
    if (holes != 2) return 0;
    *text_length = input[31];
    if (*text_length < 0 || *text_length > MAX_TEXT) return 0;
    return length == (size_t)(32 + *text_length);
}

static int find_symbol(const int64_t *input, int64_t value)
{
    for (int position = 0; position < BOARD_SIZE; ++position)
        if (input[1 + position] != 0 && input[1 + position] == value) return position;
    return -1;
}

static int decoded_length(const int64_t *input, int64_t text_length, int hole_a,
                          int hole_b, int *result_length)
{
    int output_length = 0;
    for (int64_t i = 0; i < text_length; ++i) {
        const int64_t value = input[32 + i];
        if (value < '0' || value > '9') return 0;
        const int column = (int)(value - '0');
        if (input[1 + column] != 0) {
            ++output_length;
            continue;
        }
        if (i + 1 >= text_length) return 0;
        const int64_t next = input[32 + i + 1];
        if (next < '0' || next > '9') return 0;
        const int row = column == hole_a ? 1 : (column == hole_b ? 2 : 0);
        if (row == 0) return 0;
        ++output_length;
        ++i;
    }
    *result_length = output_length;
    return 1;
}

int64_t straddling_checkerboard_transducer(const int64_t *input, size_t length,
                                            uint8_t *output, size_t output_capacity)
{
    int hole_a = -1, hole_b = -1;
    int64_t text_length = 0, mode = -1;
    if (!parse_board(input, length, &hole_a, &hole_b, &text_length, &mode)) return -1;

    int result_length = 0;
    if (mode == 0) {
        for (int64_t i = 0; i < text_length; ++i) {
            const int position = find_symbol(input, input[32 + i]);
            if (position < 0) return -1;
            result_length += position < 10 ? 1 : 2;
        }
    } else if (!decoded_length(input, text_length, hole_a, hole_b, &result_length)) {
        return -1;
    }

    if (result_length > MAX_OUTPUT) return -1;
    if (output == NULL || output_capacity < (size_t)result_length) return -2;

    if (mode == 0) {
        size_t out = 0;
        for (int64_t i = 0; i < text_length; ++i) {
            const int position = find_symbol(input, input[32 + i]);
            if (position < 10) {
                output[out++] = (uint8_t)('0' + position);
            } else {
                const int row_digit = position < 20 ? hole_a : hole_b;
                output[out++] = (uint8_t)('0' + row_digit);
                output[out++] = (uint8_t)('0' + (position % 10));
            }
        }
    } else {
        size_t out = 0;
        for (int64_t i = 0; i < text_length; ++i) {
            const int column = (int)(input[32 + i] - '0');
            if (input[1 + column] != 0) {
                output[out++] = (uint8_t)input[1 + column];
            } else {
                const int row = column == hole_a ? 1 : 2;
                const int next_column = (int)(input[32 + ++i] - '0');
                output[out++] = (uint8_t)input[1 + row * 10 + next_column];
            }
        }
    }
    return result_length;
}
