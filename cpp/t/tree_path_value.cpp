// Port of Go Problem18's chunked search over its triangle-shaped DAG.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t tree_path_value(const std::int64_t *packed, std::size_t length) noexcept {
    if (packed == nullptr || length < 1 || length > 121 || packed[0] < 1 || packed[0] > 14) return -1;
    const int depth = static_cast<int>(packed[0]);
    const std::size_t count = length - 1;
    if (count == 0) return 0;

    std::int64_t values[120];
    int left[120], right[120];
    for (std::size_t i = 0; i < count; ++i) {
        values[i] = packed[i + 1]; left[i] = right[i] = -1;
        if ((i == 0 && (values[i] < -1000 || values[i] > 1000))
                || (i > 0 && (values[i] < 1 || values[i] > 1000))) return -1;
    }
    std::size_t row_start = 0, width = 1;
    while (row_start < count) {
        for (std::size_t column = 0; column < width && row_start + column < count; ++column) {
            const std::size_t parent = row_start + column;
            const std::size_t left_index = row_start + width + column;
            const std::size_t right_index = left_index + 1;
            if (left_index < count) left[parent] = static_cast<int>(left_index);
            if (right_index < count) right[parent] = static_cast<int>(right_index);
        }
        row_start += width; ++width;
    }

    int pivot = 0;
    std::int64_t maximum = values[0];
    while (left[pivot] >= 0) {
        int stack_node[16], stack_steps[16];
        std::int64_t stack_sum[16];
        std::size_t top = 0;
        stack_node[top] = pivot; stack_steps[top] = depth; stack_sum[top] = maximum; ++top;
        while (top > 0) {
            --top;
            const int node = stack_node[top], steps = stack_steps[top];
            const std::int64_t sum = stack_sum[top];
            if (steps == 0) {
                if (sum > maximum) { maximum = sum; pivot = node; }
                continue;
            }
            if (right[node] >= 0) {
                stack_node[top] = right[node]; stack_steps[top] = steps - 1;
                stack_sum[top] = sum + values[right[node]]; ++top;
            }
            if (left[node] >= 0) {
                stack_node[top] = left[node]; stack_steps[top] = steps - 1;
                stack_sum[top] = sum + values[left[node]]; ++top;
            } else if (sum > maximum) {
                maximum = sum; pivot = node;
            }
        }
    }
    return maximum;
}
