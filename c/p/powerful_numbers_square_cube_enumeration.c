#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_WORDS 2
#define MAX_LIMIT 100
#define MAX_VALUES 14

static int is_squarefree(int64_t value) {
    for (int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % (divisor * divisor) == 0) return 0;
    }
    return 1;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t powerful_numbers_square_cube_enumeration(const int64_t *input,
        size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_WORDS || length != 1) return -1;
    const int64_t limit = input[0];
    if (limit < 1 || limit > MAX_LIMIT) return -1;

    int64_t values[MAX_VALUES] = {0};
    size_t count = 0;
    for (int64_t b = 1; b * b * b <= limit; ++b) {
        if (!is_squarefree(b)) continue;
        const int64_t cube = b * b * b;
        for (int64_t a = 1; a * a * cube <= limit; ++a)
            values[count++] = a * a * cube;
    }
    for (size_t index = 1; index < count; ++index) {
        const int64_t value = values[index];
        size_t position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }

    const size_t output_bytes = (count + 1) * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    store_i64_le(output, 0, (int64_t)count);
    for (size_t index = 0; index < count; ++index)
        store_i64_le(output, (index + 1) * 8, values[index]);
    return (int64_t)output_bytes;
}
