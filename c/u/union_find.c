#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 256
#define MAX_OPERATIONS 512
#define MAX_INPUT_VALUES (2 + 3 * MAX_OPERATIONS)
#define OBSERVED_OFFSET 1000003LL

static size_t find_root(int64_t *parent, size_t item)
{
    while ((size_t)parent[item] != item) {
        parent[item] = parent[(size_t)parent[item]];
        item = (size_t)parent[item];
    }
    return item;
}

int64_t union_find_benchmark(const int64_t *values, size_t length)
{
    if (length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t item_count_value = values[0];
    const int64_t operation_count_value = values[1];
    if (item_count_value < 1 || item_count_value > MAX_ITEMS ||
        operation_count_value < 0 || operation_count_value > MAX_OPERATIONS) return -1;
    const size_t item_count = (size_t)item_count_value;
    const size_t operation_count = (size_t)operation_count_value;
    if (length != 2 + 3 * operation_count) return -1;

    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t position = 2 + 3 * operation;
        const int64_t opcode = values[position];
        const int64_t first = values[position + 1];
        const int64_t second = values[position + 2];
        if (opcode == 0 || opcode == 1) {
            if (first < 0 || first >= item_count_value || second < 0 || second >= item_count_value) return -1;
        } else if (opcode == 2) {
            if (first != 0 || second != 0) return -1;
        } else {
            return -1;
        }
    }

    int64_t parent[MAX_ITEMS];
    int64_t size[MAX_ITEMS];
    for (size_t i = 0; i < item_count; ++i) {
        parent[i] = (int64_t)i;
        size[i] = 1;
    }
    size_t components = item_count;
    int64_t connected_pairs = 0;
    int64_t checksum = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t position = 2 + 3 * operation;
        const int64_t opcode = values[position];
        const size_t first = (size_t)values[position + 1];
        const size_t second = (size_t)values[position + 2];
        int64_t observed = 0;
        if (opcode == 0) {
            size_t first_root = find_root(parent, first);
            size_t second_root = find_root(parent, second);
            if (first_root != second_root) {
                connected_pairs += size[first_root] * size[second_root];
                if (size[first_root] < size[second_root]) {
                    parent[first_root] = (int64_t)second_root;
                    size[second_root] += size[first_root];
                } else {
                    parent[second_root] = (int64_t)first_root;
                    size[first_root] += size[second_root];
                }
                --components;
                observed = 1;
            }
        } else if (opcode == 1) {
            observed = find_root(parent, first) == find_root(parent, second);
        } else {
            observed = (int64_t)components;
        }
        checksum += (int64_t)(operation + 1) * (observed + OBSERVED_OFFSET);
    }
    return checksum + connected_pairs;
}
