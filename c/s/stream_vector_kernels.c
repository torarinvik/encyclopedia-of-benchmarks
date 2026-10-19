#include <stddef.h>
#include <stdint.h>

enum { MAX_COUNT = 128, MAX_INPUT_LENGTH = 259, MAX_OUTPUT_BYTES = 1024 };

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t stream_vector_kernels(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t mode = input[0], count_value = input[1];
    if (mode < 0 || mode > 3 || count_value < 0 || count_value > MAX_COUNT) return -1;

    const size_t count = (size_t)count_value;
    const int has_alpha = mode == 1 || mode == 3;
    const size_t array_count = mode == 0 || mode == 1 ? 1u : 2u;
    const size_t expected_length = 2u + (size_t)has_alpha + array_count * count;
    if (length != expected_length) return -1;

    size_t a_start = 2u;
    int64_t alpha = 0;
    if (has_alpha) {
        alpha = input[2];
        if (alpha < -1000 || alpha > 1000) return -1;
        a_start = 3u;
    }
    const size_t b_start = a_start + count;
    for (size_t index = 0; index < array_count * count; ++index)
        if (input[a_start + index] < -1000 || input[a_start + index] > 1000) return -1;

    int64_t staged[MAX_COUNT];
    for (size_t index = 0; index < count; ++index) {
        const int64_t a = input[a_start + index];
        int64_t value;
        if (mode == 0) value = a;
        else if (mode == 1) value = alpha * a;
        else if (mode == 2) value = a + input[b_start + index];
        else value = a + alpha * input[b_start + index];
        /* Bounded operands keep every multiplication and sum inside int64. */
        staged[index] = value;
    }

    const size_t output_bytes = count * 8u;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t index = 0; index < count; ++index)
        write_i64_le(output, index * 8u, staged[index]);
    return (int64_t)output_bytes;
}
