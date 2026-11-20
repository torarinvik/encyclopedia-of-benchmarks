#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t kMaxN = 64, kMaxQ = 64;
std::size_t find_root(std::int64_t* parent, std::size_t node) {
    auto root = node;
    while (static_cast<std::size_t>(parent[root]) != root) root = static_cast<std::size_t>(parent[root]);
    while (static_cast<std::size_t>(parent[node]) != node) {
        const auto next = static_cast<std::size_t>(parent[node]); parent[node] = static_cast<std::int64_t>(root); node = next;
    }
    return root;
}
}

extern "C" std::int64_t arpa_offline_rmq(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > 195) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(kMaxN) || q_value < 0 || q_value > static_cast<std::int64_t>(kMaxQ)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (length != 2 + n + 2 * q) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[2 + i] < -1000 || input[2 + i] > 1000) return -1;
    const auto query_start = 2 + n;
    for (std::size_t j = 0; j < q; ++j) {
        const auto left = input[query_start + 2 * j], right = input[query_start + 2 * j + 1];
        if (left < 0 || left > right || right >= n_value) return -1;
    }
    std::int64_t parent[64], stack[64], head[64], next_query[64];
    for (std::size_t i = 0; i < n; ++i) { parent[i] = static_cast<std::int64_t>(i); head[i] = -1; }
    for (std::size_t j = 0; j < q; ++j) {
        const auto right = static_cast<std::size_t>(input[query_start + 2 * j + 1]);
        next_query[j] = head[right];
        head[right] = static_cast<std::int64_t>(j);
    }
    std::size_t stack_size = 0;
    std::int64_t checksum = 0;
    for (std::size_t right = 0; right < n; ++right) {
        while (stack_size > 0 && input[2 + static_cast<std::size_t>(stack[stack_size - 1])] > input[2 + right])
            parent[static_cast<std::size_t>(stack[--stack_size])] = static_cast<std::int64_t>(right);
        stack[stack_size++] = static_cast<std::int64_t>(right);
        for (auto query = head[right]; query >= 0; query = next_query[static_cast<std::size_t>(query)]) {
            const auto j = static_cast<std::size_t>(query);
            const auto index = find_root(parent, static_cast<std::size_t>(input[query_start + 2 * j]));
            checksum += static_cast<std::int64_t>(j + 1) * static_cast<std::int64_t>(index + 1);
        }
    }
    return checksum;
}
