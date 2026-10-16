/* Push–Relabel maximum flow for bounded multi-terminal integral networks. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_VERTICES = 14;
constexpr std::size_t AUGMENTED_VERTICES = 16;
constexpr std::size_t MAX_INPUT_LENGTH = 227;
constexpr std::int64_t MAX_CAPACITY = 1000000;
}

extern "C" std::int64_t push_relabel(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const std::int64_t n64 = input[0], source_count64 = input[1];
    if (n64 < 2 || n64 > static_cast<std::int64_t>(MAX_VERTICES) || source_count64 < 1 || source_count64 >= n64) return -1;
    const std::size_t n = static_cast<std::size_t>(n64), source_count = static_cast<std::size_t>(source_count64);
    const std::size_t sink_count_index = 2 + source_count;
    if (length <= sink_count_index) return -1;

    bool is_source[MAX_VERTICES] = {}, is_sink[MAX_VERTICES] = {};
    std::size_t sources[MAX_VERTICES] = {};
    for (std::size_t index = 0; index < source_count; ++index) {
        const std::int64_t node64 = input[2 + index];
        if (node64 < 0 || node64 >= n64 || is_source[static_cast<std::size_t>(node64)]) return -1;
        sources[index] = static_cast<std::size_t>(node64);
        is_source[static_cast<std::size_t>(node64)] = true;
    }
    const std::int64_t sink_count64 = input[sink_count_index];
    if (sink_count64 < 1 || sink_count64 > n64 - source_count64) return -1;
    const std::size_t sink_count = static_cast<std::size_t>(sink_count64);
    const std::size_t matrix_start = sink_count_index + 1 + sink_count;
    if (length < matrix_start || length != matrix_start + n * n) return -1;
    for (std::size_t index = 0; index < sink_count; ++index) {
        const std::int64_t node64 = input[sink_count_index + 1 + index];
        if (node64 < 0 || node64 >= n64 || is_sink[static_cast<std::size_t>(node64)] || is_source[static_cast<std::size_t>(node64)]) return -1;
        is_sink[static_cast<std::size_t>(node64)] = true;
    }

    std::int64_t residual[AUGMENTED_VERTICES * AUGMENTED_VERTICES] = {};
    std::int64_t source_out[MAX_VERTICES] = {};
    std::int64_t flow_limit = 0;
    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t column = 0; column < n; ++column) {
            const std::int64_t capacity = input[matrix_start + row * n + column];
            if (capacity < 0 || capacity > MAX_CAPACITY || (row == column && capacity != 0)) return -1;
            residual[row * AUGMENTED_VERTICES + column] = capacity;
            if (is_source[row]) {
                source_out[row] += capacity;
                flow_limit += capacity;
            }
        }
    }

    const std::size_t super_source = n, super_sink = n + 1;
    for (std::size_t index = 0; index < source_count; ++index)
        residual[super_source * AUGMENTED_VERTICES + sources[index]] = source_out[sources[index]];
    for (std::size_t index = 0; index < sink_count; ++index)
        residual[static_cast<std::size_t>(input[sink_count_index + 1 + index]) * AUGMENTED_VERTICES + super_sink] = flow_limit;

    int height[AUGMENTED_VERTICES] = {};
    std::int64_t excess[AUGMENTED_VERTICES] = {};
    bool active[AUGMENTED_VERTICES] = {};
    height[super_source] = static_cast<int>(n) + 2;
    for (std::size_t index = 0; index < source_count; ++index) {
        const std::size_t source = sources[index];
        const std::int64_t initial_excess = residual[super_source * AUGMENTED_VERTICES + source];
        residual[super_source * AUGMENTED_VERTICES + source] = 0;
        residual[source * AUGMENTED_VERTICES + super_source] += initial_excess;
        excess[source] += initial_excess;
        if (excess[source] > 0) active[source] = true;
    }

    for (;;) {
        std::size_t node = 0;
        while (node < n && !active[node]) ++node;
        if (node == n) break;
        active[node] = false;
        while (excess[node] > 0) {
            bool pushed = false;
            for (std::size_t neighbor = 0; neighbor < n + 2 && excess[node] > 0; ++neighbor) {
                const std::size_t edge = node * AUGMENTED_VERTICES + neighbor;
                if (residual[edge] <= 0 || height[node] != height[neighbor] + 1) continue;
                const std::int64_t amount = excess[node] < residual[edge] ? excess[node] : residual[edge];
                residual[edge] -= amount;
                residual[neighbor * AUGMENTED_VERTICES + node] += amount;
                excess[node] -= amount;
                const std::int64_t previous_excess = excess[neighbor];
                excess[neighbor] += amount;
                if (neighbor < n && previous_excess == 0) active[neighbor] = true;
                pushed = true;
            }
            if (excess[node] > 0 && !pushed) {
                int minimum_height = 1000;
                for (std::size_t neighbor = 0; neighbor < n + 2; ++neighbor)
                    if (residual[node * AUGMENTED_VERTICES + neighbor] > 0 && height[neighbor] < minimum_height)
                        minimum_height = height[neighbor];
                if (minimum_height == 1000) return -1;
                height[node] = minimum_height + 1;
            }
        }
    }
    return excess[super_sink];
}
