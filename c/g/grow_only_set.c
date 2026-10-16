#include <stddef.h>
#include <stdint.h>

int64_t grow_only_set(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > 25) return -1;
    const int64_t count_value = values[0];
    if (count_value < 0 || count_value > 12 || length != 1 + 2 * (size_t)count_value) return -1;
    uint32_t left = 0, right = 0;
    uint64_t answers = 0;
    unsigned query_count = 0;
    for (int64_t index = 0; index < count_value; ++index) {
        const int64_t opcode = values[1 + 2 * (size_t)index];
        const int64_t argument = values[2 + 2 * (size_t)index];
        if (opcode < 0 || opcode > 7) return -1;
        if (opcode <= 3) {
            if (argument < 0 || argument > 15) return -1;
        } else if (argument != 0) {
            return -1;
        }
        const uint32_t bit = opcode <= 3 ? (UINT32_C(1) << (unsigned)argument) : 0;
        if (opcode == 0) left |= bit;
        else if (opcode == 1) right |= bit;
        else if (opcode == 2 || opcode == 3) {
            const uint32_t set = opcode == 2 ? left : right;
            if (set & bit) answers |= UINT64_C(1) << query_count;
            ++query_count;
        } else if (opcode == 4) {
            if ((left & right) == left) answers |= UINT64_C(1) << query_count;
            ++query_count;
        } else if (opcode == 5) {
            if ((left & right) == right) answers |= UINT64_C(1) << query_count;
            ++query_count;
        } else if (opcode == 6) left |= right;
        else right |= left;
    }
    return (int64_t)(answers | ((uint64_t)left << 12) | ((uint64_t)right << 28) |
                     ((uint64_t)query_count << 44));
}
