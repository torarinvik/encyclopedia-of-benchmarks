#include <stddef.h>
#include <stdint.h>

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = (uint8_t)(bits & 0xffu); bits >>= 8; }
}
static int compare_rows(const int64_t *left, const int64_t *right, const int64_t *keys, size_t key_count, int ascending) {
    for (size_t key = 0; key < key_count; ++key) {
        int64_t a = left[keys[key] - 1], b = right[keys[key] - 1];
        if (a < b) return ascending ? -1 : 1;
        if (a > b) return ascending ? 1 : -1;
    }
    return 0;
}
int64_t array_keys_sort(const int64_t *values, size_t length, uint8_t *output, size_t capacity) {
    if (values == NULL || length < 8 || length > 263) return -1;
    int64_t raw_count = values[0], raw_key_count = values[1], order = values[2];
    if (raw_count < 1 || raw_count > 64 || raw_key_count < 1 || raw_key_count > 4 || (order != 0 && order != 1)) return -1;
    size_t count = (size_t)raw_count, key_count = (size_t)raw_key_count;
    if (length != 3 + key_count + 4 * count) return -1;
    const int64_t *keys = values + 3;
    for (size_t i = 0; i < key_count; ++i) {
        if (keys[i] < 1 || keys[i] > 4) return -1;
        for (size_t j = 0; j < i; ++j) if (keys[i] == keys[j]) return -1;
    }
    int64_t rows[256] = {0};
    const size_t rows_start = 3 + key_count;
    for (size_t i = 0; i < 4 * count; ++i) {
        int64_t value = values[rows_start + i];
        if (value < -1000 || value > 1000) return -1;
        rows[i] = value;
    }
    for (size_t i = 0; i < count; ++i) for (size_t j = i + 1; j < count; ++j)
        if (compare_rows(&rows[i * 4], &rows[j * 4], keys, key_count, 1) == 0) return -1;
    size_t byte_count = 32 * count;
    if (output == NULL || capacity < byte_count) return -2;
    for (size_t i = 1; i < count; ++i) {
        int64_t temp[4];
        for (size_t column = 0; column < 4; ++column) temp[column] = rows[i * 4 + column];
        size_t position = i;
        while (position > 0 && compare_rows(&rows[(position - 1) * 4], temp, keys, key_count, (int)order) > 0) {
            for (size_t column = 0; column < 4; ++column) rows[position * 4 + column] = rows[(position - 1) * 4 + column];
            --position;
        }
        for (size_t column = 0; column < 4; ++column) rows[position * 4 + column] = temp[column];
    }
    for (size_t i = 0; i < 4 * count; ++i) store_i64_le(output, 8 * i, rows[i]);
    return (int64_t)byte_count;
}
