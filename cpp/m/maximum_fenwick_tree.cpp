#include <cstddef>
#include <cstdint>

static int64_t previous_bucket(int64_t index) { return (index & (index + 1)) - 1; }

extern "C" int64_t maximum_fenwick_tree(const int64_t *input, size_t length,
                                         uint8_t *output, size_t output_capacity) {
    if (input == nullptr || length < 2 || length > 194) return -1;
    if (input[0] < 1 || input[0] > 64 || input[1] < 0 || input[1] > 64) return -1;
    const size_t size = static_cast<size_t>(input[0]), op_count = static_cast<size_t>(input[1]);
    if (length != 2 + 3 * op_count) return -1;
    int32_t values[64] = {}, tree[64] = {};
    int64_t results[64];
    size_t result_count = 0;
    for (size_t op = 0, pos = 2; op < op_count; ++op, pos += 3) {
        const int64_t opcode = input[pos], first = input[pos + 1], second = input[pos + 2];
        if (opcode == 0) {
            if (first < 0 || first >= static_cast<int64_t>(size) || second < 0 || second > INT32_MAX) return -1;
            size_t index = static_cast<size_t>(first);
            const int32_t old_value = values[index], value = static_cast<int32_t>(second);
            values[index] = value;
            while (index < size) {
                const int32_t old_max = tree[index];
                if (value > old_max) tree[index] = value;
                else if (old_value == old_max) {
                    const int64_t left = previous_bucket(static_cast<int64_t>(index)) + 1;
                    int32_t maximum = value;
                    int64_t child = static_cast<int64_t>(index) - 1;
                    while (child >= left) {
                        if (tree[static_cast<size_t>(child)] > maximum) maximum = tree[static_cast<size_t>(child)];
                        if (maximum == old_max) break;
                        child = previous_bucket(child);
                    }
                    tree[index] = maximum;
                    if (maximum == old_max) break;
                } else break;
                index |= index + 1;
            }
        } else if (opcode == 1) {
            if (first < 0 || first > second || second > static_cast<int64_t>(size)) return -1;
            int32_t maximum = 0;
            int64_t right = second - 1;
            while (first <= right) {
                const int64_t current_left = right & (right + 1);
                if (first <= current_left) {
                    if (tree[static_cast<size_t>(right)] > maximum) maximum = tree[static_cast<size_t>(right)];
                    right = current_left - 1;
                } else {
                    if (values[static_cast<size_t>(right)] > maximum) maximum = values[static_cast<size_t>(right)];
                    --right;
                }
            }
            results[result_count++] = maximum;
        } else return -1;
    }
    const size_t bytes = result_count * 8;
    if (output == nullptr || output_capacity < bytes) return -2;
    for (size_t i = 0; i < result_count; ++i) {
        const uint64_t bits = static_cast<uint64_t>(results[i]);
        for (size_t b = 0; b < 8; ++b) output[8 * i + b] = static_cast<uint8_t>(bits >> (8 * b));
    }
    return static_cast<int64_t>(bytes);
}
