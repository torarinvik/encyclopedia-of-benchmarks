#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 16384

static int is_triangular_score(int64_t score)
{
    for (int64_t n = 1; n <= 100; ++n) {
        if (score == n * (n + 1) / 2) return 1;
    }
    return 0;
}

int64_t solution42(const int64_t *input, size_t input_length)
{
    if (input_length > MAX_INPUT_LENGTH) return -1;
    if (input_length == 0) return 0;
    if (input == NULL) return -1;

    for (size_t i = 0; i < input_length; ++i) {
        if (input[i] < 0 || input[i] > 127) return -1;
    }

    size_t first_line_length = 0;
    while (first_line_length < input_length && input[first_line_length] != 10 &&
           input[first_line_length] != 13) {
        ++first_line_length;
    }

    int64_t count = 0;
    size_t token_start = 0;
    for (size_t position = 0; position <= first_line_length; ++position) {
        if (position == first_line_length || input[position] == ',') {
            size_t start = token_start;
            size_t end = position;
            while (start < end && input[start] == '"') ++start;
            while (end > start && input[end - 1] == '"') --end;

            int64_t score = 0;
            for (size_t i = start; i < end; ++i) score += input[i] - 64;
            if (is_triangular_score(score)) ++count;
            token_start = position + 1;
        }
    }
    return count;
}
