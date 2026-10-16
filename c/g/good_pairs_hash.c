/* Count equal-value index pairs with a bounded open-addressed frequency table. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAY_LENGTH 256
#define MAX_INPUT_LENGTH 258
#define TABLE_SIZE 512
#define MAX_VALUE INT64_C(1000000)

int64_t good_pairs_hash(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t declared = input[0];
    if (declared < 0 || declared > MAX_ARRAY_LENGTH || length != (size_t)declared + 1) return -1;
    const size_t count = (size_t)declared;
    int64_t keys[TABLE_SIZE] = {0};
    uint64_t frequencies[TABLE_SIZE] = {0};
    uint8_t occupied[TABLE_SIZE] = {0};
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 1];
        if (value < -MAX_VALUE || value > MAX_VALUE) return -1;
        size_t slot = (size_t)(((uint64_t)(value + MAX_VALUE) * UINT64_C(2654435761)) & (TABLE_SIZE - 1));
        while (occupied[slot] && keys[slot] != value) slot = (slot + 1) & (TABLE_SIZE - 1);
        if (!occupied[slot]) { occupied[slot] = 1; keys[slot] = value; }
        ++frequencies[slot];
    }
    uint64_t pairs = 0;
    for (size_t slot = 0; slot < TABLE_SIZE; ++slot) {
        const uint64_t frequency = frequencies[slot];
        if (frequency > 1) pairs += frequency * (frequency - 1) / 2;
    }
    return (int64_t)pairs;
}
