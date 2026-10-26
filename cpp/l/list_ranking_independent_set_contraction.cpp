#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 16, MAX_INPUT = 34, MAX_OUTPUT = 128;
void put64(std::uint8_t* out, std::size_t position, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        out[position + byte] = static_cast<std::uint8_t>(bits >> (8U * byte));
}
}

extern "C" std::int64_t list_ranking_independent_set_contraction(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > MAX_INPUT) return -1;
    const auto n_value = input[0], head_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(MAX_N) ||
        length != 2 + 2 * static_cast<std::size_t>(n_value) ||
        head_value < 0 || head_value >= n_value) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto head = static_cast<std::size_t>(head_value);
    std::int64_t weight[MAX_N]{}, successor[MAX_N]{};
    std::size_t indegree[MAX_N]{}, tail_count = 0;
    for (std::size_t node = 0; node < n; ++node) {
        weight[node] = input[2 + node];
        successor[node] = input[2 + n + node];
        if (weight[node] < 1 || weight[node] > 10000 ||
            successor[node] < -1 || successor[node] >= n_value) return -1;
        if (successor[node] == -1) ++tail_count;
        else if (++indegree[static_cast<std::size_t>(successor[node])] > 1) return -1;
    }
    if (tail_count != 1 || indegree[head] != 0) return -1;

    std::size_t path[MAX_N]{}, path_length = 0;
    bool seen[MAX_N]{};
    auto node = head_value;
    while (node != -1) {
        const auto index = static_cast<std::size_t>(node);
        if (seen[index] || path_length == n) return -1;
        seen[index] = true;
        path[path_length++] = index;
        node = successor[index];
    }
    if (path_length != n) return -1;
    const auto output_bytes = 8 * n;
    if (output == nullptr || capacity < output_bytes) return -2;

    std::size_t removed_node[MAX_N]{}, removed_successor[MAX_N]{}, removed_count = 0;
    std::int64_t old_successor_weight[MAX_N]{};
    while (path_length > 1) {
        std::size_t counts[3]{};
        for (std::size_t position = 0; position + 1 < path_length; ++position)
            ++counts[position % 3];
        std::size_t color = 0;
        for (std::size_t candidate = 1; candidate < 3; ++candidate)
            if (counts[candidate] > counts[color]) color = candidate;
        std::size_t write = 0;
        for (std::size_t position = 0; position < path_length; ++position) {
            const auto current = path[position];
            if (position + 1 < path_length && position % 3 == color) {
                const auto next = path[position + 1];
                removed_node[removed_count] = current;
                removed_successor[removed_count] = next;
                old_successor_weight[removed_count] = weight[next];
                ++removed_count;
                weight[next] += weight[current];
            } else {
                path[write++] = current;
            }
        }
        if (write == path_length) return -1;
        path_length = write;
    }

    std::int64_t rank[MAX_N]{};
    rank[path[0]] = weight[path[0]];
    while (removed_count > 0) {
        --removed_count;
        const auto current = removed_node[removed_count];
        const auto next = removed_successor[removed_count];
        rank[current] = rank[next] - old_successor_weight[removed_count];
    }
    std::uint8_t staged[MAX_OUTPUT]{};
    for (std::size_t index = 0; index < n; ++index)
        put64(staged, 8 * index, rank[index]);
    for (std::size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_bytes);
}
