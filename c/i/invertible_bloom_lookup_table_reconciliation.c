#include <stddef.h>
#include <stdint.h>

#define IBLT_SET_LIMIT 8
#define IBLT_KEY_LIMIT 63
#define IBLT_CELLS 48
#define IBLT_MAX_PEELS 16
#define IBLT_MAX_INPUT 18

static uint64_t iblt_checksum(int64_t key) {
    uint64_t x = (uint64_t)key;
    return x * x + 3 * x + 7;
}

static void iblt_locations(int64_t key, size_t slots[3]) {
    uint64_t x = (uint64_t)key;
    slots[0] = (size_t)(x % 16);
    slots[1] = 16 + (size_t)((3 * x + 5) % 16);
    slots[2] = 32 + (size_t)((5 * x + 9) % 16);
}

static void iblt_write_i64(uint8_t *output, size_t index, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[index * 8 + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t invertible_bloom_lookup_table_reconciliation(const int64_t *input,
        size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > IBLT_MAX_INPUT + 1) return -1;
    int64_t a0 = input[0], b0 = input[1];
    if (a0 < 0 || a0 > IBLT_SET_LIMIT || b0 < 0 || b0 > IBLT_SET_LIMIT) return -1;
    size_t a_count = (size_t)a0, b_count = (size_t)b0;
    if (length != 2 + a_count + b_count) return -1;
    int64_t previous = -1;
    for (size_t i = 0; i < a_count; ++i) {
        int64_t key = input[2 + i];
        if (key < 0 || key > IBLT_KEY_LIMIT || key <= previous) return -1;
        previous = key;
    }
    previous = -1;
    for (size_t i = 0; i < b_count; ++i) {
        int64_t key = input[2 + a_count + i];
        if (key < 0 || key > IBLT_KEY_LIMIT || key <= previous) return -1;
        previous = key;
    }

    int64_t counts[IBLT_CELLS] = {0};
    int64_t sums[IBLT_CELLS] = {0};
    int64_t checks[IBLT_CELLS] = {0};
    for (size_t side = 0; side < 2; ++side) {
        size_t n = side == 0 ? a_count : b_count;
        int64_t sign = side == 0 ? 1 : -1;
        size_t start = side == 0 ? 2 : 2 + a_count;
        for (size_t i = 0; i < n; ++i) {
            int64_t key = input[start + i];
            size_t slots[3]; iblt_locations(key, slots);
            uint64_t check = iblt_checksum(key);
            for (size_t j = 0; j < 3; ++j) {
                counts[slots[j]] += sign;
                sums[slots[j]] += sign * key;
                checks[slots[j]] += sign * (int64_t)check;
            }
        }
    }

    int64_t positive[IBLT_MAX_PEELS], negative[IBLT_MAX_PEELS];
    size_t positive_count = 0, negative_count = 0;
    int repeated = 0;
    for (size_t peel = 0; peel < IBLT_MAX_PEELS; ++peel) {
        int zero = 1;
        for (size_t i = 0; i < IBLT_CELLS; ++i)
            if (counts[i] != 0 || sums[i] != 0 || checks[i] != 0) { zero = 0; break; }
        if (zero) break;

        int found = 0;
        int64_t sign = 0, key = 0;
        for (size_t i = 0; i < IBLT_CELLS; ++i) {
            if (counts[i] != 1 && counts[i] != -1) continue;
            int64_t candidate_sign = counts[i];
            int64_t candidate = candidate_sign * sums[i];
            if (candidate < 0 || candidate > IBLT_KEY_LIMIT) continue;
            if (checks[i] != candidate_sign * (int64_t)iblt_checksum(candidate)) continue;
            sign = candidate_sign; key = candidate; found = 1; break;
        }
        if (!found) break;
        for (size_t i = 0; i < positive_count; ++i) if (positive[i] == key) repeated = 1;
        for (size_t i = 0; i < negative_count; ++i) if (negative[i] == key) repeated = 1;
        if (repeated) break;
        if (sign > 0) positive[positive_count++] = key;
        else negative[negative_count++] = key;
        size_t slots[3]; iblt_locations(key, slots);
        int64_t check = (int64_t)iblt_checksum(key);
        for (size_t j = 0; j < 3; ++j) {
            counts[slots[j]] -= sign;
            sums[slots[j]] -= sign * key;
            checks[slots[j]] -= sign * check;
        }
    }

    int zero = 1;
    for (size_t i = 0; i < IBLT_CELLS; ++i)
        if (counts[i] != 0 || sums[i] != 0 || checks[i] != 0) { zero = 0; break; }
    for (size_t i = 1; i < positive_count; ++i) {
        int64_t value = positive[i]; size_t j = i;
        while (j > 0 && positive[j - 1] > value) { positive[j] = positive[j - 1]; --j; }
        positive[j] = value;
    }
    for (size_t i = 1; i < negative_count; ++i) {
        int64_t value = negative[i]; size_t j = i;
        while (j > 0 && negative[j - 1] > value) { negative[j] = negative[j - 1]; --j; }
        negative[j] = value;
    }

    int64_t staged[3 + 2 * IBLT_MAX_PEELS];
    size_t words = 0;
    staged[words++] = (!repeated && zero) ? 1 : 0;
    staged[words++] = (int64_t)positive_count;
    staged[words++] = (int64_t)negative_count;
    for (size_t i = 0; i < positive_count; ++i) staged[words++] = positive[i];
    for (size_t i = 0; i < negative_count; ++i) staged[words++] = negative[i];
    size_t required = words * 8;
    if (output == NULL || capacity < required) return -2;
    for (size_t i = 0; i < words; ++i) iblt_write_i64(output, i, staged[i]);
    return (int64_t)required;
}
