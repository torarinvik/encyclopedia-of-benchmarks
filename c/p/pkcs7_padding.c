/* Bounded AddPadding, RemovePadding, and GetPaddingCount source extraction. */
#include <stddef.h>
#include <stdint.h>

int64_t pkcs7_padding(const int64_t *input, size_t length, uint8_t *output,
                      size_t output_capacity)
{
    if (input == NULL || length < 5 || length > 69) return -1;
    const int64_t operation = input[0];
    const int64_t block_size_arg = input[1];
    const int64_t offset_arg = input[2];
    const int64_t data_length_arg = input[3];
    if (operation < 0 || operation > 2 || block_size_arg < 1 || block_size_arg > 16 ||
        data_length_arg < 1 || data_length_arg > 64 ||
        (operation == 0 && (offset_arg < 0 || offset_arg > data_length_arg)) ||
        length != (size_t)data_length_arg + 4) return -1;
    const size_t block_size = (size_t)block_size_arg;
    const size_t offset = operation == 0 ? (size_t)offset_arg : 0;
    const size_t data_length = (size_t)data_length_arg;
    for (size_t i = 0; i < data_length; ++i)
        if (input[4 + i] < 0 || input[4 + i] > 255) return -1;

    size_t padding_count;
    size_t output_length;
    if (operation == 0) {
        padding_count = block_size - data_length % block_size;
        if (offset + padding_count > data_length) return -1;
        output_length = data_length + 1;
    } else if (operation == 1) {
        if (data_length % block_size != 0) return -1;
        padding_count = (size_t)input[3 + data_length];
        if (padding_count == 0 || padding_count > block_size) return -1;
        for (size_t i = data_length - padding_count; i < data_length; ++i)
            if ((size_t)input[4 + i] != padding_count) return -1;
        output_length = data_length - padding_count;
    } else {
        padding_count = (size_t)input[3 + data_length];
        const int64_t padding_start = (int64_t)data_length - (int64_t)padding_count;
        const int64_t invalid_bits = padding_start | ((int64_t)padding_count - 1);
        int64_t padding_check_failed = -((int64_t)((uint32_t)(int32_t)invalid_bits >> 31));
        for (size_t i = 0; i < data_length; ++i) {
            const int64_t difference = (int64_t)i - padding_start;
            const uint32_t negative_bit = (uint32_t)(int32_t)difference >> 31;
            const int64_t mask = -(int64_t)(1u - negative_bit);
            padding_check_failed |= (input[4 + i] ^ (int64_t)padding_count) & mask;
        }
        if (padding_check_failed != 0) return -1;
        output_length = 1;
    }
    if (output == NULL || output_capacity < output_length) return -2;

    if (operation == 0) {
        output[0] = (uint8_t)padding_count;
        for (size_t i = 0; i < data_length; ++i) {
            const size_t out_index = i + 1;
            output[out_index] = i >= offset && i < offset + padding_count
                ? (uint8_t)padding_count : (uint8_t)input[4 + i];
        }
    } else if (operation == 1) {
        for (size_t i = 0; i < output_length; ++i)
            output[i] = (uint8_t)input[4 + i];
    } else {
        output[0] = (uint8_t)padding_count;
    }
    return (int64_t)output_length;
}
