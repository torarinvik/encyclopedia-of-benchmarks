#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define PEARSON_TABLE_SIZE 256
#define PEARSON_MAX_TEXT 64
#define PEARSON_MAX_WORDS (1 + PEARSON_TABLE_SIZE + PEARSON_MAX_TEXT)

int64_t pearson_hash(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 + PEARSON_TABLE_SIZE ||
        length > PEARSON_MAX_WORDS + 1) return -1;

    const int64_t count = input[0];
    if (count < 0 || count > PEARSON_MAX_TEXT ||
        length != 1 + PEARSON_TABLE_SIZE + (size_t)count) return -1;

    uint8_t table[PEARSON_TABLE_SIZE];
    bool seen[PEARSON_TABLE_SIZE] = { false };
    for (size_t index = 0; index < PEARSON_TABLE_SIZE; ++index) {
        const int64_t value = input[1 + index];
        if (value < 0 || value > 255 || seen[(size_t)value]) return -1;
        table[index] = (uint8_t)value;
        seen[(size_t)value] = true;
    }

    for (size_t index = 0; index < (size_t)count; ++index)
        if (input[1 + PEARSON_TABLE_SIZE + index] < 0 ||
            input[1 + PEARSON_TABLE_SIZE + index] > 255) return -1;

    uint8_t state = 0;
    for (size_t index = 0; index < (size_t)count; ++index) {
        const uint8_t byte = (uint8_t)input[1 + PEARSON_TABLE_SIZE + index];
        state = table[(uint8_t)(state ^ byte)];
    }
    return (int64_t)state;
}
