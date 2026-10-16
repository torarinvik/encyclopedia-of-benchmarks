/* Iterative reachability search in a bounded undirected graph. */
#include <array>
#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t MAX_VERTICES = 64, MAX_EDGES = 256, MAX_INPUT_LENGTH = 518; }
extern "C" std::int64_t depth_first_search_iterative(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const auto n = input[0], m = input[1], source = input[2], target = input[3];
    if (n < 1 || n > static_cast<std::int64_t>(MAX_VERTICES) || m < 0 || m > static_cast<std::int64_t>(MAX_EDGES)
            || source < 0 || source >= n) return -1;
    const auto edge_count = static_cast<std::size_t>(m);
    if (length != 4 + 2 * edge_count) return -1;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left = input[4 + 2 * edge], right = input[5 + 2 * edge];
        if (left < 0 || left >= n || right < 0 || right >= n) return -1;
    }
    std::array<bool, MAX_VERTICES> visited{};
    std::array<std::size_t, MAX_VERTICES> pending{};
    std::size_t top = 1;
    pending[0] = static_cast<std::size_t>(source);
    visited[pending[0]] = true;
    while (top > 0) {
        const auto current = pending[--top];
        if (static_cast<std::int64_t>(current) == target) return 1;
        for (std::size_t edge = 0; edge < edge_count; ++edge) {
            const auto left = input[4 + 2 * edge], right = input[5 + 2 * edge];
            const std::int64_t neighbor = left == static_cast<std::int64_t>(current) ? right
                : right == static_cast<std::int64_t>(current) ? left : -1;
            if (neighbor >= 0 && !visited[static_cast<std::size_t>(neighbor)]) {
                const auto index = static_cast<std::size_t>(neighbor);
                visited[index] = true;
                pending[top++] = index;
            }
        }
    }
    return 0;
}
