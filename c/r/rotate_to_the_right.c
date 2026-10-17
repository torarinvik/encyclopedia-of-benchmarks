#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_N + 4)
#define MAX_OUTPUT_BYTES (8 * MAX_N)
#define MAX_PLACES INT64_C(1000000)

int64_t rotate_to_the_right(const int64_t *input, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    const int64_t places = input[1];
    if (n_value < 1 || n_value > MAX_N || places < -MAX_PLACES || places > MAX_PLACES) return -1;
    const size_t n = (size_t)n_value;
    if (length != n + 2) return -1;
    for (size_t index = 0; index < n; ++index)
        if (input[2 + index] < INT32_MIN || input[2 + index] > INT32_MAX) return -1;

    const int64_t remainder = places % n_value;
    const size_t shift = (size_t)(remainder < 0 ? remainder + n_value : remainder);
    const size_t output_bytes = n * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;

    uint8_t encoded[MAX_OUTPUT_BYTES];
    for (size_t index = 0; index < n; ++index) {
        const size_t source = (index + n - shift) % n;
        uint64_t bits = (uint64_t)input[2 + source];
        for (size_t byte = 0; byte < 8; ++byte) {
            encoded[index * 8 + byte] = (uint8_t)(bits & 255);
            bits >>= 8;
        }
    }
    for (size_t index = 0; index < output_bytes; ++index) output[index] = encoded[index];
    return (int64_t)output_bytes;
}
