#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 256
#define MAX_OPERATIONS 512
#define MAX_INPUT_VALUES (MAX_ITEMS + 3 + 3 * MAX_OPERATIONS)
#define VALUE_LIMIT 1000000
#define QUERY_OFFSET 256000001LL
#define FINAL_OFFSET 1000001LL

static int64_t identity(int64_t mode)
{
    if (mode == 1) return VALUE_LIMIT + 1LL;
    if (mode == 2) return -(VALUE_LIMIT + 1LL);
    return 0;
}

static int64_t combine(int64_t mode, int64_t left, int64_t right)
{
    if (mode == 1) return left < right ? left : right;
    if (mode == 2) return left > right ? left : right;
    return left + right;
}

int64_t segment_tree_benchmark(const int64_t *values, size_t length)
{
    if (length < 3 || length > MAX_INPUT_VALUES) return -1;
    const int64_t mode = values[0];
    const int64_t item_count_value = values[1];
    if (mode < 0 || mode > 2 || item_count_value < 1 || item_count_value > MAX_ITEMS) return -1;
    const size_t item_count = (size_t)item_count_value;
    if (length < item_count + 3) return -1;
    const int64_t operation_count_value = values[item_count + 2];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)operation_count_value;
    if (length != item_count + 3 + 3 * operation_count) return -1;

    int64_t data[MAX_ITEMS];
    for (size_t i = 0; i < item_count; ++i) {
        const int64_t value = values[i + 2];
        if (value < -VALUE_LIMIT || value > VALUE_LIMIT) return -1;
        data[i] = value;
    }
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t position = item_count + 3 + 3 * operation;
        const int64_t opcode = values[position];
        const int64_t first = values[position + 1];
        const int64_t second = values[position + 2];
        if (opcode == 0) {
            if (first < 0 || first >= item_count || second < -VALUE_LIMIT || second > VALUE_LIMIT) return -1;
        } else if (opcode == 1) {
            if (first < 0 || second < first || second >= item_count) return -1;
        } else {
            return -1;
        }
    }

    size_t base = 1;
    while (base < item_count) base *= 2;
    int64_t tree[2 * MAX_ITEMS];
    const int64_t empty = identity(mode);
    for (size_t i = 0; i < 2 * base; ++i) tree[i] = empty;
    for (size_t i = 0; i < item_count; ++i) tree[base + i] = data[i];
    for (size_t node = base; node-- > 1;) {
        tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1]);
    }

    int64_t checksum = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t position = item_count + 3 + 3 * operation;
        const int64_t opcode = values[position];
        const size_t first = (size_t)values[position + 1];
        if (opcode == 0) {
            const int64_t value = values[position + 2];
            data[first] = value;
            size_t node = base + first;
            tree[node] = value;
            while (node > 1) {
                node /= 2;
                tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1]);
            }
        } else {
            size_t left = base + first;
            size_t right = base + (size_t)values[position + 2] + 1;
            int64_t result = empty;
            while (left < right) {
                if (left & 1U) result = combine(mode, result, tree[left++]);
                if (right & 1U) result = combine(mode, result, tree[--right]);
                left /= 2;
                right /= 2;
            }
            checksum += (int64_t)(operation + 1) * (result + QUERY_OFFSET);
        }
    }
    for (size_t i = 0; i < item_count; ++i) {
        checksum += (int64_t)(operation_count + i + 1) * (data[i] + FINAL_OFFSET);
    }
    return checksum;
}
