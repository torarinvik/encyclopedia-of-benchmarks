/* Clean-room bounded implementation of the Library Checker sequence-counting task. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_M = 64, MAX_INPUT_LENGTH = 130 };
static const int64_t MOD = 998244353;

int64_t number_of_increasing_sequences_between_two_sequences(const int64_t *input, size_t length)
{
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_M) return -1;
    const size_t n = (size_t)input[0], m = (size_t)input[1];
    if (length != 2 + 2 * n) return -1;

    int64_t lower[MAX_N], upper[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        lower[i] = input[2 + i];
        upper[i] = input[2 + n + i];
        if (lower[i] < 0 || lower[i] >= upper[i] || upper[i] > (int64_t)m) return -1;
    }

    int64_t first[MAX_M] = {0}, second[MAX_M] = {0};
    int64_t *previous = first, *current = second;
    for (size_t value = (size_t)lower[0]; value < (size_t)upper[0]; ++value) previous[value] = 1;
    for (size_t position = 1; position < n; ++position) {
        int64_t prefix = 0;
        for (size_t value = 0; value < m; ++value) {
            prefix += previous[value];
            if (prefix >= MOD) prefix -= MOD;
            current[value] = (lower[position] <= (int64_t)value && (int64_t)value < upper[position]) ? prefix : 0;
        }
        int64_t *temporary = previous;
        previous = current;
        current = temporary;
    }
    int64_t answer = 0;
    for (size_t value = 0; value < m; ++value) {
        answer += previous[value];
        if (answer >= MOD) answer -= MOD;
    }
    return answer;
}
