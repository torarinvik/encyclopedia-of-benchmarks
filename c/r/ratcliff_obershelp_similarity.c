#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 32, MAX_INPUT_LENGTH = 67 };

static int64_t longest_match(const int64_t *input, size_t first_base,
                             size_t second_base, size_t first_start,
                             size_t first_end, size_t second_start,
                             size_t second_end) {
    int64_t dp[MAX_TEXT + 1] = {0};
    size_t width = second_end - second_start;
    size_t best_length = 0, best_first = 0, best_second = 0;
    for (size_t i = first_start; i < first_end; ++i) {
        int64_t diagonal = 0;
        for (size_t column = 1; column <= width; ++column) {
            int64_t old = dp[column];
            size_t j = second_start + column - 1;
            if (input[first_base + i] == input[second_base + j]) {
                size_t current = (size_t)diagonal + 1;
                dp[column] = (int64_t)current;
                if (current > best_length) {
                    best_length = current;
                    best_first = i + 1 - current;
                    best_second = j + 1 - current;
                }
            } else dp[column] = 0;
            diagonal = old;
        }
    }
    return (int64_t)(best_length * 4096 + best_first * 64 + best_second);
}

static int64_t matched_characters(const int64_t *input, size_t first_base,
                                  size_t second_base, size_t a0, size_t a1,
                                  size_t b0, size_t b1) {
    if (a0 >= a1 || b0 >= b1) return 0;
    int64_t packed = longest_match(input, first_base, second_base, a0, a1, b0, b1);
    size_t block = (size_t)(packed / 4096);
    if (block == 0) return 0;
    size_t rest = (size_t)(packed % 4096), a = rest / 64, b = rest % 64;
    return (int64_t)block
        + matched_characters(input, first_base, second_base, a0, a, b0, b)
        + matched_characters(input, first_base, second_base, a + block, a1,
                             b + block, b1);
}

int64_t ratcliff_obershelp_similarity(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    int64_t first_raw = input[0], second_raw = input[1];
    if (first_raw < 0 || first_raw > MAX_TEXT || second_raw < 0 || second_raw > MAX_TEXT) return -1;
    size_t first_length = (size_t)first_raw, second_length = (size_t)second_raw;
    if (length != 2 + first_length + second_length) return -1;
    for (size_t i = 0; i < first_length + second_length; ++i)
        if (input[2 + i] < 1 || input[2 + i] > 127) return -1;
    if (first_length == 0 || second_length == 0) return 0;
    int64_t common = matched_characters(input, 2, 2 + first_length,
                                        0, first_length, 0, second_length);
    return (200 * common) / (int64_t)(first_length + second_length);
}
