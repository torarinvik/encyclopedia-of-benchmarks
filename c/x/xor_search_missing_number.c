#include <stddef.h>
#include <stdint.h>

#define MAX_N INT64_C(255)
#define MAX_INPUT_LENGTH 257

int64_t xor_search_missing_number(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_N || length != (size_t)(n_value + 1)) return -1;
    const size_t n = (size_t)n_value;
    uint8_t seen[256] = {0};
    int64_t result = n_value;
    for (size_t i = 0; i < n; ++i) {
        const int64_t value = input[i + 1];
        if (value < 0 || value > n_value || seen[value]) return -1;
        seen[value] = 1;
        result ^= (int64_t)i ^ value;
    }
    return result;
}
