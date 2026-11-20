#include <stddef.h>
#include <stdint.h>

#define MAX_SEED 100000
#define MAX_VALUE 100000
#define MAX_TRANSITIONS 4096
#define MAX_INPUT_LENGTH 3
#define MAX_TERMS (MAX_TRANSITIONS + 1)
#define TABLE_BYTES 24

static int64_t aliquot_sum(int64_t value) {
    if (value == 1) return 0;
    int64_t sum = 1;
    for (int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) {
            sum += divisor;
            int64_t partner = value / divisor;
            if (partner != divisor) sum += partner;
        }
    }
    return sum;
}

static void store_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t aliquot_orbit_decomposition(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (length != 2 || input[0] < 1 || input[0] > MAX_SEED ||
        input[1] < 1 || input[1] > MAX_TRANSITIONS) return -1;

    int64_t keys[MAX_TERMS];
    int64_t first_indices[MAX_TERMS];
    size_t key_count = 0;
    int64_t words[3] = {0, 0, 0};
    int64_t current = input[0];
    int64_t max_transitions = input[1];
    int64_t transitions = 0;
    int64_t positive_term_count = 0;

    for (;;) {
        if (current == 0) {
            words[0] = 0;
            words[1] = positive_term_count;
            break;
        }
        size_t low = 0, high = key_count;
        while (low < high) {
            size_t middle = low + (high - low) / 2;
            if (keys[middle] < current) low = middle + 1;
            else high = middle;
        }
        if (low < key_count && keys[low] == current) {
            words[0] = 1;
            words[1] = first_indices[low];
            words[2] = transitions - first_indices[low];
            break;
        }
        for (size_t i = key_count; i > low; --i) {
            keys[i] = keys[i - 1];
            first_indices[i] = first_indices[i - 1];
        }
        keys[low] = current;
        first_indices[low] = transitions;
        ++key_count;
        ++positive_term_count;
        if (transitions >= max_transitions) {
            words[0] = -3;
            words[1] = transitions;
            words[2] = current;
            break;
        }
        int64_t next_value = aliquot_sum(current);
        ++transitions;
        if (next_value > MAX_VALUE) {
            words[0] = -2;
            words[1] = transitions;
            words[2] = next_value;
            break;
        }
        current = next_value;
    }

    if (output == NULL || capacity < TABLE_BYTES) return -2;
    for (size_t word = 0; word < 3; ++word) store_i64(output, word * 8, words[word]);
    return TABLE_BYTES;
}
