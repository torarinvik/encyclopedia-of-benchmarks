/* Return the minimum cuts needed to split ASCII bytes into palindromes. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256

int64_t palindrome_partitioning(const int64_t *input, size_t length,
                                uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length == 0 || length > MAX_LENGTH) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < 0 || input[index] > 127) return -1;
    if (output == NULL || output_capacity < 8) return -2;

    uint8_t palindrome[MAX_LENGTH][MAX_LENGTH] = {{0}};
    int64_t cuts[MAX_LENGTH] = {0};
    for (size_t end = 0; end < length; ++end) {
        int64_t best = (int64_t)end;
        for (size_t start = 0; start <= end; ++start) {
            if (input[start] == input[end] &&
                (end - start < 2 || palindrome[start + 1][end - 1])) {
                palindrome[start][end] = 1;
                const int64_t candidate = start == 0 ? 0 : cuts[start - 1] + 1;
                if (candidate < best) best = candidate;
            }
        }
        cuts[end] = best;
    }

    const uint64_t bits = (uint64_t)cuts[length - 1];
    for (size_t byte = 0; byte < 8; ++byte)
        output[byte] = (uint8_t)(bits >> (8 * byte));
    return 1;
}
