#include <stddef.h>
#include <stdint.h>

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t sort_population(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 129 || input[0] < 1 || input[0] > 64) return -1;
    const size_t count = (size_t)input[0];
    if (length != 1 + 2 * count) return -1;
    int64_t costs[64], identifiers[64];
    uint8_t seen[64] = {0};
    for (size_t i = 0; i < count; ++i) {
        const int64_t cost = input[1 + 2 * i], identifier = input[2 + 2 * i];
        if (cost < -1000000 || cost > 1000000 || identifier < 0 || identifier >= (int64_t)count) return -1;
        if (seen[identifier]) return -1;
        seen[identifier] = 1;
        costs[i] = cost;
        identifiers[i] = identifier;
    }
    for (size_t i = 1; i < count; ++i) {
        const int64_t key_cost = costs[i], key_identifier = identifiers[i];
        size_t j = i;
        while (j > 0 && costs[j - 1] > key_cost) {
            costs[j] = costs[j - 1];
            identifiers[j] = identifiers[j - 1];
            --j;
        }
        costs[j] = key_cost;
        identifiers[j] = key_identifier;
    }
    for (size_t i = 1; i < count; ++i) if (costs[i - 1] == costs[i]) return -1;
    const size_t output_length = count * 16;
    if (output == NULL || capacity < output_length) return -2;
    for (size_t i = 0; i < count; ++i) {
        write_i64_le(output, i * 16, costs[i]);
        write_i64_le(output, i * 16 + 8, identifiers[i]);
    }
    return (int64_t)output_length;
}
