/* Portable linked-list multiset port of TheAlgorithms Bag contracts. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INSERTS 128
#define MAX_QUERIES 64

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (unsigned byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t bag(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2) return -1;
    int64_t insert_count_value = input[0];
    if (insert_count_value < 0 || insert_count_value > MAX_INSERTS) return -1;
    size_t insert_count = (size_t)insert_count_value;
    if (length < insert_count + 2) return -1;
    int64_t query_count_value = input[insert_count + 1];
    if (query_count_value < 0 || query_count_value > MAX_QUERIES) return -1;
    size_t query_count = (size_t)query_count_value;
    if (length != insert_count + query_count + 2) return -1;

    for (size_t index = 0; index < insert_count; ++index) {
        int64_t value = input[index + 1];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
    }
    for (size_t query = 0; query < query_count; ++query) {
        int64_t value = input[insert_count + query + 2];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
    }
    size_t output_length = (query_count + 2) * 8;
    if (output == NULL || capacity < output_length) return -2;

    int64_t values[MAX_INSERTS];
    size_t distinct_count = 0;
    for (size_t index = 0; index < insert_count; ++index) {
        int64_t value = input[index + 1];
        size_t node = 0;
        while (node < distinct_count && values[node] != value) ++node;
        if (node == distinct_count) {
            values[distinct_count] = value;
            ++distinct_count;
        }
    }

    put_i64_le(output, 0, insert_count_value);
    put_i64_le(output, 8, insert_count_value == 0 ? 1 : 0);
    for (size_t query = 0; query < query_count; ++query) {
        int64_t target = input[insert_count + query + 2];
        int64_t contains = 0;
        for (size_t node = 0; node < distinct_count; ++node)
            if (values[node] == target) { contains = 1; break; }
        put_i64_le(output, (query + 2) * 8, contains);
    }
    return (int64_t)output_length;
}
