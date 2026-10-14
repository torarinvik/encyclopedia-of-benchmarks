#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 256
#define MAX_OPERATIONS 512
#define MAX_INPUT_VALUES (2 + 3 * MAX_OPERATIONS)
#define VALUE_LIMIT 1000000LL
#define QUERY_OFFSET 131072000001LL
#define FINAL_OFFSET 512000001LL

static size_t lowbit(size_t index) { return index & (~index + 1U); }

static int64_t prefix_sum(const int64_t *tree, size_t count)
{
    int64_t sum = 0;
    while (count > 0) {
        sum += tree[count];
        count -= lowbit(count);
    }
    return sum;
}

int64_t fenwick_tree_benchmark(const int64_t *values, size_t length)
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
        if (opcode == 0) {
            if (first < 0 || first >= item_count_value || second < -VALUE_LIMIT || second > VALUE_LIMIT) return -1;
        } else if (opcode == 1) {
            if (first < 0 || second < first || second >= item_count_value) return -1;
        } else return -1;
    }

    int64_t data[MAX_ITEMS] = {0};
    int64_t tree[MAX_ITEMS + 1] = {0};
    int64_t checksum = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t position = 2 + 3 * operation;
        const int64_t opcode = values[position];
        const size_t first = (size_t)values[position + 1];
        const int64_t second = values[position + 2];
        if (opcode == 0) {
            const int64_t delta = second;
            data[first] += delta;
            for (size_t index = first + 1; index <= item_count; index += lowbit(index)) tree[index] += delta;
        } else {
            const size_t left = first;
            const size_t right = (size_t)second;
            const int64_t result = prefix_sum(tree, right + 1) - prefix_sum(tree, left);
            checksum += (int64_t)(operation + 1) * (result + QUERY_OFFSET);
        }
    }
    for (size_t i = 0; i < item_count; ++i) {
        checksum += (int64_t)(operation_count + i + 1) * (data[i] + FINAL_OFFSET);
    }
    return checksum;
}
