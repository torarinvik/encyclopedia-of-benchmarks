#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 1024
#define INVALID_RESULT (-1)

static void store_i64_le(int64_t value, uint8_t *output)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t onepad_cipher(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > 2 + 2 * MAX_TEXT_LENGTH) return INVALID_RESULT;
    const int64_t mode = input[0], count_value = input[1];
    if ((mode != 0 && mode != 1) || count_value < 0 || count_value > MAX_TEXT_LENGTH) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    if (length != 2 + 2 * count) return INVALID_RESULT;
    const size_t needed = mode == 0 ? 8 * count : count;
    if (output_capacity < needed || (needed > 0 && output == NULL)) return -2;
    for (size_t index = 0; index < count; ++index) {
        const int64_t data = input[2 + index], key = input[2 + count + index];
        if (key < 1 || key > 300) return INVALID_RESULT;
        if (mode == 0) {
            if (data < 32 || data > 126) return INVALID_RESULT;
            const int64_t encrypted = (data + key) * key;
            store_i64_le(encrypted, output + 8 * index);
        } else {
            const int64_t key_square = key * key;
            if (data < key_square || (data - key_square) % key != 0) return INVALID_RESULT;
            const int64_t plain = (data - key_square) / key;
            if (plain < 32 || plain > 126) return INVALID_RESULT;
            output[index] = (uint8_t)plain;
        }
    }
    return (int64_t)needed;
}
