#include <stddef.h>
#include <stdint.h>

#define MAX_SEQUENCE_LENGTH 4096
#define MAX_PACKED_LENGTH 8194

static int is_unicode_scalar(int64_t value)
{
    return value >= 0 && value <= 1114111 && !(value >= 55296 && value <= 57343);
}

int64_t is_subsequence(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_PACKED_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_SEQUENCE_LENGTH ||
        input[1] < 0 || input[1] > MAX_SEQUENCE_LENGTH) return -1;
    const size_t main_length = (size_t)input[0];
    const size_t subsequence_length = (size_t)input[1];
    if (length != 2 + main_length + subsequence_length) return -1;
    for (size_t index = 2; index < length; ++index)
        if (!is_unicode_scalar(input[index])) return -1;

    const size_t subsequence_start = 2 + main_length;
    size_t main_index = 0, subsequence_index = 0;
    while (subsequence_index < subsequence_length && main_index < main_length) {
        if (input[subsequence_start + subsequence_index] == input[2 + main_index]) ++subsequence_index;
        ++main_index;
    }
    return subsequence_index == subsequence_length ? 1 : 0;
}
