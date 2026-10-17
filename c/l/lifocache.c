#include <stddef.h>
#include <stdint.h>

#define MAX_CAPACITY 16
#define MAX_OPS 64

static void put_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) out[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t lifocache(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > 2 + 3 * MAX_OPS) return -1;
    int64_t capacity_value = input[0], operation_count_value = input[1];
    if (capacity_value < 1 || capacity_value > MAX_CAPACITY || operation_count_value < 1 || operation_count_value > MAX_OPS) return -1;
    size_t capacity = (size_t)capacity_value, operations = (size_t)operation_count_value;
    if (length != 2 + 3 * operations) return -1;
    for (size_t i = 0; i < operations; ++i) {
        int64_t op = input[2 + 3 * i], key = input[3 + 3 * i], value = input[4 + 3 * i];
        if (op < 0 || op > 6) return -1;
        if (op <= 2) {
            if (key < INT32_MIN || key > INT32_MAX) return -1;
            if (op == 0) { if (value < INT32_MIN || value > INT32_MAX) return -1; }
            else if (value != 0) return -1;
        } else if (key != 0 || value != 0) return -1;
    }
    size_t required = operations * 16;
    if (output == NULL || output_capacity < required) return -2;

    int64_t keys[MAX_CAPACITY], values[MAX_CAPACITY];
    size_t count = 0;
    int64_t hits = 0, misses = 0;
    for (size_t i = 0; i < operations; ++i) {
        int64_t op = input[2 + 3 * i], key = input[3 + 3 * i], value = input[4 + 3 * i];
        int64_t first = 0, second = 0;
        if (op == 0) {
            size_t found = count;
            for (size_t j = 0; j < count; ++j) if (keys[j] == key) { found = j; break; }
            if (found < count) { for (size_t j = found; j + 1 < count; ++j) { keys[j] = keys[j + 1]; values[j] = values[j + 1]; } --count; }
            if (count == capacity) --count;
            keys[count] = key; values[count] = value; ++count;
            first = 1;
        } else if (op == 1) {
            size_t found = count;
            for (size_t j = 0; j < count; ++j) if (keys[j] == key) { found = j; break; }
            if (found < count) { ++hits; first = 1; second = values[found]; }
            else ++misses;
        } else if (op == 2) {
            size_t found = count;
            for (size_t j = 0; j < count; ++j) if (keys[j] == key) { found = j; break; }
            if (found < count) { first = 1; second = values[found]; for (size_t j = found; j + 1 < count; ++j) { keys[j] = keys[j + 1]; values[j] = values[j + 1]; } --count; }
        } else if (op == 3) first = (int64_t)count;
        else if (op == 4) first = hits;
        else if (op == 5) first = misses;
        else { count = 0; hits = 0; misses = 0; first = 1; }
        put_i64_le(output, 16 * i, first);
        put_i64_le(output, 16 * i + 8, second);
    }
    return (int64_t)(2 * operations);
}
