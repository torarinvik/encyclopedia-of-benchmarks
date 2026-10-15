#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_VALUES 66
#define MAX_ENCODED_LENGTH 82
#define MAX_DECODED_LENGTH 52
#define MAX_U32 UINT64_C(4294967295)

static int decode_group(const int64_t *values, size_t start, size_t count, uint32_t *decoded)
{
    uint64_t value = 0;
    for (size_t index = 0; index < 5; ++index) {
        uint64_t digit = 84;
        if (index < count) {
            const int64_t byte = values[start + index];
            if (byte < 33 || byte > 117) return 0;
            digit = (uint64_t)(byte - 33);
        }
        value = value * 85 + digit;
    }
    if (value > MAX_U32) return 0;
    *decoded = (uint32_t)value;
    return 1;
}

int64_t base85(const int64_t *values, size_t length, uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_VALUES) return -1;
    const int64_t mode = values[0];
    const size_t payload_length = length - 1;
    size_t output_length = 0;

    if (mode == 0) {
        for (size_t index = 1; index < length; ++index)
            if (values[index] < 0 || values[index] > 255) return -1;
        const size_t remainder = payload_length % 4;
        output_length = (payload_length / 4) * 5 + (remainder == 0 ? 0 : remainder + 1);
    } else if (mode == 1) {
        if (payload_length % 5 == 1) return -1;
        for (size_t offset = 0; offset < payload_length;) {
            const size_t count = payload_length - offset < 5 ? payload_length - offset : 5;
            uint32_t ignored;
            if (count == 1 || !decode_group(values, offset + 1, count, &ignored)) return -1;
            output_length += count == 5 ? 4 : count - 1;
            offset += count;
        }
        if (output_length > MAX_DECODED_LENGTH) return -1;
    } else {
        return -1;
    }

    if (output_capacity < output_length || (output_length != 0 && output == NULL)) return -2;
    size_t written = 0;
    if (mode == 0) {
        static const uint32_t powers[5] = {UINT32_C(52200625), UINT32_C(614125),
                                           UINT32_C(7225), UINT32_C(85), UINT32_C(1)};
        for (size_t offset = 0; offset < payload_length; offset += 4) {
            const size_t count = payload_length - offset < 4 ? payload_length - offset : 4;
            uint32_t value = 0;
            for (size_t byte = 0; byte < 4; ++byte) {
                value <<= 8;
                if (byte < count) value |= (uint32_t)values[offset + byte + 1];
            }
            for (size_t digit = 0; digit < 5; ++digit) {
                const uint8_t encoded = (uint8_t)(value / powers[digit] + 33);
                value %= powers[digit];
                if (count == 4 || digit < count + 1) output[written++] = encoded;
            }
        }
    } else {
        for (size_t offset = 0; offset < payload_length;) {
            const size_t count = payload_length - offset < 5 ? payload_length - offset : 5;
            uint32_t value;
            (void)decode_group(values, offset + 1, count, &value);
            const size_t byte_count = count == 5 ? 4 : count - 1;
            for (size_t byte = 0; byte < byte_count; ++byte)
                output[written++] = (uint8_t)(value >> (24 - 8 * byte));
            offset += count;
        }
    }
    return (int64_t)written;
}
