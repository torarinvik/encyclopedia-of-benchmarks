#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 64, kMaxQ = 64;
std::size_t find_successor(std::int64_t* parent, std::size_t node) {
    auto root = node;
    while (static_cast<std::size_t>(parent[root]) != root) root = static_cast<std::size_t>(parent[root]);
    while (static_cast<std::size_t>(parent[node]) != node) {
        const auto next = static_cast<std::size_t>(parent[node]); parent[node] = static_cast<std::int64_t>(root); node = next;
    }
    return root;
}
}

extern "C" std::int64_t offline_range_paint_successor_dsu(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > 195) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(kMaxN) || q_value < 0 || q_value > static_cast<std::int64_t>(kMaxQ)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (length != 2 + 3 * q) return -1;
    std::int64_t left[64], right[64], color[64];
    for (std::size_t j = 0; j < q; ++j) {
        left[j] = input[2 + 3 * j]; right[j] = input[3 + 3 * j]; color[j] = input[4 + 3 * j];
        if (left[j] < 0 || left[j] > right[j] || right[j] >= n_value || color[j] < -1000 || color[j] > 1000) return -1;
    }
    std::int64_t parent[65], final_color[64]{};
    for (std::size_t i = 0; i <= n; ++i) parent[i] = static_cast<std::int64_t>(i);
    for (std::size_t j = q; j > 0; --j) {
        const auto op = j - 1;
        auto cell = find_successor(parent, static_cast<std::size_t>(left[op]));
        while (cell <= static_cast<std::size_t>(right[op])) {
            final_color[cell] = color[op];
            parent[cell] = static_cast<std::int64_t>(find_successor(parent, cell + 1));
            cell = find_successor(parent, cell);
        }
    }
    std::int64_t checksum = 0;
    for (std::size_t i = 0; i < n; ++i) checksum += static_cast<std::int64_t>(i + 1) * (final_color[i] + 1001);
    return checksum;
}
