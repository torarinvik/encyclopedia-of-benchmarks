#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 256
#define MAX_OPERATIONS 512
#define MAX_INPUT_VALUES (2 + 3 * MAX_OPERATIONS)
#define VALUE_LIMIT 1000000LL
#define QUERY_OFFSET 131072000001LL
#define FINAL_OFFSET 512000001LL

static int lowbit(int index) { return index & -index; }
static int32_t prefix_sum(const int32_t *tree, int count) {
    int32_t sum = 0;
    while (count > 0) { sum += tree[count]; count -= lowbit(count); }
    return sum;
}

int64_t binary_indexed_tree(const int64_t *values, size_t length) {
    if (!values || length < 2 || length > MAX_INPUT_VALUES) return -1;
    int64_t n_value = values[0], op_value = values[1];
    if (n_value < 2 || n_value > MAX_ITEMS || (n_value & (n_value - 1)) != 0 || op_value < 0 || op_value > MAX_OPERATIONS) return -1;
    size_t n = (size_t)n_value, operations = (size_t)op_value;
    if (length != 2 + 3 * operations) return -1;
    for (size_t op = 0; op < operations; ++op) {
        size_t at = 2 + 3 * op;
        int64_t code = values[at], first = values[at + 1], second = values[at + 2];
        if (code == 0) { if (first < 0 || first >= n_value || second < -VALUE_LIMIT || second > VALUE_LIMIT) return -1; }
        else if (code == 1) { if (first < 0 || second < first || second >= n_value) return -1; }
        else return -1;
    }
    int32_t data[MAX_ITEMS] = {0}, tree[MAX_ITEMS + 2] = {0};
    int64_t checksum = 0;
    for (size_t op = 0; op < operations; ++op) {
        size_t at = 2 + 3 * op;
        int code = (int)values[at], first = (int)values[at + 1];
        int32_t second = (int32_t)values[at + 2];
        if (code == 0) {
            data[first] += second;
            int start = first + 1;
            while (start <= (int)n + 1) { tree[start] += second; start += lowbit(start); }
        } else {
            int32_t result = prefix_sum(tree, (int)second + 1) - prefix_sum(tree, first);
            checksum += (int64_t)(op + 1) * ((int64_t)result + QUERY_OFFSET);
        }
    }
    for (size_t i = 0; i < n; ++i) checksum += (int64_t)(operations + i + 1) * ((int64_t)data[i] + FINAL_OFFSET);
    return checksum;
}
