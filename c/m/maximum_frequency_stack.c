#include <stddef.h>
#include <stdint.h>

static void store_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[offset + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t maximum_frequency_stack(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 130) return -1;
    const int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > 64 || length != 1u + 2u * (size_t)raw_count) return -1;
    int frequency[17] = {0};
    int bucket_top[65];
    for (size_t i = 0; i < 65; ++i) bucket_top[i] = -1;
    int node_value[64], node_next[64], popped[64];
    size_t nodes = 0, pop_count = 0, position = 1;
    int maximum_frequency = 0;
    for (int64_t operation = 0; operation < raw_count; ++operation) {
        const int64_t opcode = input[position++];
        const int64_t argument = input[position++];
        if (opcode == 0) {
            if (argument < -8 || argument > 8) return -1;
            const int index = (int)argument + 8;
            const int next_frequency = ++frequency[index];
            node_value[nodes] = (int)argument;
            node_next[nodes] = bucket_top[next_frequency];
            bucket_top[next_frequency] = (int)nodes++;
            if (next_frequency > maximum_frequency) maximum_frequency = next_frequency;
        } else if (opcode == 1 && argument == 0) {
            if (maximum_frequency == 0 || bucket_top[maximum_frequency] < 0) return -1;
            const int node = bucket_top[maximum_frequency];
            bucket_top[maximum_frequency] = node_next[node];
            const int value = node_value[node];
            popped[pop_count++] = value;
            --frequency[value + 8];
            if (bucket_top[maximum_frequency] < 0) --maximum_frequency;
        } else {
            return -1;
        }
    }
    const size_t needed = pop_count * 8;
    if (needed != 0 && (output == NULL || capacity < needed)) return -2;
    for (size_t i = 0; i < pop_count; ++i) store_i64(output, i * 8, popped[i]);
    return (int64_t)needed;
}
