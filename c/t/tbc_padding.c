#include <stddef.h>
#include <stdint.h>

#define MAX_BYTES 256
#define MAX_INPUT_VALUES (MAX_BYTES + 3)

static void write_i64_le(uint8_t *output, size_t position, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[position + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tbc_padding(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_VALUES) return -1;
    const int64_t operation = input[0], offset_value = input[1], count_value = input[2];
    if (operation < 0 || operation > 2 || count_value < 0 || count_value > MAX_BYTES ||
        length != (size_t)count_value + 3) return -1;
    const size_t count = (size_t)count_value;
    if ((operation == 0 && (count == 0 || offset_value < 0 || offset_value > count_value)) ||
        (operation != 0 && offset_value != 0) || (operation == 2 && count == 0)) return -1;
    for (size_t i = 0; i < count; ++i) if (input[i + 3] < 0 || input[i + 3] > 255) return -1;

    if (operation == 0) {
        const size_t offset = (size_t)offset_value;
        const int last_bit = (int)(input[offset > 0 ? offset + 2 : count + 2] & 1);
        const uint8_t code = last_bit == 0 ? 0xff : 0x00;
        const size_t needed = 8 + count;
        if (output == NULL || capacity < needed) return -2;
        write_i64_le(output, 0, (int64_t)(count - offset));
        for (size_t i = 0; i < count; ++i) output[8 + i] = i >= offset ? code : (uint8_t)input[3 + i];
        return (int64_t)needed;
    }

    if (operation == 1) {
        uint8_t code = 0;
        size_t survivor_count = count;
        if (count > 0) {
            code = (input[2 + count] & 1) == 0 ? 0x00 : 0xff;
            while (survivor_count > 0 && input[2 + survivor_count] == code) --survivor_count;
        }
        if (output == NULL || capacity < survivor_count) return -2;
        for (size_t i = 0; i < survivor_count; ++i) output[i] = (uint8_t)input[3 + i];
        return (int64_t)survivor_count;
    }

    const int64_t terminal = input[2 + count];
    if (terminal != 0 && terminal != 255) return -1;
    size_t padding_count = 0;
    while (padding_count < count && input[2 + count - padding_count] == terminal) ++padding_count;
    if (output == NULL || capacity < 8) return -2;
    write_i64_le(output, 0, (int64_t)padding_count);
    return 8;
}
