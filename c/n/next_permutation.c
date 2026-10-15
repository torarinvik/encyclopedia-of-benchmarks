/* Replace a permutation by its lexicographic successor, wrapping to minimum. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 128

static void reverse(int32_t *values, size_t left, size_t right)
{
    while (left < right) {
        const int32_t temporary = values[left];
        values[left++] = values[right];
        values[right--] = temporary;
    }
}

static void store_i32_le(uint8_t *output, size_t position, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte) output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t next_permutation(const int64_t *input, size_t length,
                         uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_LENGTH + 1) return -1;
    if (input[0] < 0 || input[0] > MAX_LENGTH || length != (size_t)input[0] + 1) return -1;
    const size_t n = (size_t)input[0];
    int32_t values[MAX_LENGTH];
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 1] < INT32_MIN || input[i + 1] > INT32_MAX) return -1;
        values[i] = (int32_t)input[i + 1];
    }
    const size_t required = n * 4;
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;
    size_t pivot = n;
    for (size_t index = n; index > 1; --index) {
        if (values[index - 2] < values[index - 1]) { pivot = index - 2; break; }
    }
    if (pivot == n) {
        if (n > 1) reverse(values, 0, n - 1);
    } else {
        size_t successor = n - 1;
        while (values[successor] <= values[pivot]) --successor;
        const int32_t temporary = values[pivot];
        values[pivot] = values[successor];
        values[successor] = temporary;
        reverse(values, pivot + 1, n - 1);
    }
    for (size_t i = 0; i < n; ++i) store_i32_le(output, i * 4, values[i]);
    return (int64_t)n;
}
