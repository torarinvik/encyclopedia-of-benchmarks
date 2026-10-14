#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 256;
constexpr std::size_t max_operations = 512;
constexpr std::size_t max_input_values = 2 + 3 * max_operations;
constexpr std::int64_t observed_offset = 1000003;

std::size_t find_root(std::int64_t *parent, std::size_t item)
{
    while (static_cast<std::size_t>(parent[item]) != item) {
        parent[item] = parent[static_cast<std::size_t>(parent[item])];
        item = static_cast<std::size_t>(parent[item]);
    }
    return item;
}
}

extern "C" std::int64_t union_find_benchmark(const std::int64_t *values, std::size_t length)
{
    if (length < 2 || length > max_input_values) return -1;
    const std::int64_t item_count_value = values[0];
    const std::int64_t operation_count_value = values[1];
    if (item_count_value < 1 || item_count_value > static_cast<std::int64_t>(max_items) ||
        operation_count_value < 0 || operation_count_value > static_cast<std::int64_t>(max_operations)) return -1;
    const std::size_t item_count = static_cast<std::size_t>(item_count_value);
    const std::size_t operation_count = static_cast<std::size_t>(operation_count_value);
    if (length != 2 + 3 * operation_count) return -1;

    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::size_t position = 2 + 3 * operation;
        const std::int64_t opcode = values[position];
        const std::int64_t first = values[position + 1];
        const std::int64_t second = values[position + 2];
        if (opcode == 0 || opcode == 1) {
            if (first < 0 || first >= item_count_value || second < 0 || second >= item_count_value) return -1;
        } else if (opcode == 2) {
            if (first != 0 || second != 0) return -1;
        } else {
            return -1;
        }
    }

    std::int64_t parent[max_items];
    std::int64_t set_size[max_items];
    for (std::size_t i = 0; i < item_count; ++i) {
        parent[i] = static_cast<std::int64_t>(i);
        set_size[i] = 1;
    }
    std::size_t components = item_count;
    std::int64_t connected_pairs = 0;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::size_t position = 2 + 3 * operation;
        const std::int64_t opcode = values[position];
        const std::size_t first = static_cast<std::size_t>(values[position + 1]);
        const std::size_t second = static_cast<std::size_t>(values[position + 2]);
        std::int64_t observed = 0;
        if (opcode == 0) {
            const std::size_t first_root = find_root(parent, first);
            const std::size_t second_root = find_root(parent, second);
            if (first_root != second_root) {
                connected_pairs += set_size[first_root] * set_size[second_root];
                if (set_size[first_root] < set_size[second_root]) {
                    parent[first_root] = static_cast<std::int64_t>(second_root);
                    set_size[second_root] += set_size[first_root];
                } else {
                    parent[second_root] = static_cast<std::int64_t>(first_root);
                    set_size[first_root] += set_size[second_root];
                }
                --components;
                observed = 1;
            }
        } else if (opcode == 1) {
            observed = find_root(parent, first) == find_root(parent, second);
        } else {
            observed = static_cast<std::int64_t>(components);
        }
        checksum += static_cast<std::int64_t>(operation + 1) * (observed + observed_offset);
    }
    return checksum + connected_pairs;
}
