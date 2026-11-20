/* Union-find with circular component-member enumeration. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_ITEMS = 16, MAX_OPERATIONS = 32, MAX_INPUT_LENGTH = 99 };

static size_t ufe_find(int64_t *parent, size_t item)
{
    size_t root = item;
    while (parent[root] >= 0) root = (size_t)parent[root];
    while (item != root) {
        const size_t next_item = (size_t)parent[item];
        parent[item] = (int64_t)root;
        item = next_item;
    }
    return root;
}

static int64_t ufe_component_mask(const int64_t *successor, size_t start)
{
    uint64_t mask = 0;
    size_t item = start;
    do {
        mask |= UINT64_C(1) << item;
        item = (size_t)successor[item];
    } while (item != start);
    return (int64_t)mask;
}

int64_t union_find_enumerate(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t item_count_value = input[0];
    const int64_t operation_count_value = input[1];
    if (item_count_value < 1 || item_count_value > MAX_ITEMS ||
        operation_count_value < 0 || operation_count_value > MAX_OPERATIONS) return -1;
    const size_t item_count = (size_t)item_count_value;
    const size_t operation_count = (size_t)operation_count_value;
    if (length != 2 + 3 * operation_count) return -1;

    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t position = 2 + 3 * operation;
        const int64_t opcode = input[position];
        const int64_t first = input[position + 1];
        const int64_t second = input[position + 2];
        if (opcode == 0) {
            if (first < 0 || first >= item_count_value ||
                second < 0 || second >= item_count_value) return -1;
        } else if (opcode == 1) {
            if (first < 0 || first >= item_count_value || second != 0) return -1;
        } else return -1;
    }

    int64_t parent[MAX_ITEMS];
    int64_t successor[MAX_ITEMS];
    for (size_t item = 0; item < item_count; ++item) {
        parent[item] = -1;
        successor[item] = (int64_t)item;
    }
    int64_t checksum = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t position = 2 + 3 * operation;
        const int64_t opcode = input[position];
        const size_t first = (size_t)input[position + 1];
        int64_t observed;
        if (opcode == 0) {
            size_t left = ufe_find(parent, first);
            size_t right = ufe_find(parent, (size_t)input[position + 2]);
            observed = 0;
            if (left != right) {
                if (parent[left] > parent[right]) {
                    const size_t temporary = left;
                    left = right;
                    right = temporary;
                }
                parent[left] += parent[right];
                parent[right] = (int64_t)left;
                const int64_t temporary = successor[left];
                successor[left] = successor[right];
                successor[right] = temporary;
                observed = 1;
            }
        } else {
            observed = ufe_component_mask(successor, first);
        }
        checksum += (int64_t)(operation + 1) * (observed + 1);
    }
    return checksum;
}
