#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 8;
constexpr std::size_t kMaxM = 28;
constexpr std::size_t kMaxInputLength = 58;
constexpr std::size_t kMaxOutputBytes = 17;
}

extern "C" std::int64_t scc_condensation_dag(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(kMaxN) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(kMaxM)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * m) return -1;
    std::array<std::uint16_t, kMaxN> adjacency{}, reverse{};
    for (std::size_t i = 0; i < m; ++i) {
        const auto source = input[2 + 2 * i], target = input[3 + 2 * i];
        if (source < 0 || source >= static_cast<std::int64_t>(n) ||
            target < 0 || target >= static_cast<std::int64_t>(n)) return -1;
        adjacency[static_cast<std::size_t>(source)] |= static_cast<std::uint16_t>(1u << target);
        reverse[static_cast<std::size_t>(target)] |= static_cast<std::uint16_t>(1u << source);
    }

    std::array<bool, kMaxN> visited{};
    std::array<std::uint8_t, kMaxN> order{}, stack_vertex{}, stack_next{};
    std::size_t order_count = 0;
    for (std::size_t start = 0; start < n; ++start) {
        if (visited[start]) continue;
        std::size_t stack_size = 1;
        stack_vertex[0] = static_cast<std::uint8_t>(start);
        stack_next[0] = 0;
        visited[start] = true;
        while (stack_size > 0) {
            const auto frame = stack_size - 1;
            const auto vertex = static_cast<std::size_t>(stack_vertex[frame]);
            auto candidate = static_cast<std::size_t>(stack_next[frame]);
            while (candidate < n && (adjacency[vertex] & (1u << candidate)) == 0) ++candidate;
            if (candidate < n) {
                stack_next[frame] = static_cast<std::uint8_t>(candidate + 1);
                if (!visited[candidate]) {
                    visited[candidate] = true;
                    stack_vertex[stack_size] = static_cast<std::uint8_t>(candidate);
                    stack_next[stack_size] = 0;
                    ++stack_size;
                }
            } else {
                order[order_count++] = static_cast<std::uint8_t>(vertex);
                --stack_size;
            }
        }
    }

    std::array<std::int8_t, kMaxN> raw_component{};
    raw_component.fill(-1);
    visited.fill(false);
    std::size_t component_count = 0;
    while (order_count > 0) {
        const auto start = static_cast<std::size_t>(order[--order_count]);
        if (visited[start]) continue;
        std::size_t stack_size = 1;
        stack_vertex[0] = static_cast<std::uint8_t>(start);
        visited[start] = true;
        raw_component[start] = static_cast<std::int8_t>(component_count);
        while (stack_size > 0) {
            const auto vertex = static_cast<std::size_t>(stack_vertex[--stack_size]);
            for (std::size_t next = 0; next < n; ++next) {
                if ((reverse[vertex] & (1u << next)) != 0 && !visited[next]) {
                    visited[next] = true;
                    raw_component[next] = static_cast<std::int8_t>(component_count);
                    stack_vertex[stack_size++] = static_cast<std::uint8_t>(next);
                }
            }
        }
        ++component_count;
    }

    std::array<std::uint8_t, kMaxN> minimum{}, raw_order{}, canonical{}, labels{}, row_mask{};
    for (std::size_t component = 0; component < component_count; ++component) {
        minimum[component] = static_cast<std::uint8_t>(n);
        raw_order[component] = static_cast<std::uint8_t>(component);
    }
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        const auto component = static_cast<std::size_t>(raw_component[vertex]);
        if (vertex < minimum[component]) minimum[component] = static_cast<std::uint8_t>(vertex);
    }
    for (std::size_t i = 1; i < component_count; ++i) {
        const auto key = raw_order[i];
        auto j = i;
        while (j > 0 && minimum[raw_order[j - 1]] > minimum[key]) {
            raw_order[j] = raw_order[j - 1];
            --j;
        }
        raw_order[j] = key;
    }
    for (std::size_t i = 0; i < component_count; ++i) canonical[raw_order[i]] = static_cast<std::uint8_t>(i);
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        labels[vertex] = canonical[static_cast<std::size_t>(raw_component[vertex])];
    for (std::size_t source = 0; source < n; ++source) {
        for (std::size_t target = 0; target < n; ++target) {
            if ((adjacency[source] & (1u << target)) == 0) continue;
            const auto left = labels[source], right = labels[target];
            if (left != right) row_mask[left] |= static_cast<std::uint8_t>(1u << right);
        }
    }

    std::array<std::uint8_t, kMaxOutputBytes> staged{};
    staged[0] = static_cast<std::uint8_t>(component_count);
    for (std::size_t vertex = 0; vertex < n; ++vertex) staged[1 + vertex] = labels[vertex];
    for (std::size_t component = 0; component < component_count; ++component)
        staged[1 + n + component] = row_mask[component];
    const auto output_size = 1 + n + component_count;
    if (output == nullptr || capacity < output_size) return -2;
    for (std::size_t i = 0; i < output_size; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(output_size);
}
