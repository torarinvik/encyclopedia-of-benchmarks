/* Count every pair of distinct indices whose values sum to the target. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 257

int64_t pairs_with_given_sum(const int64_t *input, size_t length)
{
    if (input == NULL || length == 0 || length > MAX_INPUT_LENGTH) return -2;
    for (size_t index = 0; index < length; ++index) {
        if (input[index] < INT64_C(-2147483648) || input[index] > INT64_C(2147483647)) return -2;
    }
    const int64_t target = input[0];
    const size_t value_count = length - 1;
    int64_t pairs = 0;
    for (size_t left = 0; left < value_count; ++left) {
        for (size_t right = left + 1; right < value_count; ++right) {
            if (input[left + 1] + input[right + 1] == target) ++pairs;
        }
    }
    return pairs;
}
