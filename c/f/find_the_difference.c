/* Return the lowercase byte added to t by subtracting the two character sums. */
#include <stddef.h>
#include <stdint.h>

#define MAX_STRING_LENGTH 4096
#define MAX_PACKED_LENGTH (2 + 2 * MAX_STRING_LENGTH + 1)

int64_t find_the_difference(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_PACKED_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_STRING_LENGTH ||
        input[1] < 1 || input[1] > MAX_STRING_LENGTH + 1) return -1;
    const size_t s_length = (size_t)input[0];
    const size_t t_length = (size_t)input[1];
    if (t_length != s_length + 1 || length != 2 + s_length + t_length) return -1;
    int64_t sum_s = 0, sum_t = 0;
    for (size_t index = 0; index < s_length; ++index) {
        const int64_t value = input[2 + index];
        if (value < 97 || value > 122) return -1;
        sum_s += value;
    }
    const size_t t_start = 2 + s_length;
    for (size_t index = 0; index < t_length; ++index) {
        const int64_t value = input[t_start + index];
        if (value < 97 || value > 122) return -1;
        sum_t += value;
    }
    const int64_t difference = sum_t - sum_s;
    return difference >= 97 && difference <= 122 ? difference : -1;
}
