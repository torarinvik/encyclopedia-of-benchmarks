#include <stddef.h>
#include <stdint.h>

int64_t chaining(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > 260) return -1;
    const int64_t bucket_count_value = input[0];
    const int64_t operation_count_value = input[1];
    if (bucket_count_value < 1 || bucket_count_value > 127
            || operation_count_value < 0 || operation_count_value > 128) return -1;
    const size_t bucket_count = (size_t)bucket_count_value;
    const size_t operation_count = (size_t)operation_count_value;
    if (length != 2 + 2 * operation_count) return -1;

    int64_t heads[127], keys[128], next[128];
    for (size_t bucket = 0; bucket < bucket_count; ++bucket) {
        heads[bucket] = -1;
    }
    size_t inserted = 0;
    size_t query_count = 0;
    uint64_t result = 0;
    for (size_t operation_index = 0; operation_index < operation_count; ++operation_index) {
        const int64_t operation = input[2 + 2 * operation_index];
        const int64_t key = input[3 + 2 * operation_index];
        if ((operation != 0 && operation != 1) || key < 0 || key > INT32_MAX) return -1;
        const size_t bucket = (size_t)(key % bucket_count_value);
        if (operation == 0) {
            if (inserted >= 128) return -1;
            keys[inserted] = key;
            next[inserted] = -1;
            if (heads[bucket] < 0) {
                heads[bucket] = (int64_t)inserted;
            } else {
                int64_t node = heads[bucket];
                while (next[(size_t)node] >= 0) node = next[(size_t)node];
                next[(size_t)node] = (int64_t)inserted;
            }
            ++inserted;
        } else {
            if (query_count >= 63) return -1;
            int64_t node = heads[bucket];
            while (node >= 0 && keys[(size_t)node] != key) node = next[(size_t)node];
            if (node >= 0) result |= UINT64_C(1) << query_count;
            ++query_count;
        }
    }
    return (int64_t)result;
}
