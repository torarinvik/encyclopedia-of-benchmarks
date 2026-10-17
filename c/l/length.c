#include <stddef.h>
#include <stdint.h>

#define MAX_PAYLOAD_BYTES 256
#define MAX_INPUT_LENGTH 259
#define OUTPUT_BYTES 16

static int64_t utf8_scalar_count(const uint8_t *bytes, size_t length)
{
    size_t index = 0;
    int64_t count = 0;
    while (index < length) {
        const uint8_t lead = bytes[index];
        if (lead >= 1 && lead <= 0x7f) {
            ++index;
        } else if (lead >= 0xc2 && lead <= 0xdf) {
            if (index + 1 >= length || bytes[index + 1] < 0x80 || bytes[index + 1] > 0xbf) return -1;
            index += 2;
        } else if (lead >= 0xe0 && lead <= 0xef) {
            if (index + 2 >= length) return -1;
            const uint8_t second = bytes[index + 1], third = bytes[index + 2];
            if (second < 0x80 || second > 0xbf || third < 0x80 || third > 0xbf ||
                (lead == 0xe0 && second < 0xa0) || (lead == 0xed && second > 0x9f)) return -1;
            index += 3;
        } else {
            return -1;
        }
        ++count;
    }
    return count;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t length(const int64_t *input, size_t input_length,
               uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_PAYLOAD_BYTES) return -1;
    const size_t payload_length = (size_t)input[0];
    if (input_length != payload_length + 2) return -1;

    uint8_t payload[MAX_PAYLOAD_BYTES];
    for (size_t index = 0; index <= payload_length; ++index) {
        const int64_t value = input[index + 1];
        if (value < 0 || value > 255) return -1;
        if (index == payload_length) {
            if (value != 0) return -1;
        } else {
            if (value == 0) return -1;
            payload[index] = (uint8_t)value;
        }
    }
    const int64_t scalar_count = utf8_scalar_count(payload, payload_length);
    if (scalar_count < 0) return -1;
    if (output == NULL || output_capacity < OUTPUT_BYTES) return -2;

    put_i64_le(output, 0, (int64_t)payload_length);
    put_i64_le(output, 8, scalar_count);
    return OUTPUT_BYTES;
}
