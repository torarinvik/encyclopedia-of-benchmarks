#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 67
#define MAX_SIDE 32
#define MIN_VALUE (-16)
#define MAX_VALUE 16

int64_t longest_common_increasing_subsequence(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    const int64_t m_value = input[1];
    if (n_value < 0 || n_value > MAX_SIDE || m_value < 0 || m_value > MAX_SIDE) return -1;
    const size_t n = (size_t)n_value;
    const size_t m = (size_t)m_value;
    if (length != 2 + n + m) return -1;
    for (size_t index = 0; index < n + m; ++index) {
        if (input[2 + index] < MIN_VALUE || input[2 + index] > MAX_VALUE) return -1;
    }

    int64_t ending_at[MAX_SIDE] = {0};
    for (size_t i = 0; i < n; ++i) {
        const int64_t value = input[2 + i];
        int64_t best_smaller = 0;
        for (size_t j = 0; j < m; ++j) {
            const int64_t other = input[2 + n + j];
            if (value > other && ending_at[j] > best_smaller) {
                best_smaller = ending_at[j];
            } else if (value == other && best_smaller + 1 > ending_at[j]) {
                ending_at[j] = best_smaller + 1;
            }
        }
    }
    int64_t answer = 0;
    for (size_t j = 0; j < m; ++j) if (ending_at[j] > answer) answer = ending_at[j];
    return answer;
}
